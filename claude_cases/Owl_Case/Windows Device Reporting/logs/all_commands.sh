ewfinfo evidence/HD1.E01 2>&1
mkdir -p exports/hd1/{mft,registry,evtx/parsed,prefetch,amcache,shimcache,srum,shellbags,jumplists,lnk,browser/parsed,recyclebin,files,WindowsTimeline} && echo "Export dirs ready"
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
# Chrome browser history for Sarah M
sudo chmod 644 "exports/hd1/browser/Sarah_M/History" 2>/dev/null
sqlite3 "exports/hd1/browser/Sarah_M/History" \
  "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, url, title, visit_count FROM urls ORDER BY last_visit_time;" 2>&1 | head -100
# RECmd batch on all registry hives
sudo chmod 644 exports/hd1/registry/* 2>/dev/null
dotnet /opt/zimmermantools/RECmd/RECmd.dll \
  -d exports/hd1/registry/ \
  --bn /opt/zimmermantools/RECmd/BatchExamples/Kroll_Batch.reb \
  --csv exports/hd1/registry/ \
  --csvf hd1_registry_batch.csv 2>&1 | tail -10
# Exif data on owl images
exiftool exports/hd1/owl_evidence/Snowy\ Owl.jpg exports/hd1/owl_evidence/Snowy\ Owl\ 2.jpg exports/hd1/owl_evidence/Snowy\ Owl\ 3.jpg exports/hd1/owl_evidence/Snowy\ Owl\ 4.jpg exports/hd1/owl_evidence/My\ New\ Pet.jpg 2>&1 | grep -E "File Name|File Modification|Date/Time|GPS|Make|Model|Image Description|Comment|Title|Artist|Creator|Copyright" | head -40
# Get remaining browser history (after first 100 lines)
sqlite3 "exports/hd1/browser/Sarah_M/History" \
  "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, url, title, visit_count FROM urls ORDER BY last_visit_time LIMIT 500 OFFSET 100;" 2>&1
# Run PECmd on Prefetch to identify key executed programs
sudo chmod 644 exports/hd1/prefetch/*.pf 2>/dev/null
dotnet /opt/zimmermantools/PECmd.dll \
  -d exports/hd1/prefetch/ \
  --csv exports/hd1/prefetch/ \
  --csvf prefetch_parsed.csv 2>&1 | tail -5
ls /opt/zimmermantools/ | grep -i "peCmd\|PECmd" 2>/dev/null
ls /opt/zimmermantools/*.dll 2>/dev/null | head -20
# Read the full browser history output file
cat /home/sansforensics/.claude/projects/-home-sansforensics-cases-OWL-TRADE-2026/cb26a460-fe8f-418b-9bb7-4e9d53c5587c/tool-results/bzuinamus.txt 2>/dev/null | grep -iE "owl|bird|snowy|exotic|egg|21food|pet|cage|feed|deliver|pidgin|yahoo|messenger" | head -60
# Full browser history - all owl/bird/pet relevant entries from the saved file
cat /home/sansforensics/.claude/projects/-home-sansforensics-cases-OWL-TRADE-2026/cb26a460-fe8f-418b-9bb7-4e9d53c5587c/tool-results/bzuinamus.txt 2>/dev/null | tail -n +3 | head -200
# Chrome downloads history
sqlite3 "exports/hd1/browser/Sarah_M/History" \
  "SELECT datetime(start_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, current_path, referrer, tab_url, total_bytes FROM downloads ORDER BY start_time;" 2>&1
# Copy additional downloaded files from disk image
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Great Horned Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Pygmy Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Luna Owl.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Downloads/Great Horned Owl Info.pdf" exports/hd1/owl_evidence/ 2>/dev/null
sudo cp "/mnt/hd1/Users/Sarah M/Desktop/Next pet.jpg" exports/hd1/owl_evidence/ 2>/dev/null
sudo chmod 644 exports/hd1/owl_evidence/* 2>/dev/null
echo "=== Owl evidence files: ==="
ls -lh exports/hd1/owl_evidence/
# Run Amcache Parser
dotnet /opt/zimmermantools/AmcacheParser.dll \
  -f exports/hd1/registry/Amcache.hve \
  --csv exports/hd1/amcache/ \
  --csvf amcache.csv 2>&1 | tail -8
# Run Shimcache / AppCompatCache parser
dotnet /opt/zimmermantools/AppCompatCacheParser.dll \
  -f exports/hd1/registry/SYSTEM \
  --csv exports/hd1/shimcache/ \
  --csvf shimcache.csv 2>&1 | tail -5
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
# Parse EvtxECmd on Security, System, and PowerShell logs
sudo chmod 644 "exports/hd1/evtx/Logs/Security.evtx" "exports/hd1/evtx/Logs/System.evtx" 2>/dev/null
dotnet /opt/zimmermantools/EvtxeCmd/EvtxECmd.dll \
  -d exports/hd1/evtx/Logs/ \
  --inc 4624,4625,4648,4720,4722,4698,4688,7045,4698 \
  --csv exports/hd1/evtx/parsed/ \
  --csvf hd1_security_events.csv \
  --maps /opt/zimmermantools/EvtxeCmd/Maps/ 2>&1 | tail -8
# Amcache with correct path
sudo chmod 644 /mnt/hd1/Windows/appcompat/Programs/Amcache.hve 2>/dev/null
sudo cp /mnt/hd1/Windows/appcompat/Programs/Amcache.hve exports/hd1/registry/ 2>/dev/null
sudo cp /mnt/hd1/Windows/appcompat/Programs/Amcache.hve.LOG* exports/hd1/registry/ 2>/dev/null
sudo chmod 644 exports/hd1/registry/Amcache.hve* 2>/dev/null
dotnet /opt/zimmermantools/AmcacheParser.dll \
  -f exports/hd1/registry/Amcache.hve \
  --csv exports/hd1/amcache/ \
  --csvf amcache.csv 2>&1 | tail -8
# Parse event logs - check logon events and user creation
ls exports/hd1/evtx/parsed/
echo "---"
# Look for key events
sudo chmod 644 exports/hd1/evtx/parsed/*.csv 2>/dev/null
head -2 exports/hd1/evtx/parsed/*.csv 2>/dev/null | head -5
grep -h "4624\|4720\|4698" exports/hd1/evtx/parsed/*.csv 2>/dev/null | grep -v "EventId" | head -30
# Check Amcache results - look for interesting executables
ls exports/hd1/amcache/
echo "---"
sudo chmod 644 exports/hd1/amcache/*.csv 2>/dev/null
# Show files referencing pidgin, yahoo, or interesting apps
grep -ih "pidgin\|yahoo\|owl\|skype\|chrome" exports/hd1/amcache/*.csv 2>/dev/null | head -20
# Read event log CSV for logon events and user account creation
cat /home/sansforensics/.claude/projects/-home-sansforensics-cases-OWL-TRADE-2026/cb26a460-fe8f-418b-9bb7-4e9d53c5587c/tool-results/bmq5wibyo.txt 2>/dev/null | grep -E "4720|4624|Sarah|sarah" | head -20
# Get computer name and timezone from registry batch
sudo chmod 644 exports/hd1/registry/hd1_registry_batch.csv 2>/dev/null
grep -i "ComputerName\|TimeZone\|LastLoggedOn\|ProfileList\|InstallDate\|ProductName" exports/hd1/registry/hd1_registry_batch.csv 2>/dev/null | head -20
# Parse LNK files for Sarah M
dotnet /opt/zimmermantools/LECmd.dll \
  -d "exports/hd1/lnk/Sarah_M/" \
  --csv exports/hd1/lnk/ \
  --csvf lnk_sarahm.csv 2>&1 | tail -5
sudo chmod 644 exports/hd1/lnk/*.csv 2>/dev/null
# Show owl/pidgin/relevant LNK entries
grep -i "owl\|pidgin\|skype\|yahoo\|chrome\|pet" exports/hd1/lnk/lnk_sarahm.csv 2>/dev/null | head -20
# Parse Recycle Bin
sudo chmod 644 exports/hd1/recyclebin/* 2>/dev/null
dotnet /opt/zimmermantools/RBCmd.dll \
  -d exports/hd1/recyclebin/ \
  --csv exports/hd1/recyclebin/ \
  --csvf recyclebin.csv 2>&1 | tail -5
sudo chmod 644 exports/hd1/recyclebin/*.csv 2>/dev/null
cat exports/hd1/recyclebin/recyclebin.csv 2>/dev/null | column -t -s, | head -20
# Get system info from registry: computer name, timezone, OS version
grep -i "ComputerName\|TimeZoneKey\|ProductName\|InstallDate\|RegisteredOwner" exports/hd1/registry/hd1_registry_batch.csv 2>/dev/null | grep -v "^$" | head -15
# Export full browser history to file
sqlite3 "exports/hd1/browser/Sarah_M/History" \
  "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC'), url, title FROM urls ORDER BY last_visit_time;" \
  > exports/hd1/browser/chrome_history_sarahm_full.txt 2>&1
echo "Browser history: $(wc -l < exports/hd1/browser/chrome_history_sarahm_full.txt) entries"

# Save Skype to text
sqlite3 exports/hd1/files/skype_pc_main.db \
  "SELECT datetime(timestamp,'unixepoch','UTC'), author, from_dispname, replace(replace(body_xml,char(10),' '),char(13),' ') FROM Messages ORDER BY timestamp;" \
  > exports/hd1/files/skype_pc_messages.txt 2>&1
echo "Skype messages: $(wc -l < exports/hd1/files/skype_pc_messages.txt)"
# Unmount cleanly before report generation
sudo umount /mnt/hd1 && sudo umount /mnt/ewf_hd1 && echo "Image unmounted cleanly"
ls -lh reports/ && echo "---" && ls exports/hd1/owl_evidence/
