# CLAUDE.md

**Course:** 14-822 -- Host Based Forensics
**Scenario:** File Carving Exercise

---

## Case Overview

| Field | Value |
|-------|-------|
| **Client** | Carnegie Mellon University (CMU) |
| **Domain** |  |
| **Threat Actor** | User John Doe |
| **Incident Declared** | 2026-03-24 |
| **Your Role** | External IR consultant |
| **Initial Responders** | Haylee Viramontes, Chen Tao, Chloe Taylor |

---

## Evidence Files

| File | System | Notes |
|------|--------|-------|
| `~/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01` | Canon Image File | Canon (~31 MB) |

**Read-only — do NOT modify evidence files.**
Output all analysis to `./analysis/`, `./exports/`, or `./reports/` (relative to `~/cases/CORPUS/`).

---

## Common Commands

### Mount E01 images (read-only)

```bash
# Mount and verify nps-2008-jean.E01 Windows drive
sudo mkdir -p /mnt/ewf_cg6 /mnt/cg6
sudo ewfmount ~/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01 /mnt/ewf_cg6
ewfverify ~/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01
sudo mount -o ro,loop,noatime /mnt/ewf_cg6/ewf1 /mnt/cg6

# Unmount when done
sudo umount /mnt/cg6 && sudo umount /mnt/ewf_cg6
```

### Volatility 3 (memory — .mem, .raw, .vmem)
Note: No separate memory image in this case. Running Volatility against the disk image — memory analysis plugins will not apply.

### Memory Baseliner (process / service / driver diff)
Not available; No baseline JSON files present on host.

### EZ Tools (dotnet, Windows artifacts from mounted image)

```bash
# MFTECmd — parse MFT
dotnet /opt/zimmermantools/MFTECmd.dll \
  -f /mnt/cg6/\$MFT \
  --csv ./exports/ --csvf cg6-mft.csv

# EvtxECmd — parse event logs
dotnet /opt/zimmermantools/EvtxeCmd/EvtxECmd.dll \
  -d /mnt/cg6/Windows/System32/winevt/Logs/ \
  --csv ./exports/ --csvf cg6-evtx.csv \
  --maps /opt/zimmermantools/EvtxeCmd/Maps/

# RECmd — registry hives
dotnet /opt/zimmermantools/RECmd/RECmd.dll \
  -d /mnt/cg6/Windows/System32/config/ \
  --csv ./exports/ --csvf cg6-registry.csv

# AmcacheParser
dotnet /opt/zimmermantools/AmcacheParser.dll \
  -f /mnt/cg6/Windows/AppCompat/Programs/Amcache.hve \
  --csv ./exports/ --csvf cg6-amcache.csv
```

### Sleuth Kit (filesystem, no mount required)

```bash
# List files — cg6 image
fls -r -o 2048 /mnt/ewf_cg6/ewf1

# Search for a specific filename
fls -r -o 2048 /mnt/ewf_cg6/ewf1 | grep -i "<filename>"

# Extract a file by inode
icat -o 2048 /mnt/ewf_cg6/ewf1 <INODE> > ./exports/<filename>

# Verify image
ewfverify ~/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01
```

---

## Reference: Volatility 3 (N/A to this case)
**Note:** These commands require a memory dump (.mem/.raw/.vmem). They are kept here for reference only.

```bash
VOL="~/.local/bin/vol"
IMG="/mnt/ewf_cg6/ewf1"

# Human-readable process tree
$VOL -f $IMG -r pretty windows.pstree | cut -d '|' -f 1-11

# All processes incl. exited
$VOL -f $IMG windows.psscan | grep -v "N/A"

# Command lines
$VOL -f $IMG windows.cmdline | tee ./exports/cmdline.txt

# Process SIDs
$VOL -f $IMG windows.getsids | tee ./exports/getsids.txt

# Network connections
$VOL -f $IMG -r csv windows.netstat | tee ./exports/netstat.csv

# DLL list for a specific PID (Replace PID as needed)
$VOL -f $IMG -r csv windows.dlllist --pid <PID> | tee ./exports/dlllist-<PID>.csv
```

## Notes
- Run `mmls /mnt/ewf_cg6/ewf1` to confirm partition offset before running fls or icat — 2048 is assumed but must be verified
- ewfmount must be running before Volatility, Sleuth Kit, or EZ Tools commands
- **VSCMount** is Windows-only — do not use on SIFT.
- Timestamps: always report in UTC.
- Vol3 binary: `~/.local/bin/vol` (v2.27.0) — NOT `/usr/local/bin/vol.py` (that is Vol2).
