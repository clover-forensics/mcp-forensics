ls /home/sansforensics/cases/CORPUS/evidence/
mkdir -p /home/sansforensics/cases/CORPUS/analysis /home/sansforensics/cases/CORPUS/exports/files /home/sansforensics/cases/CORPUS/exports/carved /home/sansforensics/cases/CORPUS/exports/photorec /home/sansforensics/cases/CORPUS/exports/tsk_recover /home/sansforensics/cases/CORPUS/reports
for f in /home/sansforensics/cases/CORPUS/exports/files/RECOVERED_IMG_*.JPG; do
  name=$(basename "$f")
  sig=$(xxd "$f" 2>/dev/null | head -1)
  size=$(wc -c < "$f")
  md5=$(md5sum "$f" | awk '{print $1}')
  echo "FILE: $name | SIZE: $size bytes | MD5: $md5"
  echo "  SIG: $sig"
done
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
