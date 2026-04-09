# Week 3 Day 4 - DNS Analysis (C2 + Exfiltration)

This module captures my Week 3 Day 4 learning on DNS-based detection, command-and-control (C2) patterns, and how to think about DNS exfiltration like a SOC analyst.

## Day Objective

Today I focused on identifying suspicious DNS behavior in mixed normal and botnet traffic.

By the end of Day 4, I wanted to be able to:

- Identify top DNS talkers in a PCAP
- Separate DNS infrastructure details from actual queried domains
- Recognize suspicious domain and subdomain patterns
- Detect possible beaconing behavior
- Explain how DNS tunneling or exfiltration would appear in traffic

## Concept in Practical Terms

DNS is not just a lookup protocol.

Attackers can abuse DNS to:

- Hide C2 communication
- Blend into normal outbound traffic
- Exfiltrate data through encoded subdomains

The key mindset shift for me was this:

Normal DNS usually looks human and irregular.
Malicious DNS often looks automated and patterned.

## Lab Setup

Dataset used:

- Stratosphere IPS Project
- Malware Capture Facility Project
- `CTU-Malware-Capture-Botnet-42`
- PCAP file: `botnet-capture-20110810-neris.pcap`

Wireshark starting filter:

```text
dns
```

## Investigation Workflow and Answers

### 1. Basic DNS Overview

- Top querying host: `147.32.84.165`
- DNS server heavily queried: `147.32.80.9`

Important correction I learned:

- `147.32.80.9` is an IP address (resolver infrastructure), not a domain
- Domain-focused analysis should pivot to `dns.qry.name` values

### 2. Suspicious Domains

Initial suspicious examples I flagged:

- `a.956.22.com`
- `nocomcom.com`

SOC-quality refinement:

- These examples are weak evidence on their own
- A domain is not suspicious just because it "sounds weird"
- I need structural indicators: long labels, high entropy, encoded strings, and repeated changing subdomains under one base domain

### 3. Frequency Analysis

What I checked:

- Source activity volume
- Repeated DNS request behavior

Workflow improvement:

- Use `Statistics -> Endpoints -> IPv4` and `Statistics -> Conversations` in Wireshark for fast host-level aggregation
- Wireshark packet view is good for deep inspection, but endpoint statistics are better for top talker and frequency triage

### 4. C2 Behavior Detection

What I looked for:

- Same domain queried repeatedly
- Regular timing patterns from one source host

Key correction:

- Repeated queries to a DNS server IP are not the same as beaconing to a C2 domain
- Beaconing detection should be based on repeated `dns.qry.name` patterns, timing regularity, and source consistency

### 5. Advanced Challenge - DNS Exfiltration Thinking

If data is being exfiltrated over DNS, I would expect:

- Very long query names, often with long subdomains
- High-entropy or encoded-looking labels (for example base64-like strings)
- Many unique subdomains targeting the same base domain
- High request rates from one internal host

SOC-level detection logic I can implement:

- Alert when query length exceeds a threshold (for example > 50 characters)
- Alert when one host sends excessive DNS queries in a short correlation window
- Alert when unique-subdomain count to one base domain spikes
- Alert when query intervals are highly regular (possible automation/beaconing)

## Detection Engineering Upgrade

My final detection statement for C2 and exfiltration:

Malicious DNS traffic differs from normal traffic by showing long, high-entropy subdomains, high query frequency, and repeated queries to the same base domain with varying subdomains. I would detect this by thresholding query length and per-host frequency, then correlating unique-subdomain behavior and timing regularity to identify DNS tunneling or C2.

## Skills Demonstrated

- DNS-focused PCAP triage in Wireshark
- Domain vs infrastructure distinction (domain names vs resolver IPs)
- Suspicious-domain quality assessment beyond intuition
- Beaconing detection using behavior and timing patterns
- DNS exfiltration hypothesis building using measurable indicators

## Key Terms

- DNS beaconing: repeated, often regular DNS requests associated with malware C2 checks
- DNS tunneling: using DNS queries/responses to carry data covertly
- Entropy: measure of randomness; high entropy can indicate encoded or generated data
- Correlation window: defined time range used to group events for detection logic
- Detection coverage: how well rules monitor attacker techniques across scenarios
- Alert fatigue: reduced analyst effectiveness due to high volumes of low-quality alerts

## My Takeaways

What clicked for me today:

- I have to separate DNS infrastructure artifacts from actual suspicious domains
- Strong DNS detections are behavior-based, not based on "looks suspicious"
- Frequency, structure, and timing together are much stronger than one indicator alone
- SOC-ready answers need thresholds and patterns that can actually be implemented

## Next Up

Week 3 Day 5 - Flow analysis with Zeek for scalable detection and host behavior correlation.
