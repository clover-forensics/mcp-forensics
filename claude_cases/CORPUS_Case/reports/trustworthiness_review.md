# Trustworthiness Review
## Case: 14-822 — Host Based Forensics / File Carving Exercise
**Reviewer:** Claude Code DFIR Orchestrator  
**Date:** 2026-04-16 (UTC)  
**Scope:** Compare `./analysis`, `./exports`, `./reports` against `./ground_truth/corpus-report.txt`; evaluate command logs in `./logs_backup/` for relevance.

---

## 1. Ground Truth Comparison

### 1.1 Methodology Notes

`corpus-report.txt` is a cross-image reference covering three generations of the same Canon card image:
- **gen6** (`nps-2009-canon2-gen6.raw`) — the evidence image under analysis
- **gen1** (`nps-2009-canon2-gen1.raw`) — an earlier state; files listed here are *deleted* in gen6
- **gen2** (`nps-2009-canon2-gen2.raw`) — another version (different M0100.CTG)

Sector numbers in the ground truth are **partition-relative** (matching TSK's `-o 51` output). This was confirmed by cross-referencing file sizes and locations.

---

### 1.2 Allocated Files (gen6) — PASS ✅

All 34 allocated JPEG files and M0100.CTG present in gen6 are correctly identified in `analysis/fls_output.txt` and the report. All file sizes match the ground truth exactly.

| Check | Result |
|-------|--------|
| File count (34 JPEG + 1 CTG) | ✅ Match |
| All file sizes match ground truth | ✅ Match |
| M0100.CTG size (164 bytes, gen6 version) | ✅ Match |
| Partition offset (sector 51) | ✅ Correct |

---

### 1.3 Deleted Files With Directory Entries — PASS ✅

Ground truth (gen1) lists IMG_0025, IMG_0030, IMG_0035 at sectors matching the `_MG_*` entries found by fls (inodes 1053, 1058, 1063). Sizes match.

| File | GT Sector | GT Size | Analysis Finding |
|------|-----------|---------|-----------------|
| IMG_0025 (inode 1053) | 39437 | 791,333 B | ✅ Found, overwritten, correct size |
| IMG_0030 (inode 1058) | 47469 | 867,833 B | ✅ Found, thumbnail recovered, correct size |
| IMG_0035 (inode 1063) | 55629 | 820,105 B | ✅ Found, overwritten, correct size |

The data-overwrite assessments (no JPEG signature at sector start) are confirmed by the blkcat hex dump commands in the logs.

---

### 1.4 Ghost File (No Directory Entry) — CRITICAL ERROR ❌

**The analysis report misidentifies the carved ghost file at fs_sector 21421.**

Ground truth (gen1) definitively places **IMG_0014.JPG** at absolute sector 21472 — which is **fs_sector 21421** (21472 − 51 = 21421). Size: **873,437 bytes**.

The analysis report (`file_carving_report.md`, Sections 5 and 8) labels this carved file as **"likely IMG_0020"** and separately lists IMG_0014 as "missing." This is **factually incorrect** and internally contradictory.

| Item | Ground Truth | Analysis Report | Verdict |
|------|-------------|-----------------|---------|
| File at fs_sector 21421, 873,437 bytes | **IMG_0014** (gen1) | "likely IMG_0020" | ❌ WRONG |
| IMG_0014 status | Recoverable (sector 21421) | Listed as "missing" | ❌ WRONG |
| IMG_0020 location | fs_sector 31277 (gen1) | Not identified | ⚠️ Not carved |

**Correct finding:** `CARVED_unalloc_sec21421.JPG` (873,437 bytes) = **IMG_0014**, not IMG_0020.

The misidentification likely occurred because the analysis counted forward from the nearest allocated file number — but in a FAT12 card image with non-sequential allocation, inode/directory order does not predict image number gaps.

---

### 1.5 IMG_0020 — NOT FOUND IN GEN6 (Expected)

Ground truth shows IMG_0020 at fs_sector 31277 in gen1. In gen6, this region was reallocated/overwritten. The analysis did not find a valid JPEG signature there — this absence is **forensically correct** for gen6 and is not a failure of the analysis workflow.

---

### 1.6 Two Additional Thumbnail Carves (Sectors 23533 & 32845) — UNVERIFIABLE ⚠️

The carved files at sectors 23533 and 32845 (EXIF headers only, ~9 KB each) have **no corresponding entry in the ground truth**. The ground truth covers gen1 and gen2 states. These fragments likely originate from a pre-gen1 state (the card may have had additional images before gen1 was captured). Neither confirms nor contradicts the analysis; they represent best-effort carving beyond what ground truth covers.

---

### 1.7 Overall Ground Truth Match Summary

| Category | Count | Match |
|----------|-------|-------|
| Allocated gen6 files | 35 | ✅ All correct |
| Deleted files with dir entries | 3 | ✅ All correct |
| Ghost file identification | 1 | ❌ Misidentified (IMG_0014, not IMG_0020) |
| Section 8 "Missing" list | — | ❌ Lists IMG_0014 as missing (it was recovered) |
| Sectors 23533 & 32845 thumbnails | 2 | ⚠️ Not in ground truth — pre-gen1 artifacts |

---

## 2. Command Log Relevance Review

### 2.1 File Overview

| Log File | Description | Unique Commands |
|----------|-------------|-----------------|
| `Canon2-Gen6_commands.sh` | Full analysis session for gen6 image | Complete workflow |
| `all_commands.sh` | Near-identical duplicate of Canon2-Gen6 + directory setup | ~99% overlap |
| `unknownFile_commands.sh` | Subset of the post-carving verification steps | Subset of above |

**Note:** `all_commands.sh` contains essentially everything in `Canon2-Gen6_commands.sh` plus a `mkdir -p` preamble and the same commands run a second time. `unknownFile_commands.sh` duplicates the final third of both. All three logs record the same analysis session in overlapping form — no unique commands appear exclusively in one file.

---

### 2.2 Relevant Commands (Core File Carving Workflow)

The following commands are appropriate and directly relevant to the file carving exercise:

| Command | Purpose | Assessment |
|---------|---------|------------|
| `ewfinfo` / `ewfverify` | Evidence integrity | ✅ Required |
| `mmls` | Confirm partition offset before carving | ✅ Required |
| `fsstat -o 51` | Filesystem metadata (FAT12, cluster size) | ✅ Required |
| `fls -r -p -o 51` | Enumerate allocated + deleted file entries | ✅ Required |
| `istat -o 51` (inodes 1053, 1058, 1063) | Deleted inode details and cluster chains | ✅ Required |
| `icat -r -o 51` (deleted inodes) | Extract deleted file data for overwrite check | ✅ Required |
| `blkcat -o 51` (sectors 39437, 47469, 55629) | Verify overwrite by reading raw sectors | ✅ Required |
| `tsk_recover -e -o 51` | TSK automated recovery of all recoverable files | ✅ Useful |
| Python JPEG signature scan (sector-aligned) | Locate JPEG headers in unallocated space | ✅ Required |
| Python carving script (last-EOI version) | Extract carved JPEGs with correct end-boundary | ✅ Required |
| `bulk_extractor -j 4` | EXIF/GPS/metadata extraction across full image | ✅ Required |
| `mactime -b bodyfile.txt -z UTC -d` | Filesystem MAC timeline generation | ✅ Relevant |
| `icat -o 51` (inode 943621, M0100.CTG) | Extract Canon catalog file | ✅ Relevant |
| `md5sum` / file manifest loop | Evidence file hashing | ✅ Required |
| `fls -r -m /` (bodyfile generation) | MAC time bodyfile for timeline | ✅ Relevant |
| Python EXIF parser (from exif.txt) | Build chronological EXIF timeline | ✅ Relevant |
| `img_stat` | Confirm image geometry | ✅ Useful |

---

### 2.3 Irrelevant, Redundant, or Improvable Commands

#### ❌ Inefficient: `xxd /mnt/ewf_cg6/ewf1 | grep -m 5 "ffd8 ff"`
- Streams the entire 31 MB raw disk image through `xxd` (producing ~200 MB of hex text) then greps it.
- Very slow; risk of pipe buffer exhaustion on larger images.
- This was an exploratory step and was superseded by the Python sector-aligned scan.
- **Improvement:** Use only the Python signature scan (sector-aligned, faster, more precise).

#### ❌ Redundant: First JPEG carving script (first-EOI, byte-aligned skip)
- The first Python carving script (lines 125–167 in the log) uses `data.find(b'\xff\xd9')` — first EOI found — and overwrites the output files.
- The second script (lines 170–217) uses the *last* EOI, which is correct for standard JPEGs (embedded thumbnails have their own EOI markers inside the file).
- Both scripts write to the same output files; only the second result persists.
- **Improvement:** Remove or consolidate to only the last-EOI version.

#### ⚠️ Redundant: First Python JPEG signature scan (byte-by-byte `pos = idx + 1`)
- The first scan (lines 33–51) steps `pos = idx + 1` — it finds JPEG signatures *within* JPEG data (not just sector-boundary starts), generating false positives.
- The second scan (lines 84–105) correctly steps `pos = idx + 512`, scanning only at sector boundaries.
- **Improvement:** Remove the byte-by-byte scan; keep only the sector-aligned version.

#### ⚠️ Unused: `exports/photorec/` directory
- The directory was created in the `mkdir -p` setup line but `photorec` was never invoked.
- No photorec commands appear in any log file.
- The directory is empty. This is not harmful but reflects an unused tool path.
- **Improvement:** Either run `sudo photorec` as a cross-validation tool (recommended), or remove the directory from setup if not intended.

#### ⚠️ Redundant: `sudo mount ... /mnt/cg6` (the `mount` command)
- The read-only OS mount was used only for the initial `ls -la /mnt/cg6/` (directory listing).
- All carving, extraction, and analysis used TSK tools directly against the raw image with `-o 51` — no mounted filesystem was required.
- **Improvement:** Omit the OS-level mount for carving workflows. TSK is safer (no kernel FAT driver involved) and the mount command adds no carving capability.

#### ⚠️ Duplicate log files
- `all_commands.sh` duplicates `Canon2-Gen6_commands.sh` with a `mkdir -p` prefix.
- `unknownFile_commands.sh` is a subset of both.
- The naming "unknownFile" is unexplained — no unknown/unidentified file evidence is described in the case.
- **Improvement:** Maintain one canonical log per evidence file and image, with a clear naming scheme tied to the evidence identifier.

#### ⚠️ Redundant: `ls /mnt/ewf_cg6/` run twice (with and without `sudo`)
- Minor, but the initial `ls` (non-sudo) was run before ewfmount was confirmed active. The sudo version immediately follows.
- **Improvement:** Single `sudo ls` after mount confirmation.

---

### 2.4 Missing Commands (Gaps in the Workflow)

| Missing Step | Impact |
|--------------|--------|
| **`exiftool` on carved files** | Would directly confirm capture timestamps, GPS, camera serial number, and validate JPEG structure — currently done indirectly via bulk_extractor EXIF XML |
| **`photorec` cross-validation** | photorec would independently carve JPEGs and provide a second opinion on recovered files; the tool was staged but never run |
| **SHA-1 hashing of recovered files** | Ground truth uses SHA-1; the analysis used only MD5. SHA-1 would allow direct hash comparison against `corpus-report.txt` |
| **`blkls` (unallocated space dump)** | Explicitly extracting and scanning only unallocated sectors would be more rigorous than scanning the full image; reduces noise |
| **Verify carved JPEG validity** | No `file` command or ImageMagick `identify` run on carved files to confirm they are valid, viewable JPEGs |

---

## 3. Conclusion

### Ground Truth Match: MOSTLY CORRECT WITH ONE FACTUAL ERROR

The analysis correctly identifies all 34 allocated files, the CTG catalog, and the three deleted files with surviving directory entries. File sizes are exact. The carving workflow successfully recovered the ghost file from sector 21421. However:

> **The carved file `CARVED_unalloc_sec21421.JPG` is labeled "likely IMG_0020" in the report — this is incorrect. Per ground truth, this file is IMG_0014 (same sector, exact size match: 873,437 bytes). Section 8 also incorrectly lists IMG_0014 as "missing." Both errors should be corrected in the report.**

### Command Log Assessment: RELEVANT BUT WITH CLEANUP NEEDED

Core carving commands (TSK suite, bulk_extractor, Python JPEG scanning/carving) are all appropriate and correctly applied. Issues to address:

1. **Remove** the `xxd | grep` command — replaced by superior Python approach
2. **Consolidate** to one carving script (last-EOI version only)
3. **Consolidate** to one Python signature scan (sector-aligned version only)
4. **Run `photorec`** for cross-validation or remove the empty directory
5. **Add SHA-1 hashing** of carved files to enable direct ground truth comparison
6. **Add `exiftool`** for direct JPEG metadata validation on carved outputs
7. **Consolidate log files** — one log per evidence image, clearly named

---

*All analysis performed on read-only mounted evidence. No evidence files were modified.*
