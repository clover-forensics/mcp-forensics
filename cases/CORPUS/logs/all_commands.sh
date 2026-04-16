ls /home/sansforensics/cases/CORPUS/evidence/
mkdir -p /home/sansforensics/cases/CORPUS/analysis /home/sansforensics/cases/CORPUS/exports/files /home/sansforensics/cases/CORPUS/exports/carved /home/sansforensics/cases/CORPUS/exports/photorec /home/sansforensics/cases/CORPUS/exports/tsk_recover /home/sansforensics/cases/CORPUS/reports
ewfinfo /home/sansforensics/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01 2>&1
ewfverify /home/sansforensics/cases/CORPUS/evidence/nps-2009-canon2-gen6.E01 2>&1
ls /mnt/ewf_cg6/ 2>&1; sudo ls /mnt/ewf_cg6/ 2>&1
sudo img_stat /mnt/ewf_cg6/ewf1 2>&1
sudo mmls /mnt/ewf_cg6/ewf1 2>&1
sudo mount -o ro,loop,noatime,offset=$((51*512)) /mnt/ewf_cg6/ewf1 /mnt/cg6 2>&1 && echo "Mount OK" && sudo ls -la /mnt/cg6/
sudo fsstat -o 51 /mnt/ewf_cg6/ewf1 2>&1
sudo fls -r -p -o 51 /mnt/ewf_cg6/ewf1 2>&1 | tee /home/sansforensics/cases/CORPUS/analysis/fls_output.txt
sudo fls -r -p -o 51 /mnt/ewf_cg6/ewf1 | grep "^\*" 2>&1
sudo istat -o 51 /mnt/ewf_cg6/ewf1 1053 2>&1
sudo istat -o 51 /mnt/ewf_cg6/ewf1 1058 2>&1
sudo istat -o 51 /mnt/ewf_cg6/ewf1 1063 2>&1
sudo icat -r -o 51 /mnt/ewf_cg6/ewf1 1053 > /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0025.JPG 2>&1 && echo "1053 OK: $(wc -c < /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0025.JPG) bytes"
sudo icat -r -o 51 /mnt/ewf_cg6/ewf1 1058 > /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0030.JPG 2>&1 && echo "1058 OK: $(wc -c < /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0030.JPG) bytes"
sudo icat -r -o 51 /mnt/ewf_cg6/ewf1 1063 > /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0035.JPG 2>&1 && echo "1063 OK: $(wc -c < /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0035.JPG) bytes"
sudo tsk_recover -e -o 51 /mnt/ewf_cg6/ewf1 /home/sansforensics/cases/CORPUS/exports/tsk_recover/ 2>&1 | tail -5
for f in /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_*.JPG; do
  name=$(basename "$f")
  sig=$(xxd "$f" 2>/dev/null | head -1)
  size=$(wc -c < "$f")
  md5=$(md5sum "$f" | awk '{print $1}')
  echo "FILE: $name | SIZE: $size bytes | MD5: $md5"
  echo "  SIG: $sig"
done
sudo fls -r -m / -o 51 /mnt/ewf_cg6/ewf1 2>&1 | tee /home/sansforensics/cases/CORPUS/analysis/bodyfile.txt | wc -l
# Check raw sector 39437 (first sector of _MG_0025) using blkcat with partition offset
# blkcat reads data unit (sector) by number within the filesystem
sudo blkcat -o 51 /mnt/ewf_cg6/ewf1 39437 1 2>/dev/null | xxd | head -4
sudo blkcat -o 51 /mnt/ewf_cg6/ewf1 47469 1 2>/dev/null | xxd | head -4
sudo blkcat -o 51 /mnt/ewf_cg6/ewf1 55629 1 2>/dev/null | xxd | head -4
sudo istat -o 51 /mnt/ewf_cg6/ewf1 1054 2>&1 | head -20
# Search for JPEG signatures (FF D8 FF) in the raw partition
# Partition starts at sector 51, partition size = 60749 sectors
# Search within first 5MB for the signature
sudo xxd /mnt/ewf_cg6/ewf1 | grep -m 5 "ffd8 ff" 2>&1 | head -10
# Extract allocated IMG_0026 and check magic bytes
sudo icat -o 51 /mnt/ewf_cg6/ewf1 1054 2>/dev/null | xxd | head -2
# Find JPEG signatures and their sector locations in the partition
# Partition starts at byte offset 51*512=26112
# Search full partition
sudo python3 -c "
import sys
data = open('/mnt/ewf_cg6/ewf1','rb').read()
sig = b'\xff\xd8\xff'
offset = 26112  # partition start
found = []
pos = offset
while True:
    idx = data.find(sig, pos)
    if idx == -1 or idx > 26112 + 60749*512:
        break
    sector_abs = idx // 512
    sector_fs = sector_abs - 51
    found.append((idx, sector_abs, sector_fs))
    pos = idx + 1
