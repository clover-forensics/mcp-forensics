# CLAUDE.md

**Course:** 14-822 -- Host Based Forensics
**Scenario:** Two users are discussing the illegal trade of owls

---

## Case Overview

| Field | Value |
|-------|-------|
| **Client** | Carnegie Mellon University (CMU) |
| **Domain** |  |
| **Threat Actor** | User Jane Doe |
| **Incident Declared** | 2026-01-24 |
| **Your Role** | External IR consultant |
| **Initial Responders** | Haylee Viramontes, Chen Tao, Chloe Taylor |

---

## Evidence Files

| File | System | Notes |
|------|--------|-------|
| `~/cases/OWL_TRADE_2026/evidence/LGE_Nexus_5_Full_Image.raw` | LGE Nexus 5 Full Image.raw | (~29.12 GB) |
| `~/cases/OWL_TRADE_2026/evidence/HD1.E01` | Windows XP NTFS | (~63.46 GB) |

**Read-only — do NOT modify evidence files.**
Output all analysis to `./analysis/`, `./exports/`, or `./reports/` (relative to `/cases/srl/`).

---

## Common Commands

### Mount E01/raw images (read-only)

```bash
# Mount HD1.E01 - Windows disk image
sudo mkdir -p /mnt/ewf_hd1 /mnt/hd1
sudo ewfmount ~/cases/OWL_TRADE_2026/evidence/HD1.E01 /mnt/ewf_hd1
sudo mount -o ro,loop,noatime /mnt/ewf_hd1/ewf1 /mnt/hd1

# Mount LGE Nexus 5 - Android device (check partition offset first)
mmls "~/cases/OWL_TRADE_2026/evidence/LGE_Nexus_5_Full_Image.raw"
sudo mkdir -p /mnt/ln5
sudo mount -o ro,loop,noatime offset=$((OFFSET*512)) ~/cases/OWL_TRADE_2026/evidence/LGE_Nexus_5_Full_Image.raw /mnt/ln5

# Unmount when done
sudo umount /mnt/hd1 && sudo umount /mnt/ewf_hd1
sudo umount /mnt/ln5
```

### Volatility 3 (memory analysis)

```bash
VOL="python3 /opt/volatility3-2.20.0/vol.py"
IMG="~/cases/OWL_TRADE_2026/evidence/HD1.E01"

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

# DLL list for a specific PID (replace PID as needed)
$VOL -f $IMG -r csv windows.dlllist --pid 1912 | tee ./exports/dlllist-stun.csv
```

### Memory Baseliner (process / service / driver diff)
Not available; No baseline JSON files present on host.

### EZ Tools (dotnet, Windows artifacts from mounted image)

```bash
# MFTECmd — parse MFT
dotnet /opt/zimmermantools/MFTECmd.dll \
  -f /mnt/hd1/\$MFT \
  --csv ./exports/ --csvf rd01-mft.csv

# EvtxECmd — parse event logs
dotnet /opt/zimmermantools/EvtxeCmd/EvtxECmd.dll \
  -d /mnt/hd1/Windows/System32/winevt/Logs/ \
  --csv ./exports/ --csvf hd1-evtx.csv \
  --maps /opt/zimmermantools/EvtxeCmd/Maps/

# RECmd — registry hives
dotnet /opt/zimmermantools/RECmd/RECmd.dll \
  -d /mnt/hd1/Windows/System32/config/ \
  --csv ./exports/ --csvf hd1-registry.csv

# AmcacheParser
dotnet /opt/zimmermantools/AmcacheParser.dll \
  -f /mnt/hd1/Windows/AppCompat/Programs/Amcache.hve \
  --csv ./exports/ --csvf hd1-amcache.csv
```

### Sleuth Kit (filesystem, no mount required)

```bash
# List files — hd1 image
fls -r -o 2048 /mnt/ewf_hd1/ewf1

# Search for a specific filename
fls -r -o 2048 /mnt/ewf_hd1/ewf1 | grep ""

# Extract a file by inode
icat -o 2048 /mnt/ewf_hd1/ewf1 <INODE> > ./exports/

# Verify image
ewfverify ~/cases/OWL_TRADE_2026/evidence/HD1.E01

# List files - Android .raw image (using offset from mmls)
fls -r -o ~/cases/OWL_TRADE_2026/evidence/LGE_Nexus_5_Full_Image.raw

# Extract a file by inode - Android
icat -o ~/cases/OWL_TRADE_2026/evidence/LGE_Nexus_5_Full_Image.raw <INODE> > ./exports/
```

### Android-Specific Commands (SQLite)

```bash
# SQLite databases — SMS/MMS
sqlite3 /mnt/ln5/data/data/com.android.providers.telephony/databases/mmssms.db \
  "SELECT * FROM sms;" > ./exports/sms.txt

# Call logs
sqlite3 /mnt/ln5/data/data/com.android.providers.contacts/databases/contacts2.db \
  "SELECT * FROM calls;" > ./exports/calls.txt

# Installed packages
cat /mnt/ln5/data/system/packages.xml > ./exports/installed_packages.xml

# Browser history (Chrome)
sqlite3 /mnt/ln5/data/data/com.android.chrome/app_chrome/Default/History \
  "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC;" \
  > ./exports/browser_history.txt
```

---

## Notes

- **VSCMount** is Windows-only — do not use on SIFT.
- Timestamps: always report in UTC.
- Vol3 binary: `/opt/volatility3-2.20.0/vol.py` — NOT `/usr/local/bin/vol.py` (that is Vol2).
