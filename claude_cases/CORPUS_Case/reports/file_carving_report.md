# File Carving Analysis Report
## Case: 14-822 — Host Based Forensics / File Carving Exercise

| Field | Value |
|-------|-------|
| **Client** | Carnegie Mellon University (CMU) |
| **Examiner** | External IR Consultant |
| **Report Date** | 2026-04-16 (UTC) |
| **Evidence** | `~/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01` |
| **Analysis Host** | SANS SIFT Workstation |

---

## 1. Evidence Integrity

| Item | Value |
|------|-------|
| Image format | EnCase 6 (EWF) |
| Acquisition date | 2010-08-06 00:06:08 UTC |
| Acquiring OS | Darwin (macOS) |
| Media type | Removable disk (memory card) |
| Media size | 31,129,600 bytes (29 MiB) |
| Sectors | 60,800 @ 512 bytes/sector |
| MD5 (stored in E01) | `750b509d8fbed37a5213480aaccfdc61` |
| MD5 (verified at analysis) | `750b509d8fbed37a5213480aaccfdc61` |
| **Integrity check** | **PASSED — image unmodified** |

---

## 2. Filesystem Overview

| Item | Value |
|------|-------|
| Partition table | MBR / DOS |
| Partition 1 | Sectors 51–60799 (type 0x04 DOS FAT16, actual FAT12) |
| Filesystem | FAT12 |
| Volume label | `CANON_DC` |
| OEM name | `PwrShot` |
| Cluster size | 16,384 bytes (32 sectors) |
| Camera model | **Canon PowerShot SD800 IS** |
| Image resolution | 640×480, 1600×1200, 2048×1536, 3072×2304 |
| Focal length | 4.6 mm (all frames, fixed zoom) |

---

## 3. Filesystem Enumeration

```
fls -r -p -o 51 /mnt/ewf_cg6/ewf1
```

| Category | Count |
|----------|-------|
| Allocated JPEG files (DCIM/100CANON/) | 34 |
| Deleted JPEG files (directory entry preserved) | 3 |
| Canon catalog file (M0100.CTG) | 1 |
| **Total directory entries** | **38** |

### 3.1 Allocated Files

```
DCIM/100CANON/IMG_0003.JPG   (840,101 bytes)   inode 1031
DCIM/100CANON/IMG_0007.JPG   (865,313 bytes)   inode 1035
DCIM/100CANON/IMG_0009.JPG   (840,692 bytes)   inode 1037
DCIM/100CANON/IMG_0011.JPG   (771,052 bytes)   inode 1039
DCIM/100CANON/IMG_0013.JPG   (842,160 bytes)   inode 1041
DCIM/100CANON/IMG_0016.JPG   (853,839 bytes)   inode 1044
DCIM/100CANON/IMG_0017.JPG   (795,574 bytes)   inode 1045
DCIM/100CANON/IMG_0018.JPG   (784,455 bytes)   inode 1046
DCIM/100CANON/IMG_0019.JPG   (864,257 bytes)   inode 1047
DCIM/100CANON/IMG_0021.JPG   (819,599 bytes)   inode 1049
DCIM/100CANON/IMG_0022.JPG   (728,696 bytes)   inode 1050
DCIM/100CANON/IMG_0023.JPG   (858,798 bytes)   inode 1051
DCIM/100CANON/IMG_0024.JPG   (838,434 bytes)   inode 1052
DCIM/100CANON/IMG_0026.JPG   (768,385 bytes)   inode 1054
DCIM/100CANON/IMG_0027.JPG   (840,253 bytes)   inode 1055
DCIM/100CANON/IMG_0028.JPG   (815,636 bytes)   inode 1056
DCIM/100CANON/IMG_0029.JPG   (861,552 bytes)   inode 1057
DCIM/100CANON/IMG_0031.JPG   (749,202 bytes)   inode 1059
DCIM/100CANON/IMG_0032.JPG   (879,834 bytes)   inode 1060
DCIM/100CANON/IMG_0033.JPG   (845,375 bytes)   inode 1061
DCIM/100CANON/IMG_0034.JPG   (812,465 bytes)   inode 1062
DCIM/100CANON/IMG_0036.JPG   (882,337 bytes)   inode 1064
DCIM/100CANON/IMG_0038.JPG (1,296,150 bytes)   inode 1038
DCIM/100CANON/IMG_0042.JPG (1,361,807 bytes)   inode 1030
DCIM/100CANON/IMG_0043.JPG (2,834,018 bytes)   inode 1032
DCIM/100CANON/IMG_0044.JPG   (105,195 bytes)   inode 1029
DCIM/100CANON/IMG_0045.JPG   (110,686 bytes)   inode 1033
DCIM/100CANON/IMG_0046.JPG   (116,135 bytes)   inode 1034
DCIM/100CANON/IMG_0047.JPG   (120,441 bytes)   inode 1036
DCIM/100CANON/IMG_0048.JPG   (124,906 bytes)   inode 1040
DCIM/100CANON/IMG_0049.JPG   (114,940 bytes)   inode 1042
DCIM/100CANON/IMG_0050.JPG   (127,191 bytes)   inode 1043
DCIM/100CANON/IMG_0051.JPG   (130,418 bytes)   inode 1048
DCIM/CANONMSC/M0100.CTG      (164 bytes)        inode 943621
```

