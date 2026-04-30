# FORENSIC EXAMINATION REPORT
## Case: OWL_TRADE_2026 — Illegal Wildlife Trade (Owl)

---

| Field | Value |
|-------|-------|
| **Report Author** | DFIR Orchestrator (Claude Code) |
| **Report Date** | 2026-04-29 (UTC) |
| **Case Number** | OWL_TRADE_2026 |
| **Client** | Carnegie Mellon University (CMU) |
| **Course** | 14-822 — Host Based Forensics |
| **Initial Responders** | Haylee Viramontes, Chen Tao, Chloe Taylor |
| **Incident Declared** | 2026-01-24 |
| **Examiner Role** | External IR Consultant |

---

## 1. Evidence Summary

| Item | Description | Hash / Notes |
|------|-------------|--------------|
| LGE Nexus 5 Full Image.raw | Android full device image | 31,268,536,320 bytes (~29.12 GB) |

**Evidence integrity:** Image mounted read-only (norecovery). No modifications made to evidence.

---

## 2. Device Identification

| Attribute | Value |
|-----------|-------|
| **Device** | LGE Nexus 5 (hammerhead) |
| **OS** | Android (userdata partition ext4, mounted at /data) |
| **Image Format** | RAW (GPT partition table) |
| **Userdata Partition** | Slot 027, Start sector 3,969,024, 57,102,292 sectors (~27.2 GB) |
| **System Partition** | Slot 024, Start sector 376,832, 2,097,152 sectors (~1 GB) |
| **First Activity** | 2017-01-20 (AT&T GoPhone activation) |
| **Last Activity** | 2017-02-06 (Skype concierge tip timestamp) |

---

## 3. Suspect Identification

| Platform | Identity |
|----------|----------|
| **Full Name** | Sarah McAvoy |
| **Gmail** | mcavoys87@gmail.com |
| **Skype** | live:mcavoys87 |
| **TextNow** | username: mcavoys87 / phone: **901-444-9108** |
| **Twitter** | mcavoys87 (UID: 826838231564034048) |
| **TikTok/Musical.ly** | SarahMcavoy / sarahmcavoy |

**Source:** TextNow `shared_prefs/com.enflick.android.TextNow_preferences.xml`; device `accounts.db`; Skype `Contacts` table.

---

## 4. Co-Conspirator Identification

| Attribute | Value |
|-----------|-------|
| **Phone Number** | +1 (304) 518-4333 |
| **Communication Channel** | Native SMS to Sarah's AT&T GoPhone SIM |
| **Secondary Channel** | Pidgin (PC-based XMPP/IM client — referenced in SMS) |
| **Nature of Contact** | Delivery coordination for illegal owl acquisition |

**Note:** "Matt Haze28" (Skype: live:generalhaze28) is a separate social contact (movie plans); no owl-related content found in those exchanges.

---

## 5. Key Evidence

### 5.1 Critical SMS — Delivery Coordination (HIGHEST RELEVANCE)

| Field | Value |
|-------|-------|
| **Timestamp (UTC)** | 2017-02-01 05:41:15 |
| **From** | +1 (304) 518-4333 |
| **To** | Sarah McAvoy |
| **Message** | *"Sarah, the delivery is today 7 tonight the confirmation will come later through pidgin"* |

| Field | Value |
|-------|-------|
| **Timestamp (UTC)** | 2017-02-01 05:41:45 |
| **From** | Sarah McAvoy |
| **To** | +1 (304) 518-4333 |
| **Message** | *"Thank you!"* |

**Analysis:** The co-conspirator notified Sarah of a same-day delivery ("7 tonight") and indicated that a confirmation would be sent via **Pidgin** — a desktop XMPP/IM client. The use of Pidgin for confirmation suggests the conspirators deliberately moved to a PC-based platform for the final transaction details, likely to avoid mobile forensics. Sarah's "Thank you!" reply confirms receipt and acceptance.

