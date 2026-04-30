# Email Harassment Forensic Analysis Report

## Executive Summary

This forensic analysis examines network capture files from the Email_Harassment case folder. The investigation reveals **clear evidence of email harassment** originating from an internal network host. Two threatening emails were sent to a victim using anonymous email services, with the perpetrator's activity fully traceable through network traffic analysis.

---

## Evidence Files Analyzed

| File | Size | Description |
|------|------|-------------|
| `nitroba.pcap` | 56.2 MB | Primary evidence - contains harassment activity |
| `mycapture.pcap` | 14.8 KB | RDP traffic between internal hosts |
| `mycapture10_10_81_0.pcap` | 8.6 KB | RDP session continuation |
| `mycapture10_10_81.75.pcap` | 1.3 KB | RDP session traffic |
| `ubalt.pcap` | 217.8 KB | HTTP traffic to University of Baltimore |

---

## Critical Findings

### 1. Suspect Machine Identification

| Attribute | Value |
|-----------|-------|
| **AOL/AIM Username** | `m57jean` |
| **Internal IP Address** | `192.168.1.64` |
| **External IP (NAT)** | `70.134.91.12` |
| **MAC Addresses** | `00:1d:6b:99:98:68`, `00:1d:d9:2e:4f:61` |
| **Operating System** | Windows NT 5.1.0.2600 (Windows XP SP2) |
| **Browser** | Internet Explorer 6.0 |
| **Device ID** | `AFE626E1-58E0-465A-83E4-28D58FE33959` |
| **Activity Timeframe** | July 22, 2008, approximately 01:51 - 06:13 UTC |

### 2. Victim Information

| Attribute | Value |
|-----------|-------|
| **Email Address** | `lilytuckrige@yahoo.com` |
| **Affiliation** | Nitroba University (instructor) |

### 3. Threatening Emails Sent

#### Email #1 - Via SendAnonymousMail.net
- **Timestamp**: July 22, 2008 ~07:21 GMT
- **Service Used**: `www.sendanonymousemail.net`
- **Sender Field**: `the_whole_world_is_watching@nitroba.org`
- **Subject**: `Your class stinks`
- **Message Body**:
  ```
  Why do you persist in teaching a boring class?

  We don't like it.

  We don't like you.
  ```
- **POST Request Evidence**:
  ```
  POST /send.php HTTP/1.1
  Host: www.sendanonymousemail.net
  Cookie: PHPSESSID=762adba03236142ccec305f6a20aaffa

  email=lilytuckrige@yahoo.com&sender=the_whole_world_is_watching@nitroba.org
  &subject=Your+class+stinks&message=Why+do+you+persist+in+teaching+a+boring+class...
  ```

#### Email #2 - Via WillSelfDestruct.com
- **Timestamp**: Shortly after Email #1
- **Service Used**: `www.willselfdestruct.com`
- **Subject**: `you can't find us`
- **Message Body**:
  ```
  and you can't hide from us.

  Stop teaching.

  Start running.
  ```
- **POST Request Evidence**:
  ```
  POST /secure/submit HTTP/1.1
  Host: www.willselfdestruct.com

  to=lilytuckrige@yahoo.com&from=&subject=you+can%27t+find+us
  &message=and+you+can%27t+hide+from+us.%0D%0A%0D%0AStop+teaching.%0D%0A%0D%0AStart+running.
  ```

---

## Incriminating Search Queries

The following searches were captured from the suspect's machine, demonstrating **premeditation and criminal intent**:

| Search Query | Search Engine | Significance |
|--------------|---------------|--------------|
| "i want to harass my teacher" | Google | **Direct admission of intent** |
| "can I go to jail for harassing my teacher?" | Yahoo Answers | **Awareness of criminal nature** |
| "send anonymous mail" | Google | Seeking anonymous methods |
| "sending anonymous mail" | Google | Seeking anonymous methods |
| "how to annoy people" | Google | Hostile intent |

---

## Timeline of Suspicious Activity

| Time (UTC) | Activity |
|------------|----------|
| ~01:51 | Network capture begins |
| ~06:01 | Suspect searches Google for "send anonymous mail" |
| ~06:01:50 | Redirected to sendanonymousemail.net |
| ~07:21:37 | Accesses sendanonymousemail.net website |
| ~07:23:16 | **Sends Email #1** via sendanonymousemail.net |
| Shortly after | Searches Yahoo Answers: "can I go to jail for harassing my teacher?" |
| Shortly after | Accesses willselfdestruct.com via about.com directory |
| Shortly after | **Sends Email #2** via willselfdestruct.com |