print(f'Total JPEG sigs found: {len(found)}')
for f in found[:10]:
    print(f'  byte_offset=0x{f[0]:08x} ({f[0]}) | abs_sector={f[1]} | fs_sector={f[2]}')
" 2>&1
# Verify sector mapping - does IMG_0026 JPEG data sit at abs_sector 41005+51=41056 or 41005?
sudo python3 -c "
import struct
f = open('/mnt/ewf_cg6/ewf1','rb')
# Check at absolute sector 41005
f.seek(41005*512)
d1 = f.read(4)
# Check at absolute sector 41005+51=41056
f.seek(41056*512)
d2 = f.read(4)
print(f'Absolute sector 41005: {d1.hex()} ({d1})')
print(f'Absolute sector 41056: {d2.hex()} ({d2})')
f.close()
" 2>&1
# The istat sectors are partition-relative. Add 51 for absolute sector.
# Check absolute sector for _MG_0025 starting sector: 39437 + 51 = 39488
sudo python3 -c "
f = open('/mnt/ewf_cg6/ewf1','rb')
# _MG_0025: partition sector 39437 → abs sector 39488
f.seek(39488*512)
d = f.read(8)
print(f'_MG_0025 abs sector 39488: {d.hex()} | {d}')
# _MG_0030: partition sector 47469 → abs sector 47520
f.seek(47520*512)
d = f.read(8)
print(f'_MG_0030 abs sector 47520: {d.hex()} | {d}')
# _MG_0035: partition sector 55629 → abs sector 55680
f.seek(55680*512)
d = f.read(8)
print(f'_MG_0035 abs sector 55680: {d.hex()} | {d}')
f.close()
" 2>&1
sudo python3 -c "
import sys
data = open('/mnt/ewf_cg6/ewf1','rb').read()
sig = b'\xff\xd8\xff'
part_start = 51 * 512
part_end = part_start + 60749 * 512
found = []
pos = part_start
while True:
    idx = data.find(sig, pos)
    if idx == -1 or idx > part_end:
        break
    abs_sector = idx // 512
    fs_sector = abs_sector - 51
    cluster_approx = (fs_sector - 45) // 32 + 2 if fs_sector >= 45 else 0
    found.append((idx, abs_sector, fs_sector, cluster_approx))
    pos = idx + 512  # skip to next potential sector boundary
# Show all
print(f'Total full-sector JPEG starts: {len(found)}')
for f in found:
    print(f'  fs_sector={f[2]:6d} cluster~{f[3]:5d}  | byte=0x{f[0]:08x}')
" 2>&1
# Check if recovered _MG_0030 has JPEG signature embedded (not at byte 0)
sudo python3 -c "
data = open('/home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0030.JPG','rb').read()
sig = b'\xff\xd8\xff'
pos = 0
found = []
while True:
    idx = data.find(sig, pos)
    if idx == -1: break
    found.append(idx)
    pos = idx + 1
print(f'JPEG sigs in RECOVERED_IMG_0030.JPG: {len(found)}')
for o in found[:5]:
    print(f'  offset 0x{o:08x} ({o:10d}): {data[o:o+16].hex()}')
" 2>&1
# Also check for EXIF/TIFF signatures in recovered files (CR2 starts with 49 49 2A 00)
for f in /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_*.JPG; do
  name=$(basename "$f")
  python3 -c "
