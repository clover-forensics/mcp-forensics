"""MCP stdio client: one session per investigation run."""

from __future__ import annotations

import json
import os
import sys
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

REPO_ROOT = Path(__file__).resolve().parent.parent


def get_stdio_server_parameters() -> StdioServerParameters:
    # Same interpreter as the agent (critical in Docker so venv/site-packages match).
    py = os.environ.get("PYTHON", sys.executable)
    return StdioServerParameters(
        command=py,
        args=[str(REPO_ROOT / "core" / "mcp_server.py")],
        cwd=str(REPO_ROOT),
        env={**os.environ, "PYTHONPATH": str(REPO_ROOT)},
    )


def tool_result_to_serializable(result: Any) -> dict[str, Any]:
    """Turn MCP CallToolResult into a JSON-friendly dict for logs and model context."""
    out: dict[str, Any] = {"isError": getattr(result, "isError", False)}
    parts: list[str] = []
    for block in getattr(result, "content", []) or []:
        text = getattr(block, "text", None)
        if text is not None:
            parts.append(text)
        else:
            parts.append(str(block))
    joined = "\n".join(parts)
    out["text"] = joined
    try:
        out["parsed"] = json.loads(joined)
    except (json.JSONDecodeError, TypeError):
        out["parsed"] = None
    return out


async def run_with_mcp_session(
    fn: Callable[[ClientSession], Awaitable[Any]],
) -> Any:
    """Run async `fn(session)` with a single initialized MCP client session."""
    params = get_stdio_server_parameters()
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            return await fn(session)
