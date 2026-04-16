"""
Volatility 3 — memory forensics plugins (processes, files, carving from RAM).
Resolves the `vol` launcher from PATH or the same directory as `sys.executable` (pip install).
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

DEFAULT_TIMEOUT_SEC = 600
DEFAULT_MAX_OUTPUT_BYTES = 2_000_000

_PLUGIN_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9_.]*$")
_EXTRA_ARG_RE = re.compile(r"^[-a-zA-Z0-9_./:=@%+]+$")


class VolatilityError(RuntimeError):
    pass


def _resolve_path(path: str, *, must_exist: bool = True) -> Path:
    p = Path(path).expanduser().resolve()
    if must_exist and not p.exists():
        raise FileNotFoundError(f"Path does not exist: {path}")
    return p


def _vol_base_command() -> list[str]:
    for name in ("vol", "vol.py", "volatility", "volatility3"):
        p = shutil.which(name)
        if p:
            return [p]
    # pip install volatility3 places `vol` next to the interpreter (Volatility 3.2+ has no python -m cli)
    exe_dir = Path(sys.executable).resolve().parent
    for candidate in (exe_dir / "vol", exe_dir / "vol.exe"):
        if candidate.is_file():
            return [str(candidate)]
    raise VolatilityError(
        "Volatility 3 `vol` executable not found; install with: pip install volatility3"
    )


def _validate_plugin(name: str) -> str:
    if not _PLUGIN_RE.match(name):
        raise ValueError(
            f"Invalid plugin name {name!r}; use dotted form like windows.info or linux.pslist"
        )
    return name


def _validate_extra_args(args: list[str] | None) -> list[str]:
    if not args:
        return []
    out: list[str] = []
    for a in args:
        if len(a) > 512 or not _EXTRA_ARG_RE.match(a):
            raise ValueError(f"Unsafe or invalid extra argument: {a!r}")
        out.append(a)
    return out


def _run_text(
    cmd: list[str],
    *,
    timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
) -> dict[str, Any]:
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            timeout=timeout_sec,
            check=False,
            text=True,
            errors="replace",
        )
    except subprocess.TimeoutExpired as e:
        raise VolatilityError(f"Command timed out after {timeout_sec}s: {' '.join(cmd)}") from e

    out = proc.stdout or ""
    err = proc.stderr or ""
    raw = out.encode("utf-8", errors="replace")
    truncated = len(raw) > max_output_bytes
    if truncated:
        out = raw[:max_output_bytes].decode("utf-8", errors="replace") + "\n... [output truncated]\n"

    return {
        "command": cmd,
        "returncode": proc.returncode,
        "stdout": out,
        "stderr": err,
        "truncated": truncated,
    }


def register_volatility_tools(mcp) -> None:
    @mcp.tool()
    def volatility_version(
        *,
        timeout_sec: int = 120,
    ) -> dict[str, Any]:
        """Show Volatility 3 version / banner."""
        base = _vol_base_command()
        return _run_text(base + ["-V"], timeout_sec=timeout_sec, max_output_bytes=100_000)

    @mcp.tool()
    def volatility_run(
        image_path: str,
        plugin: str,
        *,
        output_dir: str | None = None,
        extra_args: list[str] | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Run a Volatility 3 plugin against a memory image (e.g. windows.info, linux.pslist,
        windows.filescan, windows.dumpfiles). Optional output_dir for plugins that write files.
        Pass plugin-specific flags via extra_args (e.g. ["--pid", "4"]).
        """
        img = _resolve_path(image_path)
        if not img.is_file():
            raise IsADirectoryError(f"Expected a memory image file: {image_path}")

        plug = _validate_plugin(plugin)
        extras = _validate_extra_args(extra_args)

        base = _vol_base_command()
        cmd: list[str] = [*base, "-f", str(img)]
        if output_dir is not None:
            outp = _resolve_path(output_dir, must_exist=False)
            outp.mkdir(parents=True, exist_ok=True)
            cmd.extend(["-o", str(outp)])
        cmd.append(plug)
        cmd.extend(extras)
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def volatility_list_plugins(
        *,
        filter_prefix: str | None = None,
        timeout_sec: int = 120,
    ) -> dict[str, Any]:
        """
        List available Volatility modules (long output). Optionally filter lines containing filter_prefix.
        """
        base = _vol_base_command()
        result = _run_text(
            base + ["--help"],
            timeout_sec=timeout_sec,
            max_output_bytes=DEFAULT_MAX_OUTPUT_BYTES,
        )
        if filter_prefix and result.get("stdout"):
            lines = [ln for ln in result["stdout"].splitlines() if filter_prefix in ln]
            result = {
                **result,
                "stdout": "\n".join(lines[:2000])
                + ("\n... [line filter truncated]" if len(lines) > 2000 else ""),
                "filtered": True,
            }
        return result