---

## Network Analysis

### IP Conversations (Top Sources)
- Primary suspect traffic from `192.168.1.64` to various destinations
- Secondary host `192.168.15.4` with web browsing activity
- VoIP traffic from `192.168.1.64` to Vonage service (`t.voncp.com`)

### Protocols Identified
- HTTP (Port 80) - Primary browsing activity
- HTTPS (Port 443) - Gmail, Google services
- DNS (Port 53) - Domain lookups
- SIP/RTP - VoIP communications via Vonage
- SSDP/UPnP - Network discovery

### Key Domains Accessed from Suspect IP
- `www.google.com` (search queries)
- `www.sendanonymousemail.net` (anonymous email service)
- `www.willselfdestruct.com` (self-destructing email service)
- `mail.google.com` (Gmail access)
- `nitroba.org` (victim's organization)

---

## Additional Forensic Artifacts

### User-Agent String
```
Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)
```
This identifies an Internet Explorer 6 browser on Windows XP SP1.

### Session Identifiers
- PHP Session ID: `762adba03236142ccec305f6a20aaffa` (sendanonymousemail.net)

### VoIP Activity
- Phone number registered: `16178766111`
- VoIP Provider: Vonage (`t.voncp.com`)
- This provides additional identifying information for the suspect machine.

---

## Other PCAP File Analysis

### mycapture*.pcap Files
These files contain **Remote Desktop Protocol (RDP)** traffic:
- Source: `10.10.81.75` (internal workstation)
- Destination: `136.160.215.15:3389` (RDP server)
- Encrypted RDP session data captured

### ubalt.pcap
Contains legitimate web browsing to:
- University of Baltimore website (`ubalt.edu`, IP: `204.52.129.211`)
- Standard HTTP/HTTPS traffic
- No suspicious activity detected

---

## Conclusions

1. **The harassment emails originated from IP address `192.168.1.64`** on the internal network, with external NAT IP `70.134.91.12`.

2. **The perpetrator deliberately used anonymous email services** to attempt to hide their identity, first using sendanonymousemail.net, then willselfdestruct.com.

3. **The attack was premeditated** - Google search evidence shows the perpetrator actively searched for anonymous email services before sending the threats.

4. **Both emails were threatening in nature**, with the second email containing more aggressive language ("Stop teaching. Start running.").

5. **The victim was a Nitroba University instructor** (lilytuckrige@yahoo.com) being harassed about their teaching.

6. **The perpetrator used "the_whole_world_is_watching@nitroba.org"** as a fake sender, suggesting they may be affiliated with Nitroba University.

---

## Recommendations

1. **Identify the user "m57jean"** - This AOL/AIM username was found in sync traffic and should be subpoenaed from AOL for account holder information.

2. **Identify the user of workstation 192.168.1.64** through DHCP logs, Active Directory records, or physical asset inventory.

3. **Preserve all evidence** including this pcap file and any related system logs.

4. **Contact law enforcement** as the second email contains threatening language that may constitute criminal harassment or threats.

5. **Review VoIP records** for phone number 617-876-6111 for additional identification.

6. **MAC address lookup** - The MAC addresses 00:1d:6b:99:98:68 and 00:1d:d9:2e:4f:61 may help identify the physical network adapter.

7. **Document chain of custody** for all evidence files.

---

## Extracted Evidence Files

All raw evidence has been extracted to the `extracted_evidence/` directory:

| File | Description |
|------|-------------|
| `harassment_evidence_summary.txt` | Complete summary of all findings |
| `email_addresses.txt` | All email addresses found (165 unique) |
| `critical_search_queries.txt` | Incriminating search queries |
| `user_identifiers.txt` | User accounts and identifiers |
| `hosts_accessed.txt` | All websites accessed |
| `urls.txt` | All URLs extracted (3,027) |
| `cookies.txt` | Session cookies and identifiers |
| `ip_addresses.txt` | All IP addresses (435 unique) |
| `mac_addresses.txt` | MAC addresses captured |
| `http_requests.txt` | HTTP GET/POST requests |
| `session_ids.txt` | Session identifiers |

---

*Report Generated: February 19, 2026*
*Case: Email Harassment Investigation*
*Evidence Location: /home/sansforensics/Documents/Email_Harassment/data/*
*Extracted Evidence: /home/sansforensics/Documents/Email_Harassment/data/extracted_evidence/*