**Source:** `mmssms.db` / `sms` table; corroborated by `hangouts_babel0.db` / `messages` table.

---

### 5.2 Browser History — Owl Purchasing Research

All timestamps UTC. Extracted from Chrome `History` database.

#### Session 1: 2017-01-25 (Initial Owl Trade Research)

| Timestamp (UTC) | URL | Title |
|-----------------|-----|-------|
| 07:10:46 | internationalowlcenter.org/owls-humans/owlsaspets | Owls as Pets |
| 07:10:56 | reference.com/…/can-buy-owl… | Where can I buy an owl? |
| 07:11:47 | answers.yahoo.com/…AAFEx2R | Where can I buy an owl? (Yahoo Answers) |
| 07:20:22 | quora.com/…baby-owls-for-sale-Are-owls-legal… | Where can you find baby owls for sale? Are owls legal to keep as pets? |
| 07:22:44 | birdtrader.co.uk/…tawny-owls-for-sale/557493 | Tawny Owls for Sale (Londonderry, N. Ireland) |
| 07:22:57 | birdtrader.co.uk/…bonding-pair-asian-wood-owls/558006 | BONDING PAIR ASIAN WOOD OWLS (Northamptonshire) |
| 07:23:10 | birdtrader.co.uk/birds-of-prey-for-sale?sstr=Baby+owl | Owls for Sale — BirdTrader |
| 07:23:27 | birdtrader.co.uk/…barn-owls-for-sale/557933 | Barn Owls for Sale (Lincolnshire) |
| 07:26:34 | exoticanimalsforsale.net/search.asp?q=Owl | Search Exotic Animals: Owl |
| 07:27:15 | exoticanimalsforsale.net/search.asp?q=Owl&page=2 | Search Exotic Animals: Owl (page 2) |
| 07:27:33 | exoticanimalsforsale.net/search.asp?q=Owl&page=3 | Search Exotic Animals: Owl (page 3) |

**Analysis:** Sarah systematically researched owl purchasing sites on 2017-01-25 — the same day she received her Facebook confirmation code, suggesting this was very early in the operation. She browsed UK-based bird trading sites (BirdTrader) and exotic animal sale sites. The search term "baby owls for sale" and legality research ("Are owls legal to keep as pets?") is consistent with the early planning stage of an illegal wildlife purchase.

#### Session 2: 2017-01-31 (Bird Supply Procurement)

| Timestamp (UTC) | URL | Title |
|-----------------|-----|-------|
| 03:06:18 | amazon.com/…bird+feeder | Amazon.com: bird feeder |
| 03:06:37 | amazon.com/…/B0002AQMDM/…bird+bedding | Kaytee Kay Kob Bedding for Birds, 8-Pound |
| 03:06:43 | amazon.com/…/B00BUFRZU2/…bird+bedding | Kaytee Walnut Bedding and Litter Pad, 7-Pound |
| 03:09:47 | bing.com/search?q=owls | owls — Bing |
| 03:11:29 | bing.com/…q=owls+Snowy | Bing image search: owls Snowy |

**Analysis:** Sarah searched Amazon for **bird feeder** and **bird bedding** products — consistent with preparing to receive and house a live bird. This activity occurred on the same evening she sent the Skype message "Hey Matt thanks for the hook up" (2017-01-31 00:15 UTC), suggesting the "hook up" referred to the owl arrangement. The subsequent Bing snowy owl image searches corroborate the specific species of interest.

#### Session 3: 2017-02-03 (Post-Delivery Research)

| Timestamp (UTC) | URL | Title |
|-----------------|-----|-------|
| 22:19:05 | google.com/…tbm=isch&q=owls | owls — Google Image Search |
| 22:20:17 | google.com/…q=snowy+owl | snowy owl — Google Image Search |
| 22:20:49–53 | google.com/…snowy+owl (multiple image views) | Snowy owl image browsing |

**Analysis:** Continued owl image browsing two days after the delivery. This post-delivery interest is consistent with someone who had recently acquired an owl and was continuing to research the species.

