ewfinfo evidence/HD1.E01 2>&1
sudo mkdir -p /mnt/ewf_hd1 /mnt/hd1
sudo ewfmount evidence/HD1.E01 /mnt/ewf_hd1 2>&1 && echo "EWF mounted" || echo "Mount failed"
sudo mmls /mnt/ewf_hd1/ewf1 2>&1
OFFSET=$(( 1001472 * 512 ))
sudo mount -o ro,loop,noatime,norecovery,offset=${OFFSET} /mnt/ewf_hd1/ewf1 /mnt/hd1 2>&1 && echo "Mounted at /mnt/hd1" || echo "Mount failed"
ls /mnt/hd1/ 2>&1
ls /mnt/hd1/Users/ 2>&1
# System info from registry
sudo cat /mnt/hd1/Windows/System32/config/SYSTEM 2>/dev/null | strings | grep -i "ComputerName" | head -5 2>/dev/null
# Check computer name via hive path listing
sudo ls /mnt/hd1/Windows/System32/config/ 2>&1
# Copy system registry hives
sudo cp /mnt/hd1/Windows/System32/config/SYSTEM exports/hd1/registry/
sudo cp /mnt/hd1/Windows/System32/config/SOFTWARE exports/hd1/registry/
sudo cp /mnt/hd1/Windows/System32/config/SAM exports/hd1/registry/
sudo cp /mnt/hd1/Windows/System32/config/SECURITY exports/hd1/registry/
echo "System hives copied"
# Copy user NTUSER.DAT and UsrClass.dat hives for both accounts
sudo cp "/mnt/hd1/Users/Sarah McAvoy/NTUSER.DAT" exports/hd1/registry/SarahMcAvoy_NTUSER.DAT 2>/dev/null && echo "McAvoy NTUSER copied"
sudo cp "/mnt/hd1/Users/Sarah M/NTUSER.DAT" exports/hd1/registry/SarahM_NTUSER.DAT 2>/dev/null && echo "SarahM NTUSER copied"
sudo find "/mnt/hd1/Users/Sarah McAvoy/AppData/Local/Microsoft/Windows/" -name "UsrClass.dat" 2>/dev/null -exec sudo cp {} exports/hd1/registry/SarahMcAvoy_UsrClass.dat \; && echo "McAvoy UsrClass copied"
sudo find "/mnt/hd1/Users/Sarah M/AppData/Local/Microsoft/Windows/" -name "UsrClass.dat" 2>/dev/null -exec sudo cp {} exports/hd1/registry/SarahM_UsrClass.dat \; && echo "SarahM UsrClass copied"
# Copy event logs
sudo cp -r /mnt/hd1/Windows/System32/winevt/Logs/ exports/hd1/evtx/ 2>/dev/null && echo "Event logs copied: $(ls exports/hd1/evtx/Logs/ 2>/dev/null | wc -l) files"
# Copy Prefetch files
sudo mkdir -p exports/hd1/prefetch
sudo cp /mnt/hd1/Windows/Prefetch/*.pf exports/hd1/prefetch/ 2>/dev/null && echo "Prefetch: $(ls exports/hd1/prefetch/*.pf 2>/dev/null | wc -l) files"
# Copy Amcache
sudo cp /mnt/hd1/Windows/AppCompat/Programs/Amcache.hve exports/hd1/registry/ 2>/dev/null && echo "Amcache copied"
# Copy SRUM
sudo cp /mnt/hd1/Windows/System32/sru/SRUDB.dat exports/hd1/srum/ 2>/dev/null && echo "SRUM copied"
# MFT extraction
sudo icat -o 1001472 /mnt/ewf_hd1/ewf1 0 > exports/hd1/mft/\$MFT 2>/dev/null && echo "MFT: $(ls -lh exports/hd1/mft/\$MFT | awk '{print $5}')"
# Copy Recycle Bin $I files
sudo find /mnt/hd1/\$RECYCLE.BIN/ -name "\$I*" 2>/dev/null -exec sudo cp {} exports/hd1/recyclebin/ \; && echo "Recycle Bin: $(ls exports/hd1/recyclebin/ | wc -l) $I files"
# Copy browser artifacts - Chrome and Firefox for both users
for user in "Sarah McAvoy" "Sarah M"; do
  safe=$(echo "$user" | tr ' ' '_')
  sudo mkdir -p "exports/hd1/browser/${safe}"
  # Chrome
  chrome_path="/mnt/hd1/Users/${user}/AppData/Local/Google/Chrome/User Data/Default"
  sudo find "$chrome_path" -maxdepth 1 -name "History" -o -name "Web Data" -o -name "Login Data" -o -name "Cookies" -o -name "Bookmarks" 2>/dev/null | \
    xargs -I{} sudo cp {} "exports/hd1/browser/${safe}/" 2>/dev/null
  # Firefox
  sudo find "/mnt/hd1/Users/${user}/AppData/Roaming/Mozilla/Firefox/Profiles/" -name "places.sqlite" -o -name "formhistory.sqlite" 2>/dev/null | \
    xargs -I{} sudo cp {} "exports/hd1/browser/${safe}/" 2>/dev/null
  echo "$user: $(ls exports/hd1/browser/${safe}/ 2>/dev/null | wc -l) browser files"
done
# Copy LNK recent files and Jump Lists
for user in "Sarah McAvoy" "Sarah M"; do
  safe=$(echo "$user" | tr ' ' '_')
  sudo mkdir -p "exports/hd1/lnk/${safe}" "exports/hd1/jumplists/${safe}"
  sudo find "/mnt/hd1/Users/${user}/AppData/Roaming/Microsoft/Windows/Recent/" -name "*.lnk" 2>/dev/null | \
    xargs -I{} sudo cp {} "exports/hd1/lnk/${safe}/" 2>/dev/null
  sudo find "/mnt/hd1/Users/${user}/AppData/Roaming/Microsoft/Windows/Recent/AutomaticDestinations/" -name "*.automaticDestinations-ms" 2>/dev/null | \
    xargs -I{} sudo cp {} "exports/hd1/jumplists/${safe}/" 2>/dev/null
  echo "$user: $(ls exports/hd1/lnk/${safe}/ 2>/dev/null | wc -l) LNK, $(ls exports/hd1/jumplists/${safe}/ 2>/dev/null | wc -l) jumplists"
done
# Look for Pidgin - the app referenced in the Android delivery SMS
sudo find /mnt/hd1/ -path "*/purple/logs" -type d 2>/dev/null
sudo find /mnt/hd1/ -name ".purple" -type d 2>/dev/null
sudo find /mnt/hd1/ -iname "pidgin*" -type f 2>/dev/null | head -10
# Also check AppData for both users
for user in "Sarah McAvoy" "Sarah M"; do
  echo "=== $user AppData/Roaming ==="
  sudo ls "/mnt/hd1/Users/${user}/AppData/Roaming/" 2>/dev/null | head -30
