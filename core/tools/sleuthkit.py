"""
Wrappers for The Sleuth Kit CLI tools used in disk/volume forensics.
Builds argv lists (no shell), caps text/binary output, and uses generous timeouts for images.
"""

from __future__ import annotations

import base64
import subprocess
from pathlib import Path
from typing import Any

DEFAULT_TIMEOUT_SEC = 300
DEFAULT_MAX_OUTPUT_BYTES = 2_000_000
DEFAULT_MAX_BINARY_BYTES = 1_000_000


class SleuthKitError(RuntimeError):
    """Raised when a Sleuth Kit command times out or cannot be run."""


def _resolve_path(path: str, *, must_exist: bool = True) -> Path:
    p = Path(path).expanduser().resolve()
    if must_exist and not p.exists():
        raise FileNotFoundError(f"Path does not exist: {path}")
    return p


def _append_img_opts(
    cmd: list[str],
    *,
    imgtype: str | None,
    dev_offset: int | None,
    sector_offset: int | None,
    fstype: str | None = None,
) -> None:
    if imgtype is not None:
        cmd.extend(["-i", imgtype])
    if dev_offset is not None:
        cmd.extend(["-b", str(dev_offset)])
    if sector_offset is not None:
        cmd.extend(["-o", str(sector_offset)])
    if fstype is not None:
        cmd.extend(["-f", fstype])


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
        raise SleuthKitError(f"Command timed out after {timeout_sec}s: {' '.join(cmd)}") from e

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


def _run_binary_capped(
    cmd: list[str],
    *,
    max_bytes: int = DEFAULT_MAX_BINARY_BYTES,
    timeout_sec: int = DEFAULT_TIMEOUT_SEC,
) -> dict[str, Any]:
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as e:
        raise SleuthKitError(f"Failed to start: {' '.join(cmd)}: {e}") from e

    assert proc.stdout is not None
    assert proc.stderr is not None
    try:
        data = proc.stdout.read(max_bytes + 1)
        err = proc.stderr.read()
    finally:
        proc.stdout.close()
        proc.stderr.close()
        proc.terminate()
        try:
            proc.wait(timeout=timeout_sec)
        except subprocess.TimeoutExpired:
            proc.kill()

    truncated = len(data) > max_bytes
    if truncated:
        data = data[:max_bytes]

    return {
        "command": cmd,
        "returncode": proc.returncode,
        "stdout_base64": base64.standard_b64encode(data).decode("ascii"),
        "stderr": err.decode("utf-8", errors="replace") if isinstance(err, bytes) else err,
        "bytes_returned": len(data),
        "truncated": truncated,
    }