import sys
data = open('$f','rb').read()[:16]
print(f'$name: {data.hex()} | {repr(data[:8])}')
" 2>&1
done
# Extract the embedded EXIF thumbnail from _MG_0030 (starts at offset 622592)
sudo python3 -c "
data = open('/home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_0030.JPG','rb').read()
# JPEG at offset 622592 - extract from FF D8 FF to FF D9 (EOI)
start = 622592
# Find JPEG EOI (FF D9)
end = data.find(b'\xff\xd9', start)
if end != -1:
    end += 2  # include the marker
    thumb = data[start:end]
    print(f'EXIF thumbnail: {len(thumb)} bytes, sig: {thumb[:8].hex()}')
    open('/home/sansforensics/cases/CORPUS/exports/files/IMG_0030_exif_thumb.JPG','wb').write(thumb)
else:
    print('No EOI found, extracting 200KB chunk')
    thumb = data[622592:622592+204800]
    open('/home/sansforensics/cases/CORPUS/exports/files/IMG_0030_exif_thumb.JPG','wb').write(thumb)
" 2>&1
# Check sectors with intact JPEG data in unallocated space (possible extra deleted files)
# Gap at sectors 21421-23148 (JPEG sig at 21421)
sudo python3 -c "
f = open('/mnt/ewf_cg6/ewf1','rb')
# Check abs sector 21421+51=21472
f.seek(21472*512)
d = f.read(16)
print(f'Gap sec 21421 (abs 21472): {d.hex()} | {repr(d[:8])}')
# Check sector 23533+51=23584
f.seek(23584*512)
d = f.read(16)
print(f'Gap sec 23533 (abs 23584): {d.hex()} | {repr(d[:8])}')
# Check sector 32845+51=32896
f.seek(32896*512)
d = f.read(16)
print(f'Gap sec 32845 (abs 32896): {d.hex()} | {repr(d[:8])}')
f.close()
" 2>&1
# Carve the 3 extra intact JPEGs from unallocated gaps
sudo python3 -c "
import struct

image_path = '/mnt/ewf_cg6/ewf1'
PART_OFFSET = 51  # sectors
SECTOR_SIZE = 512
CLUSTER_SIZE = 32  # sectors per cluster

f = open(image_path, 'rb')

def carve_jpeg(start_fs_sector, max_sectors, label):
    abs_byte = (start_fs_sector + PART_OFFSET) * SECTOR_SIZE
    f.seek(abs_byte)
    # Read up to max_sectors of data
    data = f.read(max_sectors * SECTOR_SIZE)
    # Find JPEG EOI (FF D9)
    eoi = data.find(b'\xff\xd9')
    if eoi != -1:
        carved = data[:eoi+2]
        print(f'{label}: carved {len(carved)} bytes (EOI at offset {eoi})')
    else:
        carved = data
        print(f'{label}: no EOI found, using {len(carved)} bytes (truncated)')
    return carved

# Gap 1: sectors 21421-23148 (1728 sectors)
d1 = carve_jpeg(21421, 1728, 'extra_jpeg_21421')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec21421.JPG','wb') as out:
    out.write(d1)

# Gap 2: sectors 23533-24780 (1248 sectors)
d2 = carve_jpeg(23533, 1248, 'extra_jpeg_23533')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec23533.JPG','wb') as out:
    out.write(d2)

# Gap 3: sector 32845 - goes until 33004 (160 sectors before allocated)
d3 = carve_jpeg(32845, 160, 'extra_jpeg_32845')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec32845.JPG','wb') as out:
    out.write(d3)

f.close()
print('Done carving.')
" 2>&1
# Run bulk_extractor for metadata, EXIF extraction, and any hidden content
sudo bulk_extractor -o /home/sansforensics/cases/CORPUS/exports/carved/ -j 4 /mnt/ewf_cg6/ewf1 2>&1 | tail -20
sudo python3 -c "
import struct

image_path = '/mnt/ewf_cg6/ewf1'
PART_OFFSET = 51
SECTOR_SIZE = 512

f = open(image_path, 'rb')

