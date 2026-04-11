# Week 3 Day 5 - Flow Analysis and Beaconing Detection

This module captures my Week 3 Day 5 learning on log-based DNS analysis, flow patterns, and the critical skill of distinguishing normal enterprise behavior from actual malicious beaconing.

## Day Objective

Today I shifted from packet inspection to structured log analysis, learning how to identify automated behavior patterns while avoiding false positives in normal enterprise DNS traffic.

By the end of Day 5, I wanted to be able to:

- Parse Zeek DNS logs using command-line tools
- Identify top DNS talkers and domain frequency patterns
- Recognize Windows Active Directory traffic vs malicious queries
- Detect beaconing through timing and subdomain patterns
- Understand why "weird-looking" does not automatically mean malicious

## Concept in Practical Terms

Log-based detection is how SOC analysts actually work at scale.

The key mindset shift for me today was this:

Normal enterprise DNS often looks complex and unusual when you first see it. GUID-based service discovery, SRV records, and multi-level subdomains are not indicators of compromise—they are baseline infrastructure traffic.

True detection is about recognizing patterns that differ from baseline behavior, not just reacting to unusual appearance.

## Lab Setup

Dataset used:

- Wireshark Sample Captures
- `dns.cap` (lightweight, ~20KB)
- Contains DNS queries with mixed enterprise and external lookups

Zeek execution:

```bash
zeek -r dns.cap
cat dns.log
```

Log parsing workflow:

```bash
cat dns.log | head -20
cat dns.log | cut -f 3,10
cat dns.log | cut -f 3 | sort | uniq -c | sort -nr
```

## Investigation Workflow and Findings

### 1. Top Talker Identification

- Top querying host: `192.168.170.56`
- This host dominated DNS activity

Initial assessment:

This appears to be a Windows machine performing significant DNS work.

### 2. Domain Analysis

Domains observed:

- `isc.org` (external)
- `utelsystems.local` (internal)
- `_ldap._tcp.dc._msdcs.utelsystems.local` (Active Directory service discovery)
- `_ldap._tcp.05b5292b-34b8-4fb7-85a3-8beef5fd2069.domains._msdcs.utelsystems.local` (AD with embedded GUID)

Critical lesson I learned:

Long, complex-looking domain names with GUIDs and service prefixes are standard Active Directory lookups, not exfiltration or C2 indicators.

### 3. Pattern Assessment

What I checked:

- Repetition to single external domain: None observed
- Consistent automated timing: No evidence
- Multiple unique subdomains to one base: Not present
- Encoded or random-looking strings: GUIDs are structured, not encoding

Conclusion:

No beaconing detected. No DNS exfiltration indicators present.

### 4. False Positive Avoidance

Important realization:

Not everything that looks unusual is malicious.

In enterprise environments:

- Service discovery queries are normal
- Multi-level subdomains are expected
- High DNS query volume is expected from certain hosts (domain controllers, member servers)

This is where junior analysts can overalert. Strong detection requires understanding baseline behavior.

### 5. Refined Beaconing Thinking

If this traffic HAD shown beaconing, it would have exhibited:

- Consistent query intervals (every 5s, 10s, or 60s)
- Repeated queries to the same external domain or base domain
- Long or encoded-looking subdomains
- Multiple unique subdomains all pointing to the same domain (data chunking pattern)
- Timing regularity that indicates automation, not user interaction

## Detection Engineering Upgrade

My final detection statement for automated DNS beaconing:

Malicious DNS beaconing differs from normal traffic by exhibiting consistent, automated query intervals, often targeting the same domain or base domain repeatedly. The queries may include long or random-looking subdomains, sometimes encoding data. I would detect this by identifying high-frequency DNS requests from a single host, consistent timing intervals, and patterns of multiple unique subdomains associated with the same domain, which indicate potential C2 communication or data exfiltration.

Key upgrade:

This logic accounts for both the technical indicators AND the understanding that timing regularity and pattern repetition are stronger signals than unusual appearance alone.

## Skills Demonstrated

- Log parsing with command-line tools (cut, sort, uniq)
- DNS traffic analysis at scale without packet inspection
- Recognition of Windows Active Directory DNS patterns
- Beaconing detection through behavioral patterns
- Critical thinking to avoid false positives

## Key Terms

- Beaconing: automated, often regularly-timed DNS requests indicating C2 or malware behavior
- Service discovery: DNS queries used by systems to locate services like domain controllers
- SRV record: DNS record type identifying services and their servers
- GUID: globally unique identifier used by Windows, often seen in Active Directory
- Baseline behavior: normal, expected traffic patterns in an environment
- False positive: benign activity incorrectly flagged as malicious
- Flow analysis: detecting threats through connection patterns and metadata instead of payload inspection

## My Takeaways

What clicked for me today:

- Complex or long-looking domains can be completely normal in enterprise environments
- Timing and consistency are stronger indicators of automation than appearance
- Understanding baseline traffic is as important as knowing attack patterns
- Log-based detection scales better than packet inspection for high-volume environments
- False positive discipline prevents alert fatigue and improves team credibility

## Next Up

Week 3 Day 6 - Advanced detection engineering combining all techniques for multi-layer threat detection.