### 3.2 Deleted Files (Directory Entry Present)

| Filename | Inode | Size | Dir Entry Timestamp | FAT Chain | Data Status |
|----------|-------|------|---------------------|-----------|-------------|
| `_MG_0025.JPG` (IMG_0025) | 1053 | 791,333 B | 2008-12-23 14:14:40 UTC | Freed | **Overwritten — unrecoverable** |
| `_MG_0030.JPG` (IMG_0030) | 1058 | 867,833 B | 2008-12-23 14:15:02 UTC | Freed | **Partially overwritten; embedded thumbnail recovered** |
| `_MG_0035.JPG` (IMG_0035) | 1063 | 820,105 B | 2008-12-23 14:15:28 UTC | Freed | **Overwritten — unrecoverable** |

> **Note on TSK naming:** FAT deletion replaces the first character of the 8.3 filename with 0xE5; TSK renders this as `_`. The original filenames were `IMG_0025.JPG`, `IMG_0030.JPG`, `IMG_0035.JPG`.

---

## 4. Deleted File Recovery Analysis

### 4.1 inode 1053 — IMG_0025.JPG

- **Cluster range:** sectors 39,437–40,982 (partition-relative)
- **Raw sector content at start:** `7b f1 5c df 88 fc 43 a7` — no JPEG signature (FF D8 FF)
- **Assessment:** Entire data region was reallocated and overwritten by subsequent writes to the card.
- **Recovered:** NO (791,333 bytes extracted but not a valid JPEG; icat returns overwritten data)

### 4.2 inode 1058 — IMG_0030.JPG

- **Cluster range:** sectors 47,469–49,163 (partition-relative)
- **Raw sector content at start:** `49 e6 7c a3 ec ac 4e 5d` — no JPEG signature
- **Assessment:** First ~622 KB overwritten. Embedded EXIF thumbnail (at byte offset 622,592 within the original file space) survives intact.
- **EXIF capture time:** 2008-12-23 14:26:13 UTC
- **Recovered:** PARTIAL — 8,808-byte embedded thumbnail extracted to `exports/files/IMG_0030_exif_thumb.JPG`

### 4.3 inode 1063 — IMG_0035.JPG

- **Cluster range:** sectors 55,629–57,228 (partition-relative)
- **Raw sector content at start:** `9f 08 78 cf c0 5f 00 7e` — no JPEG signature
- **Assessment:** Entire data region overwritten.
- **Recovered:** NO

---

## 5. Unallocated Space Carving

Three JPEG files were found in unallocated space with **no corresponding directory entries** — their directory entries were overwritten (deeper deletion than the three above). Their data blocks partially survived.

| Carved File | Start Sector (fs) | Carved Size | EXIF Capture Time | Resolution | Status |
|-------------|-------------------|-------------|-------------------|------------|--------|
| `CARVED_unalloc_sec21421.JPG` | 21,421 | **873,437 bytes** | 2008-12-23 14:13:45 UTC | 1600×1200 | **FULLY RECOVERED** |
| `CARVED_unalloc_sec23533.JPG` | 23,533 | 9,164 bytes | 2008-12-23 14:22:54 UTC | 2048×1536 | Thumbnail only (truncated) |
| `CARVED_unalloc_sec32845.JPG` | 32,845 | 9,082 bytes | 2008-12-23 14:23:01 UTC | 2048×1536 | Thumbnail only (truncated) |

- **sec21421:** Full JPEG from 1728-sector unallocated gap; all data intact, EOI found at byte 873,435. This is a completely recoverable original photograph.
- **sec23533 & sec32845:** Only the leading EXIF APP1 block (including thumbnail) survived. The main image data was overwritten.

---

## 6. File Manifest (Exported Evidence)

