"""
Forensic investigation agent: user query + case folder, MCP tools, logging under cases/.../logs/.
"""

from __future__ import annotations

import asyncio
import json
import os
import re
from pathlib import Path
from typing import Any

from google.genai import types
from dotenv import load_dotenv

from core.genai_config import build_genai_client, default_model_name
from core.case_logging import (
    append_step_jsonl,
    ensure_logs_dir,
    list_case_inventory,
    redact_for_llm,
    truncate_value,
    utc_now_iso,
    write_final_report,
)
from core.mcp_client import run_with_mcp_session, tool_result_to_serializable
from core.prompt import NEXT_STEP_PROMPT, build_investigation_user_message

load_dotenv()

client = build_genai_client()
GEMINI_MODEL = default_model_name()

# Context size limits for the model (full step payloads still go to JSONL with larger caps)
MAX_MODEL_CONTEXT_CHARS = 14_000
MAX_JSONL_RESULT_CHARS = 400_000


def parse_json_response(text: str) -> dict[str, Any]:
    """Extract JSON from model output (handles optional markdown fences)."""
    text = (text or "").strip()
    if not text:
        raise ValueError("Empty model response")

    fence = re.match(r"^```(?:json)?\s*\n?", text)
    if fence:
        text = text[fence.end() :]
        text = re.sub(r"\n?```\s*$", "", text, flags=re.DOTALL)

    text = text.strip()
    return json.loads(text)


def decide_next_step(context: dict[str, Any]) -> dict[str, Any]:
    user_block = build_investigation_user_message(context)
    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=NEXT_STEP_PROMPT + "\n\n" + user_block,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )

    raw_text = getattr(response, "text", None) or ""
    if not raw_text and response.candidates:
        parts = response.candidates[0].content.parts
        raw_text = "".join(getattr(p, "text", "") for p in parts)

    try:
        data = parse_json_response(raw_text)
    except (json.JSONDecodeError, ValueError) as e:
        return {
            "action": "finish",
            "summary": f"Model returned invalid JSON: {e}",
            "reasoning": "parse_error",
            "args": {},
        }

    action = data.get("action")
    reasoning = data.get("reasoning", "")

    if action == "finish" or action is None:
        summary = data.get("summary") or reasoning or "Investigation ended without a summary."
        return {
            "action": "finish",
            "summary": summary,
            "reasoning": reasoning,
            "args": {},
        }

    return {
        "action": action,
        "args": data.get("args") or {},
        "reasoning": reasoning,
    }


def _build_model_context(state: dict[str, Any]) -> dict[str, Any]:
    """Concise context: user goal, progress, inventory, recent history with truncated results."""
    history = state.get("history", [])
    recent = history[-8:] if len(history) > 8 else history
    slim_history: list[dict[str, Any]] = []
    for h in recent:
        slim_history.append(
            {
                "step": h.get("step"),
                "reasoning": h.get("reasoning"),
                "action": h.get("action"),
                "args": h.get("args"),
                "result": truncate_value(redact_for_llm(h.get("result_summary")), 3500),
            }
        )

    ctx = {
        "user_query": state["user_query"],
        "case_folder": state["case_folder"],
        "step": state["step_index"],
        "max_steps": state["max_steps"],
        "progress": f"Step {state['step_index'] + 1} of {state['max_steps']}",
        "case_inventory": state.get("inventory", []),
        "recent_steps": slim_history,
    }
    return truncate_value(ctx, MAX_MODEL_CONTEXT_CHARS)


def _max_steps_summary(state: dict[str, Any]) -> str:
    """Short final text when the loop exits without a model finish."""
    lines = [
        "## Investigation limit reached",
        "",
        f"The run stopped after **{state['max_steps']}** tool steps without a model `finish`.",
        "",
        "### Steps taken",
    ]
    for h in state.get("history", []):
        lines.append(
            f"- Step {h.get('step')}: `{h.get('action')}` — {str(h.get('reasoning', ''))[:200]}"
        )
    lines.append("")
    lines.append("See `investigation_steps.jsonl` for full tool output.")
    return "\n".join(lines)


