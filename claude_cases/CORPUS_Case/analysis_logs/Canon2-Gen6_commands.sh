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
# Extract CTG catalog file (may list deleted image metadata)
sudo icat -o 51 /mnt/ewf_cg6/ewf1 943621 > /home/sansforensics/cases/CORPUS/exports/files/M0100.CTG 2>&1
xxd /home/sansforensics/cases/CORPUS/exports/files/M0100.CTG | head -20
# Unmount cleanly
sudo umount /mnt/cg6 2>&1 && sudo umount /mnt/ewf_cg6 2>&1 && echo "Unmounted cleanly"
# Verify report and exports exist
echo "=== Reports ===" && ls -la /home/sansforensics/cases/CORPUS/reports/
echo "=== Exports ===" && ls -la /home/sansforensics/cases/CORPUS/exports/files/
echo "=== Analysis ===" && ls -la /home/sansforensics/cases/CORPUS/analysis/