| File | Size (bytes) | MD5 | Notes |
|------|-------------|-----|-------|
| `CARVED_unalloc_sec21421.JPG` | 873,437 | `2c11f3b009dacc24896c0c0cb0df924c` | Full JPEG, captured 2008-12-23 14:13:45 |
| `CARVED_unalloc_sec23533.JPG` | 9,164 | `aee494b6fe449c22c0d20fb2fe51e5b0` | EXIF thumbnail only, 2008-12-23 14:22:54 |
| `CARVED_unalloc_sec32845.JPG` | 9,082 | `7de378d819b17222d0f40b69486d5207` | EXIF thumbnail only, 2008-12-23 14:23:01 |
| `IMG_0030_exif_thumb.JPG` | 8,808 | `e02e1d4ce1baae6af98efb92850d0d87` | Embedded thumbnail from deleted _MG_0030 |
| `M0100.CTG` | 164 | `b8ae356e040f8242122537c66e4dc961` | Canon image catalog file |
| `RECOVERED_IMG_0025.JPG` | 791,333 | `9ab4246657429642b4ee4a3a132036bc` | icat output — NOT a valid JPEG (overwritten) |
| `RECOVERED_IMG_0030.JPG` | 867,833 | `7b5bbe656fea8bfde21f162b2f150ed0` | icat output — NOT a valid JPEG (first 622KB overwritten) |
| `RECOVERED_IMG_0035.JPG` | 820,105 | `648a37e0f4c8a7a4eaaa7779186e776b` | icat output — NOT a valid JPEG (overwritten) |

---

## 7. EXIF Timeline — All Detected Images (Chronological)

All images taken with **Canon PowerShot SD800 IS**, focal length 4.6 mm. No GPS data in any frame.

### Session A — 2008-12-23, 14:12–14:15 UTC (1600×1200, outdoor/daylight)

| Time (UTC) | FS Sector | Status | Exposure |
|-----------|-----------|--------|----------|
| 14:12:52 | 3,533 | Allocated (IMG_0003 range) | 1/80 s |
| 14:13:12 | 10,093 | Allocated | 1/100 s |
| 14:13:22 | 13,261 | Allocated | 1/100 s |
| 14:13:31 | 16,621 | Allocated | 1/100 s |
| 14:13:41 | 19,757 | Allocated | 1/100 s |
| **14:13:45** | **21,421** | **CARVED (ghost file — no dir entry)** | 1/100 s |
| 14:13:56 | 24,781 | Allocated | 1/100 s |
| 14:14:01 | 26,477 | Allocated | 1/100 s |
| 14:14:06 | 28,045 | Allocated | 1/100 s |
| 14:14:10 | 29,581 | Allocated | 1/100 s |
| 14:14:21 | 33,005 | Allocated | 1/100 s |
| 14:14:26 | 34,637 | Allocated | 1/100 s |
| 14:14:31 | 36,077 | Allocated | 1/100 s |
| 14:14:36 | 37,773 | Allocated | 1/100 s |
| *(14:14:40)* | *39,437* | *Deleted — IMG_0025 dir entry only* | *—* |
| 14:14:46 | 41,005 | Allocated (IMG_0026) | 1/100 s |
| 14:14:50 | 42,509 | Allocated | 1/100 s |
| 14:14:54 | 44,173 | Allocated | 1/100 s |
| 14:14:58 | 45,773 | Allocated | 1/100 s |
| *(14:15:02)* | *47,469* | *Deleted — IMG_0030 dir entry only* | *—* |
| 14:15:08 | 49,165 | Allocated | 1/100 s |
| 14:15:14 | 50,637 | Allocated | 1/100 s |
| 14:15:18 | 52,365 | Allocated | 1/100 s |
| 14:15:23 | 54,029 | Allocated | 1/100 s |
| *(14:15:28)* | *55,629* | *Deleted — IMG_0035 dir entry only* | *—* |
| 14:15:36 | 57,261 | Allocated | 1/100 s |

### Session B — 2008-12-23, 14:22–14:30 UTC (higher-resolution shots)

| Time (UTC) | FS Sector | Status | Resolution | Exposure |
|-----------|-----------|--------|------------|----------|
| 14:22:46 | 8,077 | Allocated | 2048×1536 | 1/80 s |
| **14:22:54** | **23,533** | **CARVED (ghost file — thumbnail only)** | 2048×1536 | 1/100 s |
| **14:23:01** | **32,845** | **CARVED (ghost file — thumbnail only)** | 2048×1536 | 1/80 s |
| *(14:26:13)* | *(48,685)* | *Embedded thumb from deleted IMG_0030* | 2048×1536 | 1/100 s |
| 14:28:08 | 237 | Allocated | 2048×1536 | 1/100 s |
| 14:30:39 | 2,989 | Allocated | 3072×2304 | 1/100 s |