def register_sleuthkit_tools(mcp) -> None:
    """Register Sleuth Kit MCP tools on the given FastMCP instance."""

    @mcp.tool()
    def tsk_mmls(
        image_path: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """List partition layouts in a disk image (`mmls`)."""
        img = _resolve_path(image_path)
        cmd: list[str] = ["mmls"]
        _append_img_opts(cmd, imgtype=imgtype, dev_offset=dev_offset, sector_offset=None)
        cmd.append(str(img))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_mmstat(
        image_path: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Show volume system / partition metadata (`mmstat`)."""
        img = _resolve_path(image_path)
        cmd: list[str] = ["mmstat"]
        _append_img_opts(cmd, imgtype=imgtype, dev_offset=dev_offset, sector_offset=None)
        cmd.append(str(img))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_mmcat(
        image_path: str,
        partition: str | int,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        max_bytes: int = DEFAULT_MAX_BINARY_BYTES,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Extract raw bytes from a partition slot (`mmcat`). `partition` is the address or index
        as shown by mmls. Output is base64-encoded and capped (images are large).
        """
        img = _resolve_path(image_path)
        cmd: list[str] = ["mmcat"]
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
        )
        cmd.extend([str(img), str(partition)])
        return _run_binary_capped(cmd, max_bytes=max_bytes, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_fsstat(
        image_path: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        fstype: str | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """File system statistics (`fsstat`) for the volume at `-o` sector offset when needed."""
        img = _resolve_path(image_path)
        cmd: list[str] = ["fsstat"]
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
            fstype=fstype,
        )
        cmd.append(str(img))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_fls(
        image_path: str,
        *,
        inode: str | None = None,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        fstype: str | None = None,
        long_output: bool = True,
        recurse: bool = False,
        deleted_only: bool = False,
        undeleted_only: bool = False,
        dot_entries: bool = False,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        List file names in a volume (`fls`). Use `sector_offset` (sector offset to volume) from mmls.
        Pass `inode` to list that directory; omit for root listing.
        Flags: `-l` long, `-r` recurse, `-d` deleted only, `-u` undeleted only, `-a` include "." / "..".
        """
        if deleted_only and undeleted_only:
            raise ValueError("Use at most one of deleted_only or undeleted_only")

        img = _resolve_path(image_path)
        cmd: list[str] = ["fls"]
        if dot_entries:
            cmd.append("-a")
        if deleted_only:
            cmd.append("-d")
        if undeleted_only:
            cmd.append("-u")
        if long_output:
            cmd.append("-l")
        if recurse:
            cmd.append("-r")
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
            fstype=fstype,
        )
        cmd.append(str(img))
        if inode is not None:
            cmd.append(str(inode))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_istat(
        image_path: str,
        inode: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        fstype: str | None = None,
        block_size: int | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """Inode/metadata details (`istat`) for a given inode or artifact id."""
        img = _resolve_path(image_path)
        cmd: list[str] = ["istat"]
        if block_size is not None:
            cmd.extend(["-b", str(block_size)])
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
            fstype=fstype,
        )
        cmd.extend([str(img), str(inode)])
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_icat(
        image_path: str,
        inode: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        max_bytes: int = DEFAULT_MAX_BINARY_BYTES,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Extract file content by inode (`icat`). Data returned as base64, size capped.
        """
        img = _resolve_path(image_path)
        cmd: list[str] = ["icat"]
        _append_img_opts(cmd, imgtype=imgtype, dev_offset=dev_offset, sector_offset=sector_offset)
        cmd.extend([str(img), str(inode)])
        return _run_binary_capped(cmd, max_bytes=max_bytes, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_ffind(
        image_path: str,
        *,
        inode: str | None = None,
        name: str | None = None,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        fstype: str | None = None,
        timeout_sec: int = DEFAULT_TIMEOUT_SEC,
    ) -> dict[str, Any]:
        """
        Find file name path from inode (`-p`) or inode from file name (`-n`) (`ffind`).
        Provide exactly one of `inode` or `name`.
        """
        if (inode is None) == (name is None):
            raise ValueError("ffind requires exactly one of `inode` or `name`")

        img = _resolve_path(image_path)
        cmd: list[str] = ["ffind"]
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
            fstype=fstype,
        )
        if inode is not None:
            cmd.extend(["-p", str(inode)])
        if name is not None:
            cmd.extend(["-n", name])
        cmd.append(str(img))
        return _run_text(cmd, timeout_sec=timeout_sec)

    @mcp.tool()
    def tsk_recover(
        image_path: str,
        output_dir: str,
        *,
        imgtype: str | None = None,
        dev_offset: int | None = None,
        sector_offset: int | None = None,
        fstype: str | None = None,
        recover_allocated_only: bool = False,
        recover_all: bool = False,
        timeout_sec: int = 3600,
    ) -> dict[str, Any]:
        """
        Export files from a volume to `output_dir` (`tsk_recover`). Can consume a lot of disk space.
        Default tool behavior is unallocated files only; pass `recover_allocated_only` (-a) or
        `recover_all` (-e) for other modes.
        """
        if recover_allocated_only and recover_all:
            raise ValueError("Use at most one of recover_allocated_only or recover_all")

        img = _resolve_path(image_path)
        out = _resolve_path(output_dir, must_exist=False)
        out.mkdir(parents=True, exist_ok=True)

        cmd: list[str] = ["tsk_recover"]
        if recover_allocated_only:
            cmd.append("-a")
        if recover_all:
            cmd.append("-e")
        _append_img_opts(
            cmd,
            imgtype=imgtype,
            dev_offset=dev_offset,
            sector_offset=sector_offset,
            fstype=fstype,
        )
        cmd.extend([str(img), str(out)])
        return _run_text(cmd, timeout_sec=timeout_sec, max_output_bytes=DEFAULT_MAX_OUTPUT_BYTES)