done
# Windows Timeline
for user in "Sarah McAvoy" "Sarah M"; do
  safe=$(echo "$user" | tr ' ' '_')
  sudo find "/mnt/hd1/Users/${user}/AppData/Local/ConnectedDevicesPlatform/" -name "ActivitiesCache.db" 2>/dev/null | \
    xargs -I{} sudo cp {} "exports/hd1/WindowsTimeline/${safe}_ActivitiesCache.db" 2>/dev/null && echo "$user: Timeline DB copied"
done
# Extract ALL Pidgin data - this is critical evidence
sudo mkdir -p exports/hd1/pidgin
sudo cp -r "/mnt/hd1/Users/Sarah M/AppData/Roaming/.purple/" exports/hd1/pidgin/ 2>/dev/null && \
  echo "Pidgin .purple copied" && find exports/hd1/pidgin/.purple/ -type f | head -40
# Sarah M user directory overview
echo "=== Sarah M Desktop ==="
sudo ls "/mnt/hd1/Users/Sarah M/Desktop/" 2>/dev/null
echo "=== Sarah M Documents ==="
sudo ls "/mnt/hd1/Users/Sarah M/Documents/" 2>/dev/null
echo "=== Sarah M Downloads ==="
sudo ls "/mnt/hd1/Users/Sarah M/Downloads/" 2>/dev/null
# Sarah McAvoy user directory overview
echo "=== Sarah McAvoy Desktop ==="
sudo ls "/mnt/hd1/Users/Sarah McAvoy/Desktop/" 2>/dev/null
echo "=== Sarah McAvoy Documents ==="
sudo ls "/mnt/hd1/Users/Sarah McAvoy/Documents/" 2>/dev/null
echo "=== Sarah McAvoy Downloads ==="
sudo ls "/mnt/hd1/Users/Sarah McAvoy/Downloads/" 2>/dev/null
# Check if Pidgin has logs - look more carefully
sudo ls "/mnt/hd1/Users/Sarah M/AppData/Roaming/.purple/" 2>/dev/null
echo "---"
sudo find "/mnt/hd1/Users/Sarah M/AppData/Roaming/.purple/" -type f 2>/dev/null | sort
# Read Pidgin account config - critical for account identification
sudo cat "/mnt/hd1/Users/Sarah M/AppData/Roaming/.purple/accounts.xml" 2>/dev/null
# Read Pidgin buddy list - shows contacts
sudo cat "/mnt/hd1/Users/Sarah M/AppData/Roaming/.purple/blist.xml" 2>/dev/null
sudo cat "/mnt/hd1/Users/Sarah M/Desktop/WOLf Awsome.html" 2>/dev/null | python3 -c "import sys,html; [print(html.unescape(l.rstrip())) for l in sys.stdin]" | grep -v "^\s*$" | head -80
sudo cat "/mnt/hd1/Users/Sarah M/Desktop/what is this.html" 2>/dev/null | python3 -c "import sys,html; [print(html.unescape(l.rstrip())) for l in sys.stdin]" | grep -v "^\s*$" | head -60
# Yahoo Messenger data
sudo ls "/mnt/hd1/Users/Sarah M/AppData/Roaming/Yahoo Messenger/" 2>/dev/null
sudo find "/mnt/hd1/Users/Sarah M/AppData/Roaming/Yahoo Messenger/" -type f 2>/dev/null | head -20
# Check Yahoo Messenger Cookies (may contain message data)
sudo cp "/mnt/hd1/Users/Sarah M/AppData/Roaming/Yahoo Messenger/Cookies" exports/hd1/files/yahoo_cookies.db 2>/dev/null
sudo chmod 644 exports/hd1/files/yahoo_cookies.db 2>/dev/null
sqlite3 exports/hd1/files/yahoo_cookies.db ".tables" 2>&1
echo "---"
# Check YM Local Storage
sudo find "/mnt/hd1/Users/Sarah M/AppData/Roaming/Yahoo Messenger/Local Storage/" -type f 2>/dev/null | head -10
# New Pet Care and pets desktop folder
echo "=== New Pet Care folder ==="
sudo ls "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/" 2>/dev/null
echo "=== Desktop pets folder ==="
sudo ls "/mnt/hd1/Users/Sarah M/Desktop/pets/" 2>/dev/null
echo "=== Sarah M Pictures ==="
sudo find "/mnt/hd1/Users/Sarah M/Pictures/" -type f 2>/dev/null | head -20
# Skype data for Sarah M
sudo find "/mnt/hd1/Users/Sarah M/AppData/Roaming/Skype/" -name "main.db" 2>/dev/null
sudo find "/mnt/hd1/Users/Sarah M/AppData/Local/Microsoft/Skype/" -name "main.db" 2>/dev/null
sudo ls "/mnt/hd1/Users/Sarah M/AppData/Roaming/Skype/" 2>/dev/null
# Copy all owl evidence files
sudo mkdir -p exports/hd1/owl_evidence
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/pets/Snowy Owl.jpg" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/pets/Snowy Owl 2.jpg" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/pets/Snowy Owl 3.jpg" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/pets/Snowy Owl 4.jpg" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/My New Pet.jpg" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/Snowy Owl Care.pdf" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/Snowy_Owl.pdf" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/Owl_Emergency_Care.pdf" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/Owl_Keeping.pdf" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Documents/New Pet Care/Sightings2005 (1).xls" exports/hd1/owl_evidence/
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Bibliography - Snowy Owl 14 April 2014 - GLOW posting.xls" exports/hd1/owl_evidence/
sudo chmod 644 exports/hd1/owl_evidence/* 2>/dev/null
ls -lh exports/hd1/owl_evidence/
# Copy and query Skype PC database
sudo cp "/mnt/hd1/Users/Sarah M/AppData/Roaming/Skype/live#3amcavoys87/main.db" exports/hd1/files/skype_pc_main.db
sudo chmod 644 exports/hd1/files/skype_pc_main.db
echo "Skype DB: $(ls -lh exports/hd1/files/skype_pc_main.db | awk '{print $5}')"
# Query messages
sqlite3 exports/hd1/files/skype_pc_main.db "SELECT datetime(timestamp,'unixepoch','UTC'), author, from_dispname, body_xml FROM Messages ORDER BY timestamp;" 2>&1
# Copy additional downloaded files from disk image
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Great Horned Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Pygmy Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Luna Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Great Horned Owl Info.pdf" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/Next pet.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo chmod 644 exports/hd1/owl_evidence/* 2>/dev/null
echo "=== Owl evidence files: ==="
ls -lh exports/hd1/owl_evidence/
# Amcache.hve not in registry dir - find it
sudo find /mnt/hd1/ -name "Amcache.hve" 2>/dev/null
# Copy with logs
sudo cp /mnt/hd1/Windows/AppCompat/Programs/Amcache.hve exports/hd1/registry/ 2>/dev/null && echo "Amcache copied"
sudo cp /mnt/hd1/Windows/AppCompat/Programs/Amcache.hve.LOG1 exports/hd1/registry/ 2>/dev/null
sudo cp /mnt/hd1/Windows/AppCompat/Programs/Amcache.hve.LOG2 exports/hd1/registry/ 2>/dev/null
# Copy SYSTEM logs
sudo cp /mnt/hd1/Windows/System32/config/SYSTEM.LOG1 exports/hd1/registry/ 2>/dev/null
sudo cp /mnt/hd1/Windows/System32/config/SYSTEM.LOG2 exports/hd1/registry/ 2>/dev/null
ls exports/hd1/registry/
# Amcache with correct path
sudo chmod 644 /mnt/hd1/Windows/appcompat/Programs/Amcache.hve 2>/dev/null
sudo cp /mnt/hd1/Windows/appcompat/Programs/Amcache.hve exports/hd1/registry/ 2>/dev/null
sudo cp /mnt/hd1/Windows/appcompat/Programs/Amcache.hve.LOG* exports/hd1/registry/ 2>/dev/null
sudo chmod 644 exports/hd1/registry/Amcache.hve* 2>/dev/null
dotnet /opt/zimmermantools/AmcacheParser.dll \
  -f exports/hd1/registry/Amcache.hve \
  --csv exports/hd1/amcache/ \
  --csvf amcache.csv 2>&1 | tail -8
# Unmount cleanly before report generation
sudo umount /mnt/hd1 && sudo umount /mnt/ewf_hd1 && echo "Image unmounted cleanly"