### Session C — 2008-12-24, 20:21–20:22 UTC (640×480, low-light, evening)

| Time (UTC) | FS Sector | Status | Exposure |
|-----------|-----------|--------|----------|
| 20:21:45 | 173 | Allocated | 1/13 s |
| 20:21:57 | 12,461 | Allocated | 1/20 s |
| 20:22:10 | 12,685 | Allocated | 1/25 s |
| 20:22:16 | 12,941 | Allocated | 1/25 s |
| 20:22:22 | 13,197 | Allocated | 1/25 s |
| 20:22:28 | 18,349 | Allocated | 1/25 s |
| 20:22:36 | 18,605 | Allocated | 1/30 s |
| 20:22:42 | 18,861 | Allocated | 1/30 s |

> Session C (640×480, slow shutter, evening of 2008-12-24) is a distinct shooting session. The low resolution and long exposure times are consistent with indoor/low-light conditions, approximately 30 hours after Sessions A/B.

---

## 8. Missing Image Numbering Analysis

The card contained images numbered up to IMG_0051. Significant gaps exist where files were fully deleted (no directory entry, no recoverable data):

| Missing Images | Count |
|---------------|-------|
| IMG_0001, 0002, 0004, 0005, 0006, 0008, 0010, 0012, 0014, 0015 | 10 |
| IMG_0020 | 1 (ghost file at sector 21421 — RECOVERED) |
| IMG_0039, 0040, 0041 | 3 |
| **Total missing from directory** | **14** |

Of the 14 missing images:
- **1 fully recovered** from unallocated space (sector 21421 → likely IMG_0020, 14:13:45)
- **2 thumbnail-only** from unallocated space (sectors 23533, 32845)
- **11 completely unrecoverable** — no data or directory evidence remains

---

## 9. Bulk Extractor Findings

bulk_extractor scanned the full 29 MiB image. Results:
- **Email addresses:** 0
- **URLs / domains:** Minimal (no meaningful hits; no browsing history)
- **GPS coordinates:** None in any EXIF record
- **Credit card numbers:** None
- **JPEG carved files:** 113 JPEG segment markers identified (aligned with files above)
- **KML file:** Generated (`exports/carved/kml.txt`) — empty (no GPS data)
- **EXIF records:** 37 (documented above)

---

## 10. Key Findings Summary

1. **Device:** Canon PowerShot SD800 IS compact camera, FAT12 memory card (29 MiB, volume `CANON_DC`).

2. **Image integrity verified.** MD5 hash matches acquisition record.

3. **34 allocated JPEG files** remain on the card, captured across two days (2008-12-23 and 2008-12-24).

4. **3 deleted files have surviving directory entries** (IMG_0025, IMG_0030, IMG_0035) but all data blocks were overwritten by subsequent card usage. Only IMG_0030's embedded EXIF thumbnail (8,808 bytes) was recovered.

5. **1 additional deleted file was fully recovered** from unallocated space at sector 21421 (873,437 bytes, valid JPEG, captured 2008-12-23 14:13:45 UTC). This image has no directory entry — the directory entry was also deleted.

6. **2 more ghost-file thumbnails** recovered from unallocated sectors 23533 and 32845 (EXIF portions only, ~9 KB each; captured 14:22:54 and 14:23:01 UTC on 2008-12-23).

7. **No GPS metadata** in any image. No email, URL, or network artifacts.

8. **Deletion pattern:** Consecutive images in the shooting sequence were selectively deleted (IMG_0025, IMG_0030, IMG_0035 deleted from an otherwise intact run; earlier images 0001–0015 and 0039–0041 were deleted at some earlier point with directory entries also removed). The selective deletion of every 5th image in a sequence (0025, 0030, 0035) may be significant.

---

## 11. Output Artifacts

| Path | Description |
|------|-------------|
| `analysis/fls_output.txt` | Full recursive file listing (allocated + deleted) |
| `analysis/bodyfile.txt` | MAC time bodyfile for timeline analysis |
| `exports/fs_timeline.csv` | Filesystem MAC timeline (UTC) |
| `exports/files/` | Extracted and carved image files (see Section 6) |
| `exports/carved/` | bulk_extractor feature files |

---

*Report prepared in accordance with DFIR chain-of-custody requirements. Evidence files were not modified. All analysis performed on read-only mounted image.*