def carve_jpeg_full(start_fs_sector, max_sectors, label):
    abs_byte = (start_fs_sector + PART_OFFSET) * SECTOR_SIZE
    f.seek(abs_byte)
    data = f.read(max_sectors * SECTOR_SIZE)
    # Find LAST FF D9 (EOI) - that is the end of the full JPEG
    sig = b'\xff\xd8\xff'
    # Find last occurrence of FF D9
    pos = 0
    last_eoi = -1
    while True:
        idx = data.find(b'\xff\xd9', pos)
        if idx == -1: break
        last_eoi = idx
        pos = idx + 1
    if last_eoi != -1:
        carved = data[:last_eoi+2]
        print(f'{label}: carved {len(carved)} bytes (last EOI at offset {last_eoi})')
    else:
        carved = data
        print(f'{label}: no EOI found, using full {len(carved)} bytes')
    return carved

# Gap 1: sectors 21421-23148 = 1728 sectors = 884736 bytes
d1 = carve_jpeg_full(21421, 1728, 'extra_sec21421')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec21421.JPG','wb') as out:
    out.write(d1)

# Gap 2: sectors 23533-24780 = 1248 sectors = 638976 bytes
d2 = carve_jpeg_full(23533, 1248, 'extra_sec23533')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec23533.JPG','wb') as out:
    out.write(d2)

# Gap 3: sector 32845-33004 = 160 sectors = 81920 bytes
d3 = carve_jpeg_full(32845, 160, 'extra_sec32845')
with open('/home/sansforensics/cases/CORPUS/exports/files/CARVED_unalloc_sec32845.JPG','wb') as out:
    out.write(d3)

f.close()
" 2>&1
# Hash and verify all carved/recovered files
cd /home/sansforensics/cases/CORPUS/exports/files/
for f in *.JPG *.jpg; do
  [ -f "$f" ] || continue
  size=$(wc -c < "$f")
  md5=$(md5sum "$f" | awk '{print $1}')
  sig=$(python3 -c "d=open('$f','rb').read(4); print(d.hex())")
  echo "$f | ${size} bytes | $sig | md5:$md5"
done
ls /home/sansforensics/cases/CORPUS/exports/carved/
# Check bulk_extractor key outputs: GPS, EXIF, JPEG carves
echo "=== GPS ===" && cat /home/sansforensics/cases/CORPUS/exports/carved/gps.txt
echo "=== EXIF (first 50 lines) ===" && head -50 /home/sansforensics/cases/CORPUS/exports/carved/exif.txt
echo "=== JPEG carved files found ===" && wc -l /home/sansforensics/cases/CORPUS/exports/carved/jpeg_carved.txt && head -10 /home/sansforensics/cases/CORPUS/exports/carved/jpeg_carved.txt
# Extract EXIF DateTimeOriginal and GPS from bulk_extractor exif output
python3 -c "
import re
with open('/home/sansforensics/cases/CORPUS/exports/carved/exif.txt') as f:
    for line in f:
        if line.startswith('#'): continue
        parts = line.strip().split('\t')
        if len(parts) < 3: continue
        offset, md5, xml = parts[0], parts[1], parts[2]
        # Extract date and model
        dt = re.search(r'<ifd0\.tiff\.DateTime>([^<]+)<', xml)
        model = re.search(r'<ifd0\.tiff\.Model>([^<]+)<', xml)
        gps_lat = re.search(r'<gps\.GPSLatitude>([^<]+)<', xml)
        gps_lon = re.search(r'<gps\.GPSLongitude>([^<]+)<', xml)
        if dt or model:
            print(f'Offset {offset}: {model.group(1) if model else \"?\"} | {dt.group(1) if dt else \"?\"} | GPS lat={gps_lat.group(1) if gps_lat else \"none\"} lon={gps_lon.group(1) if gps_lon else \"none\"}')
" 2>&1 | head -50
# Generate timeline from bodyfile
mactime -b /home/sansforensics/cases/CORPUS/analysis/bodyfile.txt -z UTC -d 2>&1 | tee /home/sansforensics/cases/CORPUS/exports/fs_timeline.csv | head -60
# Extract CTG catalog file (may list deleted image metadata)
sudo icat -o 51 /mnt/ewf_cg6/ewf1 943621 > /home/sansforensics/cases/CORPUS/exports/files/M0100.CTG 2>&1
xxd /home/sansforensics/cases/CORPUS/exports/files/M0100.CTG | head -20
# Parse all EXIF to build complete image timeline
python3 -c "
import re, sys

