"""Case folder logging: logs/ subfolder, JSONL steps, final report."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def ensure_logs_dir(case_folder: Path) -> Path:
    case_folder = case_folder.expanduser().resolve()
    logs = case_folder / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    return logs


def list_case_inventory(case_folder: Path, *, max_entries: int = 200) -> list[dict[str, Any]]:
    """Shallow listing of the case folder (not under logs/) for model context."""
    case_folder = case_folder.expanduser().resolve()
    if not case_folder.is_dir():
        raise NotADirectoryError(f"Case folder is not a directory: {case_folder}")

    entries: list[dict[str, Any]] = []
    for p in sorted(case_folder.iterdir(), key=lambda x: x.name.lower()):
        if p.name == "logs":
            continue
        try:
            st = p.stat()
            kind = "dir" if p.is_dir() else "file"
            entries.append(
                {
                    "name": p.name,
                    "kind": kind,
                    "size_bytes": st.st_size if kind == "file" else None,
                }
            )
        except OSError:
            entries.append({"name": p.name, "kind": "unknown", "size_bytes": None})
        if len(entries) >= max_entries:
            entries.append({"note": f"listing truncated at {max_entries} entries"})
            break
    return entries


def redact_for_llm(value: Any) -> Any:
    """
    Strip binary/base64 and huge text from tool results before they go to the LLM (token-safe).
    Full payloads remain in JSONL logs via the separate truncation path in pipeline.
    """
    if isinstance(value, dict):
        out: dict[str, Any] = {}
        for k, v in value.items():
            lk = str(k).lower()
            if lk == "stdout_base64" or lk.endswith("_base64") or "base64" in lk:
                s = v if isinstance(v, str) else str(v)
                out[k] = f"<omitted binary field ({len(s)} chars)>"
            else:
                out[k] = redact_for_llm(v)
        # Avoid duplicating huge JSON in `text` when structured `parsed` exists
        if (
            out.get("parsed") is not None
            and isinstance(out.get("text"), str)
            and len(out["text"]) > 2000
        ):
            out["text"] = f"<omitted raw text ({len(out['text'])} chars); see parsed>"
        return out
    if isinstance(value, list):
        return [redact_for_llm(v) for v in value[:500]]
    if isinstance(value, str) and len(value) > 12000:
        return f"<omitted long string ({len(value)} chars)>"
    return value


def truncate_value(value: Any, max_chars: int) -> Any:
    """Truncate large strings (and JSON-serialized blobs) for storage/context."""
    if isinstance(value, str) and len(value) > max_chars:
        return value[:max_chars] + f"\n... [truncated, original length {len(value)} chars]"
    if isinstance(value, dict):
        return {k: truncate_value(v, max_chars) for k, v in value.items()}
    if isinstance(value, list):
        return [truncate_value(v, max_chars) for v in value[:500]]
    return value


def append_step_jsonl(logs_dir: Path, record: dict[str, Any]) -> Path:
    path = logs_dir / "investigation_steps.jsonl"
    line = json.dumps(record, ensure_ascii=False, default=str) + "\n"
    with path.open("a", encoding="utf-8") as f:
        f.write(line)
    return path


def write_final_report(logs_dir: Path, body: str, *, filename: str = "FINAL_REPORT.md") -> Path:
    path = logs_dir / filename
    path.write_text(body, encoding="utf-8")
    return path


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()
