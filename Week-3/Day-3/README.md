# Week 3 Day 3 - IDS Detection with Suricata

This module captures my Week 3 Day 3 learning on Suricata, signature-based detection, and how to tune rules so they detect behavior instead of generating noisy alerts.

## Day Objective

Today I focused on writing and testing IDS rules, then improving them to reduce false positives.

By the end of Day 3, I wanted to be able to:

- Run Suricata against a PCAP and review alerts
- Understand how a Suricata rule is structured
- Write a basic custom HTTP detection rule
- Explain why one alert does not always equal one suspicious event
- Improve detection logic with thresholds and behavior context

## Concept in Practical Terms

Suricata is signature-based detection.

The mindset is:

If this pattern happens, trigger an alert.

This is powerful, but also risky if rules are too broad. A rule that matches common traffic patterns can flood a SOC with noise and hide real threats.

## Lab Setup

PCAP reused:

- `http_with_jpegs.cap`

Baseline Suricata run:

```bash
suricata -r http_with_jpegs.cap -l output/
cat output/fast.log
```

Custom rule testing workflow:

```bash
suricata -r http_with_jpegs.cap -S local.rules -l output/
cat output/fast.log
```

## Investigation Workflow and Answers

### 1. Baseline Alert Check

Initial lesson:

- Default rule sets often produce minimal or no alerts for normal traffic
- That is expected and highlights why custom detection engineering is important

### 2. First Custom Rule

Rule used:

```text
alert http any any -> any any (msg:"JPEG Download Detected"; content:"image/jpeg"; sid:100001; rev:1;)
```

My result:

- Alerts generated: 24
- File perspective: about 5 images observed

Key observation:

The alert count did not match image count.

Why:

- IDS rules match packet or stream patterns, not clean human events
- A single file transfer can trigger multiple matches depending on packetization, headers, and repeated content conditions

### 3. False Positive Problem and Rule Tuning

My first tuning idea was to alert when the same source sends many requests and exclude normal traffic.

SOC refinement:

That direction is correct, but it needs measurable rule logic to be useful.

## Detection Engineering Upgrade

### Why the Basic Rule Was Too Broad

Matching only `content:"image/jpeg"` can trigger repeatedly on benign traffic and does not represent malicious behavior on its own.

### Better Rule Pattern

A stronger starting point is to add flow context and thresholding.

```text
alert http any any -> any any (
msg:"Possible Excessive JPEG Downloads";
flow:to_server,established;
http.header;
content:"image/jpeg";
threshold:type both, track by_src, count 5, seconds 60;
sid:100002;
rev:1;
)
```

Why this is better:

- Restricts matching to established HTTP flow direction
- Focuses on repeated behavior from one source, not one-off content
- Reduces noisy single-event alerts

### Evasion Challenge and Outcome

Challenge question:

Would the rule still work if attacker changes `image/jpeg` to `application/octet-stream`?

My answer:

- No, the content-type specific rule can be evaded

Improved detection mindset:

Do not rely on one content type. Detect protocol-agnostic behavior patterns:

- High outbound volume over HTTP
- High request frequency from one source
- Repeated connections to same destination
- Regular request timing that suggests automation
- Similar transfer-size patterns consistent with chunking

## Progressive Exercises Completed

### 1. Basic

Detect HTTP GET requests by matching request method and HTTP flow context.

### 2. Intermediate

Detect requests to `/dagbok` by matching URI content.

### 3. Detection Thinking

Detect repeated requests to the same URI using thresholding by source.

### 4. Real-World Scenario

Model possible image-based exfiltration using frequency, volume, and destination repetition instead of only MIME match.

### 5. Challenge

Draft suspicious user-agent detection rule logic (even if no malicious user-agent appears in this PCAP).

## SOC-Quality Detection Logic Summary

My improved answer:

If attackers change headers or content-type, I should shift from static signature-only logic to behavior-based logic. I would monitor repeated HTTP transfers from the same source, outbound byte volume over time, destination concentration, and automated interval patterns. This approach is more resilient to evasion and reduces false positives compared with single-indicator matching.

## Skills Demonstrated

- Running Suricata with baseline and custom rule sets
- Writing first IDS signatures for HTTP content and URI patterns
- Interpreting alert-volume mismatch versus actual files
- Applying thresholding to reduce false positives
- Adapting detection logic for header/content-type evasion

## Key Terms

- Intrusion Detection System (IDS): tool that monitors traffic and generates alerts for suspicious patterns
- Signature-based detection: matching known patterns in traffic to trigger alerts
- Rule tuning: refining detection logic to reduce false positives and improve quality
- Thresholding: alert control based on count and time windows
- False positive: benign activity incorrectly flagged as malicious
- Evasion: attacker technique to bypass detection logic
- Alert fatigue: reduced analyst effectiveness caused by too many low-quality alerts

## My Takeaways

What clicked for me today:

- A basic rule can work technically but still be poor operationally
- One file transfer can generate multiple IDS hits, so raw alert count needs context
- Strong rules combine flow context, thresholds, and behavior logic
- Signature-only detection is not enough against adaptive attackers
- Real SOC detection quality depends on precision, not rule quantity

## Next Up

Week 3 Day 4 - DNS analysis for command-and-control and data exfiltration patterns.