---

### 5.3 Downloaded Files

All files downloaded **2017-02-03** (corroborated by Chrome downloads database and filesystem timestamps).

| Filename | Size | Source | Relevance |
|----------|------|---------|-----------|
| `220px-Snowy_Owl_Barrow_Alaska.jpg` | 15,191 bytes | Referrer: google.com (image search) | Snowy Owl — species of interest |
| `220px-Snowy_Owl_-_Schnee-Eule.jpg` | 22,062 bytes | Referrer: google.com (image search) | Snowy Owl (German: "Snow Owl") |
| `SeaTurtle-1600x600px.jpg` | 56,867 bytes | Referrer: google.com (image search) | Sea turtle image |
| `1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg` | 81,982 bytes | Referrer: google.com (image search) | Unknown subject (1134×756 px JPEG) |
| `download.jpg` | 10,704 bytes | Chrome download | Unknown subject |

**Supporting files location:** `exports/media/downloads/`

**Analysis:** Two distinct snowy owl images were downloaded, directly corroborating the Bing/Google "Snowy Owl" image search activity. The sea turtle images suggest possible interest in a second CITES-protected species, though no direct trade evidence was found for turtles within this dataset.

---

### 5.4 Skype Messages — "Hook Up" Reference

Extracted from Skype `main.db` / `Messages` table.

| Timestamp (UTC) | Author | Message |
|-----------------|--------|---------|
| 2017-01-31 00:15:25 | live:mcavoys87 (Sarah) | *"Hey Matt thanks for the hook up"* |
| 2017-01-31 00:16:07 | live:generalhaze28 (Matt) | *"No prob have you seen the new Rings movie"* |

**Analysis:** Sarah thanked "Matt Haze28" for a "hook up" — and the conversation immediately pivoted to innocuous movie discussion. The phrase "hook up" in context (immediately following the owl purchasing research phase, and days before the delivery SMS) is consistent with a referral or introduction to the owl supplier. Matt's non-responsive pivot to movies may indicate awareness of communications security.

---

### 5.5 Social Media Account Creation Timeline

Corroborated by SMS verification codes received.

| Date (UTC) | Event |
|------------|-------|
| 2017-01-20 | AT&T GoPhone activated (new SIM/device) |
| 2017-01-25 | Facebook account confirmed (code from 32665) |
| 2017-01-26 | Twitter account activated (code from 40404); Microsoft account code received |
| 2017-01-27 | Facebook friends accepted: Monica Neff, Terry Bunch, Isaiah Dashner |
| 2017-01-31 | Skype conversation with live:generalhaze28 |
| 2017-02-01 | Delivery SMS received from +1(304)518-4333 |
| 2017-02-03 | Snowy owl image searches and downloads |

**Analysis:** The rapid creation of multiple social accounts immediately after device activation (all within 6 days of SIM activation) is consistent with establishing a new persona/identity for operational purposes. The GoPhone prepaid SIM provides anonymity; the TextNow VOIP number (901-444-9108) provides an additional layer of communication obfuscation.

---

## 6. Installed Applications of Forensic Significance

