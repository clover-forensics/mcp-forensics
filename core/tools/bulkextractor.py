"""
bulk_extractor — carve features and embedded data from disk images / files.
https://github.com/simsong/bulk_extractor
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Any

DEFAULT_TIMEOUT_SEC = 3600
DEFAULT_MAX_OUTPUT_BYTES = 2_000_000


class BulkExtractorError(RuntimeError):
    pass


def _resolve_path(path: str, *, must_exist: bool = True) -> Path:
    p = Path(path).expanduser().resolve()
    if must_exist and not p.exists():
        raise FileNotFoundError(f"Path does not exist: {path}")
    return p


def _bulk_extractor_binary() -> str:
    for name in ("bulk_extractor", "bulk-extractor"):
        p = shutil.which(name)
        if p:
            return p
    raise BulkExtractorError(
        "bulk_extractor not found in PATH (install bulk-extractor package in the image)"
    )


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
        raise BulkExtractorError(f"Command timed out after {timeout_sec}s: {' '.join(cmd)}") from e

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


def register_bulk_extractor_tools(mcp) -> None:
    @mcp.tool()
    def bulk_extractor_version(
        *,
        timeout_sec: int = 60,
    ) -> dict[str, Any]:
        """Print bulk_extractor version banner (verify install)."""
        be = _bulk_extractor_binary()
        return _run_text([be, "-V"], timeout_sec=timeout_sec, max_output_bytes=50_000)

    @mcp.tool()
    def bulk_extractor_run(
        image_path: str,
        output_dir: str,
        *,
        threads: int | None = None,
        quiet: bool = False,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Run bulk_extractor on an image file or device path; writes feature files under output_dir
        (directory is created if needed). Use for carving URLs, emails, EXIF, zlib, etc.
        """
        img = _resolve_path(image_path)
        if not img.is_file():
            raise IsADirectoryError(f"bulk_extractor expects a file: {image_path}")

        out = _resolve_path(output_dir, must_exist=False)
        out.mkdir(parents=True, exist_ok=True)

        be = _bulk_extractor_binary()
        cmd: list[str] = [be, "-o", str(out)]
        if threads is not None:
            if threads < 1:
                raise ValueError("threads must be >= 1")
            cmd.extend(["-j", str(threads)])
        if quiet:
            cmd.append("-q")
        cmd.append(str(img))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def bulk_extractor_read_report(
        output_dir: str,
        *,
        max_chars: int = 500_000,
        timeout_sec: int = 60,
    ) -> dict[str, Any]:
        """Read bulk_extractor `report.xml` from a completed run (bounded size)."""
        out = _resolve_path(output_dir)
        if not out.is_dir():
            raise NotADirectoryError(f"Not a directory: {output_dir}")
        report = out / "report.xml"
        if not report.is_file():
            raise FileNotFoundError(f"No report.xml in {output_dir}")

        text = report.read_text(encoding="utf-8", errors="replace")
        truncated = len(text) > max_chars
        if truncated:
            text = text[:max_chars] + "\n... [truncated]\n"
        return {
            "command": ["read", str(report)],
            "path": str(report),
            "returncode": 0,
            "stdout": text,
            "stderr": "",
            "truncated": truncated,
        }
