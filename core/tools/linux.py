"""
Wrappers around common Linux CLI tools for digital forensics.
Uses subprocess with argument lists and limits output size.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Any

DEFAULT_TIMEOUT_SEC = 120
DEFAULT_MAX_OUTPUT_BYTES = 2_000_000


class LinuxToolError(RuntimeError):
    """Raised when a command fails or output is truncated."""


def _resolve_path(path: str) -> Path:
    p = Path(path).expanduser().resolve()
    if not p.exists():
        raise FileNotFoundError(f"Path does not exist: {path}")
    return p


def _run(
    cmd: list[str],
    *,
    timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
    stdin: int | None = None,
) -> dict[str, Any]:
    try:
        run_kw: dict[str, Any] = {
            "capture_output": True,
            "timeout": timeout_sec,
            "check": False,
            "text": True,
            "errors": "replace",
        }
        if stdin is not None:
            run_kw["stdin"] = stdin
        proc = subprocess.run(cmd, **run_kw)
    except subprocess.TimeoutExpired as e:
        raise LinuxToolError(f"Command timed out after {timeout_sec}s: {' '.join(cmd)}") from e

    out = proc.stdout or ""
    err = proc.stderr or ""
    truncated = len(out.encode("utf-8", errors="replace")) > max_output_bytes
    if truncated:
        out = out.encode("utf-8", errors="replace")[:max_output_bytes].decode(
            "utf-8", errors="replace"
        )
        out += "\n... [output truncated]\n"

    return {
        "command": cmd,
        "returncode": proc.returncode,
        "stdout": out,
        "stderr": err,
        "truncated": truncated,
    }

def register_file_discovery_tools(mcp):
    @mcp.tool()
    def ls_path(
        path: str,
        *,
        long_format: bool = True,
        all_entries: bool = True,
        human_readable: bool = True,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Run `ls` on a file or directory (-laH style for forensics listings)."""
        target = _resolve_path(path)
        cmd = ["ls"]
        if long_format:
            cmd.append("-l")
        if all_entries:
            cmd.append("-a")
        if human_readable:
            cmd.append("-h")
        cmd.append(str(target))
        return _run(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def find_paths(
        start_path: str,
        *,
        name_glob: str | None = None,
        path_glob: str | None = None,
        type_flag: str | None = None,
        maxdepth: int | None = None,
        mindepth: int | None = None,
        print0: bool = False,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Run GNU/BSD `find`. `type_flag` is one of f, d, l (passed to -type).
        """
        root = _resolve_path(start_path)
        if not root.is_dir():
            raise NotADirectoryError(f"find start path must be a directory: {start_path}")

        cmd: list[str] = ["find", str(root)]
        if maxdepth is not None:
            cmd.extend(["-maxdepth", str(maxdepth)])
        if mindepth is not None:
            cmd.extend(["-mindepth", str(mindepth)])
        if type_flag is not None:
            if type_flag not in ("f", "d", "l", "b", "c", "p", "s"):
                raise ValueError("type_flag must be a single find -type letter")
            cmd.extend(["-type", type_flag])
        if name_glob is not None:
            cmd.extend(["-name", name_glob])
        if path_glob is not None:
            cmd.extend(["-path", path_glob])
        cmd.append("-print" + ("0" if print0 else ""))

        return _run(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def cat_file(
        path: str,
        *,
        max_bytes: int = 1_000_000,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Read file contents via bounded read (forensic-safe `cat` equivalent).
        Uses Python to avoid loading unbounded files into memory.
        """
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"cat expects a regular file: {path}")

        with target.open("rb") as f:
            data = f.read(max_bytes)
        truncated = target.stat().st_size > len(data)
        text = data.decode("utf-8", errors="replace")
        if truncated:
            text += "\n... [truncated to max_bytes]\n"

        return {
            "command": ["cat", "<bounded read>", str(target)],
            "path": str(target),
            "size_bytes": target.stat().st_size,
            "returncode": 0,
            "stdout": text,
            "stderr": "",
            "truncated": truncated,
        }

    @mcp.tool()
    def less_view(
        path: str,
        *,
        lines: int = 100,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Non-interactive preview of the start of a file (uses `head`; true `less` is interactive).
        Suitable for triage the way an examiner might open a log in a pager.
        """
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"less_view expects a regular file: {path}")

        cmd = ["head", "-n", str(lines), str(target)]
        return _run(cmd, timeout_sec=timeout_sec)


def register_content_extraction_tools(mcp):
    @mcp.tool()
    def strings_file(
        path: str,
        *,
        min_len: int = 4,
        encoding: str | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Run `strings` to recover printable sequences from binary data."""
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"strings expects a regular file: {path}")

        cmd = ["strings", "-n", str(min_len)]
        if encoding:
            cmd.extend(["-e", encoding])
        cmd.append(str(target))
        return _run(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def grep_path(
        pattern: str,
        path: str,
        *,
        ignore_case: bool = False,
        line_number: bool = True,
        recursive: bool = False,
        extended_regexp: bool = True,
        max_count: int | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Run `grep` on a file or recursively under a directory."""
        target = _resolve_path(path)
        cmd = ["grep"]
        if extended_regexp:
            cmd.append("-E")
        if ignore_case:
            cmd.append("-i")
        if line_number:
            cmd.append("-n")
        if recursive:
            cmd.append("-r")
        if max_count is not None:
            cmd.extend(["-m", str(max_count)])
        cmd.extend([pattern, str(target)])
        return _run(cmd, timeout_sec=timeout_sec)


def register_binary_tools(mcp):
    @mcp.tool()
    def hexdump_file(
        path: str,
        *,
        length_bytes: int | None = None,
        skip_bytes: int = 0,
        canonical: bool = True,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Run `hexdump` (-C canonical hex + ASCII)."""
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"hexdump expects a regular file: {path}")

        cmd = ["hexdump"]
        if canonical:
            cmd.append("-C")
        if skip_bytes:
            cmd.extend(["-s", str(skip_bytes)])
        if length_bytes is not None:
            cmd.extend(["-n", str(length_bytes)])
        cmd.append(str(target))
        return _run(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def xxd_file(
        path: str,
        *,
        length_bytes: int | None = None,
        skip_bytes: int = 0,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Run `xxd` with optional seek/skip and length limits."""
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"xxd expects a regular file: {path}")

        cmd = ["xxd"]
        if skip_bytes:
            cmd.extend(["-s", str(skip_bytes)])
        if length_bytes is not None:
            cmd.extend(["-l", str(length_bytes)])
        cmd.append(str(target))
        return _run(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def sha256sum_file(path: str, *, timeout_sec: int = DEFAULT_TIMEOUT_SEC) -> dict[str, Any]:
        """Compute SHA-256 digest (GNU coreutils `sha256sum`)."""
        target = _resolve_path(path)
        if not target.is_file():
            raise IsADirectoryError(f"sha256sum expects a regular file: {path}")

        cmd = ["sha256sum", str(target)]
        return _run(cmd, timeout_sec=timeout_sec)


DEFAULT_EWFEXPORT_TIMEOUT_SEC = 3600


def register_ewf_tools(mcp):
    @mcp.tool()
    def ewfexport(
        image_path: str,
        target_path: str,
        *,
        output_format: str | None = None,
        quiet: bool = True,
        timeout_sec: int = DEFAULT_EWFEXPORT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Export Expert Witness / EnCase (E01, etc.) to another format, usually raw (`ewfexport` from libewf).
        Always uses unattended mode (`-u`, no prompts) for MCP/subprocess use. Writes to `target_path`
        (parent directories are created). Large images need a high `timeout_sec`.
        """
        src = _resolve_path(image_path)
        if not src.is_file():
            raise IsADirectoryError(f"ewfexport expects an existing evidence file: {image_path}")

        tgt = Path(target_path).expanduser().resolve()
        tgt.parent.mkdir(parents=True, exist_ok=True)

        # -u: unattended (no prompts); -q: suppress progress messages (default on for automation)
        cmd: list[str] = ["ewfexport", "-u"]
        if quiet:
            cmd.append("-q")
        if output_format is not None:
            cmd.extend(["-f", output_format])
        cmd.extend(["-t", str(tgt), str(src)])
        return _run(
            cmd,
            timeout_sec=timeout_sec,
            max_output_bytes=DEFAULT_MAX_OUTPUT_BYTES,
            stdin=subprocess.DEVNULL,
        )