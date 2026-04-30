ls /home/sansforensics/cases/OWL_TRADE_2026/ && ls /home/sansforensics/cases/OWL_TRADE_2026/evidence/ 2>/dev/null && ls /home/sansforensics/.claude/projects/-home-sansforensics-cases-OWL-TRADE-2026/memory/ 2>/dev/null
ls /home/sansforensics/cases/OWL_TRADE_2026/reports/ && ls /home/sansforensics/cases/OWL_TRADE_2026/analysis/ && ls /home/sansforensics/cases/OWL_TRADE_2026/exports/
ls -la "/home/sansforensics/cases/OWL_TRADE_2026/evidence/LGE Nexus 5 Full Image.raw" 2>/dev/null | awk '{print $5, $9}'
mmls "evidence/LGE Nexus 5 Full Image.raw" 2>&1
sudo mkdir -p /mnt/android_data /mnt/android_system && echo "Mount points created"
# Check filesystem type on userdata partition
sudo fsstat -o 3969024 "evidence/LGE Nexus 5 Full Image.raw" 2>&1 | head -20
OFFSET=$(( 3969024 * 512 ))
sudo mount -o ro,loop,noatime,offset=${OFFSET} "evidence/LGE Nexus 5 Full Image.raw" /mnt/android_data 2>&1 && echo "Mounted successfully" || echo "Mount failed"
OFFSET=$(( 3969024 * 512 ))
sudo mount -o ro,loop,noatime,norecovery,offset=${OFFSET} "evidence/LGE Nexus 5 Full Image.raw" /mnt/android_data 2>&1 && echo "Mounted successfully" || echo "Mount failed"
ls /mnt/android_data/ 2>&1
mkdir -p exports/{sms,calls,browser,email,social,media,contacts,apps,accounts} && echo "Export dirs created"
sudo ls /mnt/android_data/data/ 2>&1 | head -60
sudo ls /mnt/android_data/media/ 2>&1
sudo ls /mnt/android_data/data/ 2>&1 | tail -80
sudo ls /mnt/android_data/media/0/ 2>&1 | head -30
# SMS/MMS database
sudo find /mnt/android_data/data/com.android.providers.telephony -name "*.db" 2>/dev/null
echo "---"
sudo ls /mnt/android_data/data/com.android.providers.telephony/databases/ 2>/dev/null
# Contacts/Call log database
sudo find /mnt/android_data/data/com.android.providers.contacts -name "*.db" 2>/dev/null
echo "---"
sudo ls /mnt/android_data/data/com.android.providers.contacts/databases/ 2>/dev/null
# TextNow app databases
sudo find /mnt/android_data/data/com.enflick.android.TextNow -name "*.db" 2>/dev/null
echo "---"
sudo ls /mnt/android_data/data/com.enflick.android.TextNow/ 2>/dev/null
# Copy all key databases to exports for analysis
sudo cp /mnt/android_data/data/com.android.providers.telephony/databases/mmssms.db exports/sms/
sudo cp /mnt/android_data/data/com.android.providers.contacts/databases/contacts2.db exports/contacts/
sudo cp /mnt/android_data/data/com.enflick.android.TextNow/databases/textnow_data.db exports/social/textnow_data.db
sudo cp /mnt/android_data/data/com.enflick.android.TextNow/app_data/callhistory.db exports/social/textnow_callhistory.db
sudo cp /mnt/android_data/data/com.enflick.android.TextNow/app_data/smshistory.db exports/social/textnow_smshistory.db
ls exports/sms/ exports/contacts/ exports/social/ 2>/dev/null
# Check other messaging/social apps
for app in com.facebook.katana com.google.android.gm com.skype.raider com.snapchat.android com.google.android.talk com.twitter.android; do
  echo "=== $app ==="; sudo find /mnt/android_data/data/$app -name "*.db" 2>/dev/null | head -10