def run_investigation(
    user_query: str,
    case_folder: str,
    max_steps: int = 12,
) -> dict[str, Any]:
    """
    Run a forensic investigation using MCP tools (linux + sleuthkit).

    Writes:
      `<case_folder>/logs/investigation_steps.jsonl` — one JSON record per step
      `<case_folder>/logs/FINAL_REPORT.md` — user-facing summary

    Returns a dict with keys: case_folder, logs_dir, final_summary, history, finish_reason
    """
    case_path = Path(case_folder).expanduser().resolve()
    logs_dir = ensure_logs_dir(case_path)

    inventory = list_case_inventory(case_path)

    state: dict[str, Any] = {
        "user_query": user_query,
        "case_folder": str(case_path),
        "max_steps": max_steps,
        "step_index": 0,
        "inventory": inventory,
        "history": [],
    }

    append_step_jsonl(
        logs_dir,
        {
            "kind": "run_start",
            "ts": utc_now_iso(),
            "user_query": user_query,
            "case_folder": str(case_path),
            "max_steps": max_steps,
            "inventory": inventory,
        },
    )

    async def investigation_loop(session) -> dict[str, Any]:
        finish_reason = "completed"
        final_summary = ""

        for step_num in range(max_steps):
            state["step_index"] = step_num
            model_ctx = _build_model_context(state)
            print(
                f"[step {step_num}] Waiting: LLM reasoning (choosing next action)…",
                flush=True,
            )
            decision = decide_next_step(model_ctx)

            if decision["action"] == "finish":
                final_summary = decision.get("summary", "")
                append_step_jsonl(
                    logs_dir,
                    {
                        "kind": "model_finish",
                        "ts": utc_now_iso(),
                        "step": step_num,
                        "reasoning": decision.get("reasoning", ""),
                        "summary": final_summary,
                    },
                )
                finish_reason = "completed"
                break

            tool_name = decision["action"]
            tool_args = decision.get("args") or {}
            reasoning = decision.get("reasoning", "")

            print(
                f"[step {step_num}] Waiting: MCP tool / subprocess ({tool_name})…",
                flush=True,
            )
            try:
                result = await session.call_tool(tool_name, arguments=tool_args)
                serial = tool_result_to_serializable(result)
            except Exception as e:
                serial = {
                    "isError": True,
                    "text": str(e),
                    "parsed": None,
                }

            result_for_log = truncate_value(serial, MAX_JSONL_RESULT_CHARS)
            result_summary = truncate_value(redact_for_llm(serial), 8000)

            record = {
                "kind": "tool_step",
                "ts": utc_now_iso(),
                "step": step_num,
                "reasoning": reasoning,
                "action": tool_name,
                "args": tool_args,
                "result": result_for_log,
            }
            append_step_jsonl(logs_dir, record)

            state["history"].append(
                {
                    "step": step_num,
                    "reasoning": reasoning,
                    "action": tool_name,
                    "args": tool_args,
                    "result_summary": result_summary,
                }
            )

        else:
            finish_reason = "max_steps"
            final_summary = _max_steps_summary(state)
            append_step_jsonl(
                logs_dir,
                {
                    "kind": "run_end_max_steps",
                    "ts": utc_now_iso(),
                    "summary": final_summary,
                },
            )

        report_body = _format_final_report(
            user_query=user_query,
            case_folder=str(case_path),
            final_summary=final_summary,
            finish_reason=finish_reason,
            state=state,
        )
        write_final_report(logs_dir, report_body)

        return {
            "case_folder": str(case_path),
            "logs_dir": str(logs_dir),
            "final_summary": final_summary,
            "history": state["history"],
            "finish_reason": finish_reason,
        }

    return asyncio.run(run_with_mcp_session(investigation_loop))


def _format_final_report(
    *,
    user_query: str,
    case_folder: str,
    final_summary: str,
    finish_reason: str,
    state: dict[str, Any],
) -> str:
    lines = [
        "# Forensic investigation report",
        "",
        "## User query",
        "",
        user_query.strip(),
        "",
        "## Case folder",
        "",
        f"`{case_folder}`",
        "",
        "## Outcome",
        "",
        f"- **Finish reason:** `{finish_reason}`",
        "",
        "## Findings summary",
        "",
        final_summary.strip() or "_No summary produced._",
        "",
        "## Step overview",
        "",
    ]
    for h in state.get("history", []):
        lines.append(f"{h.get('step', 0) + 1}. **{h.get('action')}** — {h.get('reasoning', '')}")
    lines.extend(
        [
            "",
            "## Log files",
            "",
            "- `investigation_steps.jsonl` — full step records and tool output",
            "- `FINAL_REPORT.md` — this report",
            "",
        ]
    )
    return "\n".join(lines)

def _cli() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        description="Run a forensic investigation (MCP tools + Gemini). Requires API_KEY."
    )
    parser.add_argument(
        "--case",
        required=True,
        help="Case directory (must exist; logs/ will be created under it)",
    )
    q = parser.add_mutually_exclusive_group(required=True)
    q.add_argument(
        "--query",
        help="Investigation goal in natural language",
    )
    q.add_argument(
        "--query-file",
        type=Path,
        metavar="PATH",
        help="Read investigation goal from this file (UTF-8; supports multiple lines)",
    )
    parser.add_argument(
        "--max-steps",
        type=int,
        default=12,
        help="Maximum MCP tool calls before stopping (default: 12)",
    )
    args = parser.parse_args()
    if args.query_file is not None:
        user_query = args.query_file.expanduser().resolve().read_text(encoding="utf-8")
    else:
        user_query = args.query
    out = run_investigation(
        user_query=user_query,
        case_folder=args.case,
        max_steps=args.max_steps,
    )
    print(json.dumps({k: out[k] for k in ("case_folder", "logs_dir", "finish_reason")}, indent=2))
    print("\nFinal summary:\n", out.get("final_summary", ""))


if __name__ == "__main__":
    _cli()