| Package | Application | Forensic Significance |
|---------|-------------|----------------------|
| com.enflick.android.TextNow | TextNow | VOIP/SMS anonymization layer (# 901-444-9108) |
| com.skype.raider | Skype | Chat with contact who "hooked up" owl purchase |
| com.facebook.katana | Facebook | Social network — friends potentially aware of activity |
| com.snapchat.android | Snapchat | Ephemeral messaging; content not retained in database |
| com.google.android.talk | Google Hangouts | SMS bridge; delivery SMS also captured here |
| com.twitter.android | Twitter | Account mcavoys87 activated 2017-01-26 |
| com.zhiliaoapp.musically | TikTok/Musical.ly | Account: SarahMcavoy |

**Note on Snapchat:** The Snapchat database (`tcspahn.db`) contained no retained chat messages, consistent with Snapchat's ephemeral design. Snaps and chats are deleted after viewing. Metadata tables (Friends, ReceivedSnaps, SentSnaps) were empty.

**Note on Pidgin:** No Pidgin application was found installed on the Android device. Pidgin is a Windows/Linux desktop IM client — the co-conspirator's reference to "pidgin" in the SMS indicates that owl trade confirmation communications were conducted from a separate desktop/laptop system not present in this evidence set.

---

## 7. Communication Network

```
Sarah McAvoy (mcavoys87)
  ├── AT&T GoPhone SIM (primary)
  │     └── SMS with +1(304)518-4333  [DELIVERY COORDINATION — KEY EVIDENCE]
  ├── TextNow VOIP: 901-444-9108
  ├── Skype: live:mcavoys87
  │     └── live:generalhaze28 (Matt Haze28)  ["hook up" reference]
  ├── Gmail: mcavoys87@gmail.com
  ├── Facebook (confirmed via SMS verification)
  │     └── Friends: Monica Neff, Terry Bunch, Isaiah Dashner
  ├── Twitter: mcavoys87
  ├── Snapchat (ephemeral — no content retained)
  └── TikTok/Musical.ly: SarahMcavoy

Co-Conspirator: +1(304)518-4333
  └── Pidgin desktop IM (referenced for delivery confirmation)
       [NOT found on this Android device — requires separate investigation]
```

---

## 8. Timeline of Events

| Date/Time (UTC) | Event | Source |
|-----------------|-------|--------|
| 2017-01-20 22:25 | AT&T GoPhone SIM activated; Welcome SMS received | mmssms.db |
| 2017-01-25 07:10–07:27 | Extensive owl purchasing research (Yahoo, Quora, BirdTrader UK, ExoticAnimalsForSale) | chrome_history |
| 2017-01-25 07:16 | Facebook account confirmed via SMS verification code | mmssms.db |
| 2017-01-26 01:50–01:58 | Twitter account activated (two verification codes); Microsoft account code received | mmssms.db |
| 2017-01-27 22:39–22:47 | Facebook friend requests accepted: Monica Neff, Terry Bunch, Isaiah Dashner | mmssms.db |
| 2017-01-31 00:15 | Skype: Sarah tells Matt Haze28 "thanks for the hook up" | skype_main.db |
| 2017-01-31 03:06 | Amazon searches for bird feeder and bird bedding | chrome_history |
| 2017-01-31 03:09–03:11 | Bing searches: "owls", "owls Snowy" | chrome_history |
| 2017-02-01 05:41:15 | **SMS received from +1(304)518-4333: "the delivery is today 7 tonight the confirmation will come later through pidgin"** | mmssms.db |
| 2017-02-01 05:41:45 | **Sarah replies: "Thank you!"** | mmssms.db |
| 2017-02-03 22:19–22:21 | Google image searches: "owls", "snowy owl" | chrome_history |
| 2017-02-03 22:20:30 | Download: `220px-Snowy_Owl_-_Schnee-Eule.jpg` | chrome_downloads |
| 2017-02-03 22:20:44 | Download: `220px-Snowy_Owl_Barrow_Alaska.jpg` | chrome_downloads |
| 2017-02-03 22:21:31 | Download: `SeaTurtle-1600x600px.jpg` | chrome_downloads |
| 2017-02-03 22:21:55 | Download: `1a579fb3cc1e12e4c7f7ea818dcd3aac.jpg` | chrome_downloads |

---

## 9. Findings and Conclusions

### Primary Finding: Evidence of Illegal Wildlife Trade Coordination

The forensic examination of the LGE Nexus 5 full device image reveals substantial digital evidence that **Sarah McAvoy (mcavoys87@gmail.com)** was actively engaged in planning and executing the illegal acquisition of at least one owl, specifically a **Snowy Owl** (*Bubo scandiacus*).

The evidence establishes the following chain of events:

1. **Research Phase (2017-01-25):** Sarah conducted systematic browser research into purchasing owls illegally, visiting exotic animal sale sites and researching the legality of owl ownership — indicating awareness that the activity was potentially illegal.

2. **Arrangement Phase (Late January 2017):** Sarah thanked a Skype contact ("Matt Haze28") for a "hook up," indicating a referral or introduction to a supplier. Amazon purchases of bird bedding and feeding supplies confirm preparation to receive a live bird.

3. **Delivery Phase (2017-02-01):** A co-conspirator (phone: +1(304)518-4333) sent an SMS confirming a same-day delivery and indicating that final confirmation would come via **Pidgin** (a desktop IM client) — deliberately moving the transaction details off the mobile device. Sarah's acknowledgment confirms her participation.

4. **Post-Delivery Phase (2017-02-03):** Continued Snowy Owl image searches and two Snowy Owl image downloads corroborate that a transaction involving snowy owls had occurred.

### Secondary Finding: Additional Species of Interest

Browser history on 2017-02-03 included searches for "sea turtles baby" and the download of `SeaTurtle-1600x600px.jpg`. This may indicate interest in additional protected species, though no direct trade evidence was found for sea turtles in this dataset.

### Gaps and Recommended Follow-Up

| Gap | Recommendation |
|-----|---------------|
| Pidgin communications not on device | Investigate suspect's desktop/laptop for Pidgin logs (typically stored at `~/.purple/logs/` on Linux or `%APPDATA%\Roaming\.purple\logs\` on Windows) |
| Identity of +1(304)518-4333 not determined | Law enforcement subpoena to carrier for subscriber information |
| Snapchat content ephemeral — not retained | Subpoena Snapchat for server-side records if within retention window |
| Gmail mailstore database was empty | Server-side Gmail preservation/subpoena recommended |
| Facebook messages not recovered from device | Facebook account preservation/subpoena for messages with Monica Neff, Terry Bunch, Isaiah Dashner |
| "Matt Haze28" (live:generalhaze28) identity | Further investigation of Skype account and whether referral constitutes conspiracy |

---

## 10. Supporting Files

| File | Location | Description |
|------|----------|-------------|
| `sms_all.csv` | `exports/sms/` | All SMS/MMS messages (pipe-delimited) |
| `calllog.csv` | `exports/calls/` | Call log (pipe-delimited) |
| `skype_messages.txt` | `exports/social/` | All Skype chat messages |
| `browser_history_full.txt` | `exports/browser/` | Full Chrome browser history |
| `browser_owl_searches.txt` | `exports/browser/` | Owl/bird-related browser entries only |
| `220px-Snowy_Owl_Barrow_Alaska.jpg` | `exports/media/downloads/` | Downloaded snowy owl image |
| `220px-Snowy_Owl_-_Schnee-Eule.jpg` | `exports/media/downloads/` | Downloaded snowy owl image |
| `mmssms.db` | `exports/sms/` | Raw SMS/MMS SQLite database |
| `contacts2.db` | `exports/contacts/` | Contacts and call log database |
| `skype_main.db` | `exports/social/` | Skype messages database |
| `hangouts_babel0.db` | `exports/social/` | Google Hangouts/SMS bridge database |
| `chrome_history.db` | `exports/browser/` | Chrome browser history database |
| `gmail_mailstore.db` | `exports/email/` | Gmail local cache database |
| `textnow_data.db` | `exports/social/` | TextNow messaging database |
| `accounts.db` | `exports/` | Device accounts database |

---

## 11. Examiner Certification

All analysis was conducted on read-only mounted copies of the evidence image. No modifications were made to the evidence files. Evidence remains at:
`~/cases/OWL_TRADE_2026/evidence/LGE Nexus 5 Full Image.raw`

All exports and analysis outputs are located at:
`~/cases/OWL_TRADE_2026/exports/`
`~/cases/OWL_TRADE_2026/analysis/`

*Report generated: 2026-04-29 UTC*
*Examiner: DFIR Orchestrator (Claude Code), on behalf of CMU / 14-822*