entries = []
with open('/home/sansforensics/cases/CORPUS/exports/carved/exif.txt') as f:
    for line in f:
        if line.startswith('#'): continue
        parts = line.strip().split('\t')
        if len(parts) < 3: continue
        offset = int(parts[0])
        xml = parts[2]
        dt = re.search(r'<ifd0\.tiff\.DateTime>([^<]+)<', xml)
        model = re.search(r'<ifd0\.tiff\.Model>([^<]+)<', xml)
        flash = re.search(r'<ifd0\.exif\.Flash>([^<]+)<', xml)
        flen = re.search(r'<ifd0\.exif\.FocalLength>([^<]+)<', xml)
        exp = re.search(r'<ifd0\.exif\.ExposureTime>([^<]+)<', xml)
        fnum = re.search(r'<ifd0\.tiff\.FNumber>([^<]+)<|<ifd0\.exif\.FNumber>([^<]+)<', xml)
        iso = re.search(r'ISOSpeedRatings>([^<]+)<', xml)
        w = re.search(r'PixelXDimension>([^<]+)<', xml)
        h = re.search(r'PixelYDimension>([^<]+)<', xml)
        
        if dt:
            entries.append({
                'offset': offset,
                'sector': offset//512 - 51,  # fs sector
                'datetime': dt.group(1) if dt else '?',
                'model': model.group(1) if model else '?',
                'focal': flen.group(1) if flen else '?',
                'exp': exp.group(1) if exp else '?',
                'dims': f\"{w.group(1) if w else '?'}x{h.group(1) if h else '?'}\"
            })

# Sort by datetime
entries.sort(key=lambda x: x['datetime'])
print(f'Total EXIF records: {len(entries)}')
print()
print(f'{\"DateTime\":<22} {\"FS Sector\":>10} {\"Offset\":>12} {\"Focal\":>12} {\"Exp\":>8} {\"Dims\"}')
print('-'*90)
for e in entries:
    print(f'{e[\"datetime\"]:<22} {e[\"sector\"]:>10} {e[\"offset\"]:>12} {e[\"focal\"]:>12} {e[\"exp\"]:>8} {e[\"dims\"]}')
" 2>&1
# Summarize all exported/carved files for the manifest
find /home/sansforensics/cases/CORPUS/exports/files/ -type f | sort | while read f; do
  md5=$(md5sum "$f" | awk '{print $1}')
  size=$(wc -c < "$f")
  echo "$md5  $(printf '%9d' $size)  $(basename $f)"
done
# Build list of all allocated files with sizes and EXIF dates where possible
python3 -c "
import re

# Map fs_sector -> datetime from EXIF
exif_map = {}
with open('/home/sansforensics/cases/CORPUS/exports/carved/exif.txt') as f:
    for line in f:
        if line.startswith('#'): continue
        parts = line.strip().split('\t')
        if len(parts) < 3: continue
        offset = int(parts[0])
        xml = parts[2]
        dt = re.search(r'DateTimeOriginal>([^<]+)<', xml)
        if dt:
            # Map to fs_sector (approximate - EXIF is within first cluster of file)
            fs_sector = offset // 512 - 51
            exif_map[fs_sector] = dt.group(1)

# Print sector->datetime for correlation
for sec in sorted(exif_map.keys()):
    print(f'  fs_sector {sec:6d} = {exif_map[sec]}')
" 2>&1 | head -40
# Unmount cleanly
sudo umount /mnt/cg6 2>&1 && sudo umount /mnt/ewf_cg6 2>&1 && echo "Unmounted cleanly"
# Verify report and exports exist
echo "=== Reports ===" && ls -la /home/sansforensics/cases/CORPUS/reports/
echo "=== Exports ===" && ls -la /home/sansforensics/cases/CORPUS/exports/files/
echo "=== Analysis ===" && ls -la /home/sansforensics/cases/CORPUS/analysis/