done
# Copy Skype database
sudo cp "/mnt/android_data/data/com.skype.raider/files/live#3amcavoys87/main.db" exports/social/skype_main.db
# Copy Google Hangouts databases
sudo cp /mnt/android_data/data/com.google.android.talk/databases/babel0.db exports/social/hangouts_babel0.db
sudo cp /mnt/android_data/data/com.google.android.talk/databases/message_store.db exports/social/hangouts_message_store.db 2>/dev/null || echo "no message_store"
# Copy Gmail databases
sudo cp /mnt/android_data/data/com.google.android.gm/databases/mailstore.mcavoys87@gmail.com.db exports/email/gmail_mailstore.db
# Copy Twitter DM database
sudo cp "/mnt/android_data/data/com.twitter.android/databases/826838231564034048-dm.db" exports/social/twitter_dm.db
# Copy Snapchat
sudo cp /mnt/android_data/data/com.snapchat.android/databases/tcspahn.db exports/social/snapchat.db 2>/dev/null || echo "Snapchat db access limited"
ls exports/social/ exports/email/
# SMS/MMS messages
echo "=== SMS TABLE SCHEMA ==="
sqlite3 exports/sms/mmssms.db ".tables" 2>&1
echo ""
echo "=== SMS MESSAGES (ALL) ==="
sqlite3 exports/sms/mmssms.db "SELECT datetime(date/1000,'unixepoch','UTC') as timestamp_utc, address, body, type FROM sms ORDER BY date;" 2>&1 | head -100
# Call log
echo "=== CALL LOG TABLE SCHEMA ==="
sqlite3 exports/contacts/contacts2.db ".tables" 2>&1
echo ""
echo "=== CALLS ==="
sqlite3 exports/contacts/contacts2.db "SELECT datetime(date/1000,'unixepoch','UTC') as timestamp_utc, number, name, type, duration FROM calls ORDER BY date;" 2>&1 | head -100
# TextNow SMS history
echo "=== TEXTNOW SMS TABLES ==="
sqlite3 exports/social/textnow_smshistory.db ".tables" 2>&1
echo ""
sqlite3 exports/social/textnow_smshistory.db ".schema" 2>&1 | head -40
ls -la exports/sms/ exports/contacts/ exports/social/ 2>&1 | head -30
sudo chmod 644 exports/sms/mmssms.db exports/contacts/contacts2.db exports/email/gmail_mailstore.db exports/social/*.db 2>/dev/null && echo "Permissions updated"
# SMS messages - full dump
echo "=== SMS MESSAGES ==="
sqlite3 exports/sms/mmssms.db "SELECT datetime(date/1000,'unixepoch','UTC') as timestamp_utc, address, body, CASE type WHEN 1 THEN 'RECEIVED' WHEN 2 THEN 'SENT' ELSE type END as direction FROM sms ORDER BY date;" 2>&1
# Fix call log query - check schema first
sqlite3 exports/contacts/contacts2.db ".tables" 2>&1
echo "---"
sqlite3 exports/contacts/contacts2.db ".schema calls" 2>&1 | head -20
# TextNow SMS history schema
sqlite3 exports/social/textnow_smshistory.db ".tables" 2>&1
echo "---"
sqlite3 exports/social/textnow_smshistory.db ".schema" 2>&1 | head -30
# Skype main.db schema
sqlite3 exports/social/skype_main.db ".tables" 2>&1
# Call log - corrected query
echo "=== CALL LOG ==="
sqlite3 exports/contacts/contacts2.db "SELECT datetime(date/1000,'unixepoch','UTC') as timestamp_utc, number, name, CASE type WHEN 1 THEN 'INCOMING' WHEN 2 THEN 'OUTGOING' WHEN 3 THEN 'MISSED' ELSE type END as direction, duration FROM calls ORDER BY date;" 2>&1
# TextNow SMS messages
echo "=== TEXTNOW SMS MESSAGES ==="
sqlite3 exports/social/textnow_smshistory.db "SELECT datetime(sentDate,'unixepoch','UTC') as timestamp_utc, direction, body, recipients FROM SMSHistory2 ORDER BY sentDate;" 2>&1
# Skype messages
echo "=== SKYPE MESSAGES ==="
sqlite3 exports/social/skype_main.db "SELECT datetime(timestamp,'unixepoch','UTC') as timestamp_utc, author, from_dispname, body_xml, dialog_partner FROM Messages ORDER BY timestamp;" 2>&1 | head -200
# Google Hangouts messages
echo "=== HANGOUTS TABLES ==="
sqlite3 exports/social/hangouts_babel0.db ".tables" 2>&1
# TextNow call history
echo "=== TEXTNOW CALL HISTORY ==="
sqlite3 exports/social/textnow_callhistory.db ".tables" 2>&1
echo "---"
sqlite3 exports/social/textnow_callhistory.db ".schema" 2>&1
# Check for Pidgin app
sudo find /mnt/android_data/data/ -maxdepth 1 -type d | grep -i pidgin 2>/dev/null
# Check for any IM/XMPP apps
sudo ls /mnt/android_data/data/ | grep -iE "pidgin|xmpp|jabber|otr|im\." 2>/dev/null
# Hangouts messages
echo "=== HANGOUTS MESSAGES ==="
sqlite3 exports/social/hangouts_babel0.db "SELECT datetime(timestamp/1000,'unixepoch','UTC') as ts_utc, author_chat_id, text FROM messages ORDER BY timestamp;" 2>&1 | head -100
# TextNow call records
echo "=== TEXTNOW CALL RECORDS ==="
sqlite3 exports/social/textnow_callhistory.db "SELECT datetime(callDate,'unixepoch','UTC') as timestamp_utc, callee, title, CASE direction WHEN 1 THEN 'OUTGOING' WHEN 2 THEN 'INCOMING' ELSE direction END as direction, duration, result FROM CallRecords ORDER BY callDate;" 2>&1
# Gmail mailstore schema check
echo "=== GMAIL TABLES ==="
sqlite3 exports/email/gmail_mailstore.db ".tables" 2>&1 | head -10
# Gmail - all messages/conversations
echo "=== GMAIL TABLES FULL ==="
sqlite3 exports/email/gmail_mailstore.db ".tables" 2>&1
echo ""
echo "=== GMAIL MESSAGES ==="
sqlite3 exports/email/gmail_mailstore.db "SELECT datetime(received_timestamp_ms/1000,'unixepoch','UTC') as ts_utc, from_address, subject, snippet FROM conversations ORDER BY received_timestamp_ms;" 2>&1 | head -80
# Check TextNow data.db for account info and messages
echo "=== TEXTNOW DATA TABLES ==="
sqlite3 exports/social/textnow_data.db ".tables" 2>&1
echo "---"
sqlite3 exports/social/textnow_data.db ".schema" 2>&1 | head -60
# TextNow messages - the most critical database
echo "=== TEXTNOW MESSAGES ==="
sqlite3 exports/social/textnow_data.db "SELECT datetime(date/1000,'unixepoch','UTC') as timestamp_utc, contact_value, contact_name, CASE message_direction WHEN 1 THEN 'INCOMING' WHEN 2 THEN 'OUTGOING' ELSE message_direction END as direction, message_text FROM messages ORDER BY date;" 2>&1
# Gmail messages schema fix
sqlite3 exports/email/gmail_mailstore.db ".schema messages" 2>&1 | head -10
# Hangouts participants schema fix
sqlite3 exports/social/hangouts_babel0.db ".schema participants" 2>&1 | head -10
# Gmail messages - all with correct schema
echo "=== GMAIL MESSAGES ==="
sqlite3 exports/email/gmail_mailstore.db "SELECT datetime(dateReceivedMs/1000,'unixepoch','UTC') as ts_utc, fromAddress, subject, snippet FROM messages ORDER BY dateReceivedMs;" 2>&1 | head -100
# Hangouts participants - all
echo "=== HANGOUTS PARTICIPANTS ==="
sqlite3 exports/social/hangouts_babel0.db "SELECT chat_id, full_name, fallback_name, gaia_id FROM participants;" 2>&1
# TextNow conversations list
echo "=== TEXTNOW CONVERSATIONS ==="
sqlite3 exports/social/textnow_data.db "SELECT contact_value, contact_name, message_count FROM conversations;" 2>&1
# Chrome browser history
sudo find /mnt/android_data/data/com.android.chrome -name "History" 2>/dev/null
# List photos and media
sudo ls /mnt/android_data/media/0/DCIM/ 2>/dev/null
echo "---"
sudo find /mnt/android_data/media/0/ -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" 2>/dev/null | head -30
# Skype contacts info
echo "=== SKYPE CONTACTS ==="
sqlite3 exports/social/skype_main.db "SELECT skypename, fullname, displayname, emails, city, country, homepage, about FROM Contacts;" 2>&1
# Copy owl images and all downloads to evidence exports
mkdir -p exports/media/downloads exports/media/photos
sudo cp /mnt/android_data/media/0/Download/*.jpg exports/media/downloads/ 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/*.jpeg exports/media/downloads/ 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/*.png exports/media/downloads/ 2>/dev/null
sudo ls -la /mnt/android_data/media/0/Download/ 2>/dev/null
# Chrome browser history
sudo cp /mnt/android_data/data/com.android.chrome/app_chrome/Default/History exports/browser/chrome_history.db 2>/dev/null && sudo chmod 644 exports/browser/chrome_history.db
sqlite3 exports/browser/chrome_history.db "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, url, title, visit_count FROM urls ORDER BY last_visit_time;" 2>&1 | head -100
# Check TextNow shared_prefs for account info
sudo ls /mnt/android_data/data/com.enflick.android.TextNow/shared_prefs/ 2>/dev/null
sudo find /mnt/android_data/data/com.enflick.android.TextNow/shared_prefs/ -name "*.xml" -exec sudo cat {} \; 2>/dev/null | head -60
# TextNow account info
sudo cat /mnt/android_data/data/com.enflick.android.TextNow/shared_prefs/com.enflick.android.TextNow_preferences.xml 2>/dev/null | grep -E "username|phone|number|email|account" -i | head -20
# TextNow account XML
sudo cat /mnt/android_data/data/com.enflick.android.TextNow/shared_prefs/TNSettingsInfo.xml 2>/dev/null
echo "---"
sudo cat /mnt/android_data/data/com.enflick.android.TextNow/shared_prefs/TNDevice.xml 2>/dev/null
# Camera photos in DCIM
sudo ls -la /mnt/android_data/media/0/DCIM/Camera/ 2>/dev/null | head -30
# Google account info
sudo cat /mnt/android_data/system/accounts.db 2>/dev/null || \
sudo find /mnt/android_data/system/ -name "accounts.db" 2>/dev/null -exec sudo sqlite3 {} ".tables" \;
echo "---"
sudo find /mnt/android_data/system/ -name "accounts*.db" 2>/dev/null
# Twitter DM database schema & content
sqlite3 exports/social/twitter_dm.db ".tables" 2>&1
echo "---"
sqlite3 exports/social/twitter_dm.db ".schema" 2>&1 | head -20
# Facebook database content
sqlite3 exports/social/snapchat.db ".tables" 2>&1
echo "---SNAPCHAT SCHEMA---"
sqlite3 exports/social/snapchat.db ".schema" 2>&1 | head -30
# Snapchat friends
sqlite3 exports/social/snapchat.db "SELECT Username, DisplayName, PhoneNumber, AddedMeTimestamp, AddedThemTimestamp, AddSource FROM Friends;" 2>&1
echo "---CONTACTS ON SNAPCHAT---"
sqlite3 exports/social/snapchat.db "SELECT Username, DisplayName, PhoneNumber FROM ContactsOnSnapchatTable;" 2>&1
echo "---CHATS---"
sqlite3 exports/social/snapchat.db "SELECT * FROM Chat LIMIT 10;" 2>&1
# Google accounts registered on device
sudo cp /mnt/android_data/system/users/0/accounts.db exports/accounts.db && sudo chmod 644 exports/accounts.db
sqlite3 exports/accounts.db "SELECT name, type FROM accounts;" 2>&1
# Check the "1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg" unknown image - get its metadata
file exports/media/downloads/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg 2>/dev/null
exiftool exports/media/downloads/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg 2>/dev/null | head -20
ls exports/media/downloads/ && sudo chmod 644 /mnt/android_data/media/0/Download/*.jpg 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg exports/media/downloads/ 2>/dev/null
ls exports/media/downloads/
# Full list of all accounts on device
sqlite3 exports/accounts.db "SELECT name, type FROM accounts;" 2>&1
echo "---"
# Check MusicAlly/TikTok account
sudo find /mnt/android_data/data/com.zhiliaoapp.musically/ -name "*.xml" 2>/dev/null | head -5
sudo cat /mnt/android_data/data/com.zhiliaoapp.musically/shared_prefs/*.xml 2>/dev/null | grep -E "username|user_id|email|name" | head -20
# Check Skype conversations more carefully for any owl reference
sqlite3 exports/social/skype_main.db "SELECT datetime(timestamp,'unixepoch','UTC'), author, body_xml FROM Messages WHERE body_xml LIKE '%owl%' OR body_xml LIKE '%bird%' OR body_xml LIKE '%deliver%' OR body_xml LIKE '%buy%' OR body_xml LIKE '%price%';" 2>&1
# Get image metadata for the unknown jpg
exiftool exports/media/downloads/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg 2>&1 | head -25 || \
sudo file /mnt/android_data/media/0/Download/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg 2>/dev/null
sqlite3 exports/browser/chrome_history.db "SELECT datetime(start_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, current_path, referrer, total_bytes FROM downloads ORDER BY start_time;" 2>&1
strings exports/media/downloads/1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg | grep -iE "owl|bird|snowy|sale|buy|price|trade" | head -20
# Export all SMS to CSV
sqlite3 -separator ',' exports/sms/mmssms.db \
"SELECT 'timestamp_utc','address','body','direction'
UNION ALL
SELECT datetime(date/1000,'unixepoch','UTC'), address, replace(body,char(10),' '), CASE type WHEN 1 THEN 'RECEIVED' WHEN 2 THEN 'SENT' ELSE CAST(type AS TEXT) END FROM sms ORDER BY date;" \
> exports/sms/sms_all.csv 2>&1
wc -l exports/sms/sms_all.csv
# Export call log to CSV
sqlite3 -separator ',' exports/contacts/contacts2.db \
"SELECT 'timestamp_utc','number','name','direction','duration_sec'
UNION ALL
SELECT datetime(date/1000,'unixepoch','UTC'), number, name, CASE type WHEN 1 THEN 'INCOMING' WHEN 2 THEN 'OUTGOING' WHEN 3 THEN 'MISSED' ELSE CAST(type AS TEXT) END, duration FROM calls ORDER BY date;" \
> exports/calls/calllog.csv 2>&1
wc -l exports/calls/calllog.csv
# Export browser history to CSV (owl-related)
sqlite3 -separator '|' exports/browser/chrome_history.db \
"SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, url, title, visit_count FROM urls ORDER BY last_visit_time;" \
> exports/browser/browser_history_full.txt 2>&1
# Export owl-related searches only
sqlite3 -separator '|' exports/browser/chrome_history.db \
"SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','UTC') as ts_utc, url, title, visit_count FROM urls WHERE url LIKE '%owl%' OR url LIKE '%bird%' OR title LIKE '%owl%' OR title LIKE '%bird%' ORDER BY last_visit_time;" \
> exports/browser/browser_owl_searches.txt 2>&1
echo "Full history: $(wc -l < exports/browser/browser_history_full.txt) entries"
echo "Owl-related: $(wc -l < exports/browser/browser_owl_searches.txt) entries"
# The CSV exports need fixing - use different approach
sqlite3 exports/sms/mmssms.db \
  "SELECT datetime(date/1000,'unixepoch','UTC'), address, replace(replace(body,char(10),' '),char(13),' '), CASE type WHEN 1 THEN 'RECEIVED' WHEN 2 THEN 'SENT' ELSE CAST(type AS TEXT) END FROM sms ORDER BY date;" \
  2>&1 | awk 'BEGIN{print "timestamp_utc|address|body|direction"} {print}' FS='|' > exports/sms/sms_all.csv
wc -l exports/sms/sms_all.csv
sqlite3 exports/contacts/contacts2.db \
  "SELECT datetime(date/1000,'unixepoch','UTC'), number, name, CASE type WHEN 1 THEN 'INCOMING' WHEN 2 THEN 'OUTGOING' WHEN 3 THEN 'MISSED' ELSE CAST(type AS TEXT) END, duration FROM calls ORDER BY date;" \
  2>&1 | awk 'BEGIN{print "timestamp_utc|number|name|direction|duration_sec"} {print}' FS='|' > exports/calls/calllog.csv
wc -l exports/calls/calllog.csv
# Export Skype conversations to text
sqlite3 exports/social/skype_main.db \
  "SELECT datetime(timestamp,'unixepoch','UTC'), author, from_dispname, replace(replace(body_xml,char(10),' '),char(13),' ') FROM Messages ORDER BY timestamp;" \
  2>&1 | awk 'BEGIN{print "timestamp_utc|author|display_name|message"} {print}' FS='|' > exports/social/skype_messages.txt
wc -l exports/social/skype_messages.txt
mkdir -p reports && ls reports/
# Unmount the Android partition cleanly
sudo umount /mnt/android_data && echo "Unmounted successfully"
# Final verification of report and exports
echo "=== REPORT ==="
ls -lh reports/
echo ""
echo "=== EXPORTS ==="
find exports/ -type f | sort | head -40
ls -lh exports/media/downloads/
# Re-mount briefly to extract the snowy owl images
OFFSET=$(( 3969024 * 512 ))
sudo mount -o ro,loop,noatime,norecovery,offset=${OFFSET} "evidence/LGE Nexus 5 Full Image.raw" /mnt/android_data 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/220px-Snowy_Owl_Barrow_Alaska.jpg exports/media/downloads/ 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/220px-Snowy_Owl_-_Schnee-Eule.jpg exports/media/downloads/ 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/SeaTurtle-1600x600px.jpg exports/media/downloads/ 2>/dev/null
sudo cp /mnt/android_data/media/0/Download/download.jpg exports/media/downloads/ 2>/dev/null
sudo umount /mnt/android_data
sudo chmod 644 exports/media/downloads/*.jpg 2>/dev/null
ls -lh exports/media/downloads/
ls /home/sansforensics/.claude/projects/-home-sansforensics-cases-OWL-TRADE-2026/memory/ 2>/dev/null || echo "memory dir check"
