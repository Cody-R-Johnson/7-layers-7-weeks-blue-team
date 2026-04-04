# Week 3 Day 1 - Your First SOC-Style PCAP Investigation

This module captures my Week 3 Day 1 learning on packet analysis with Wireshark, stream reconstruction, and detection-focused thinking.

## Day Objective

Today I focused on analyzing a packet capture (PCAP) like a SOC analyst, not just identifying protocols.

By the end of Day 1, I wanted to be able to:

- Identify client and server roles in HTTP traffic
- Investigate HTTP requests and downloaded content
- Follow TCP streams to inspect raw transferred data
- Extract transferred files from packet data
- Translate observations into detection ideas for Suricata and Zeek

## Lab Setup

PCAP used:

- `http_with_jpegs.cap` from Wireshark Sample Captures

Why this PCAP is useful:

- Contains HTTP traffic over TCP
- Includes file transfer activity (images)
- Supports stream reconstruction and object extraction practice

## Concept in Practical Terms

In this lab, I practiced the shift from packet reading to SOC investigation logic.

That means I am not only asking, "What traffic exists?" I am also asking:

- Could this traffic be abused?
- What evidence would increase confidence of malicious behavior?
- What should be logged and alerted on in production monitoring?

This mindset matters because normal-looking traffic can still carry malware, command-and-control behavior, or hidden exfiltration.

## SOC Scenario

I am acting as a SOC analyst reviewing outbound web traffic after concern that data may be transferred or hidden inside normal HTTP sessions.

## Investigation Workflow and Answers

### 1. Identify Basic Traffic

Questions answered:

- Main protocol used: TCP with HTTP application traffic
- Client IP: `10.1.1.1`
- Server IP: `10.1.1.101`

### 2. Analyze HTTP Requests

Using an `http` display filter, I reviewed GET activity and requested objects.

Questions answered:

- Files being downloaded: mostly JPEG content and HTML content
- Anything unusual: no obvious malicious pattern at first glance

"No obvious malicious pattern" does not mean safe. It means I need stronger justification and behavior-based checks before classifying as normal.

### 3. Follow TCP Streams

I used Follow TCP Stream to inspect request and response payloads.

Questions answered:

- Type of content transferred: web content including image data
- Raw file data visible: yes, raw HTTP response content is visible in stream view

### 4. Extract Files from HTTP Objects

Using File -> Export Objects -> HTTP:

- Total files extractable: 18
- Notes: 11 entries included paths
- File types observed: `text/html` and `image/jpeg`

### 5. Detection Thinking

Initial detection ideas were broad, then refined into measurable logic.

## Detection Engineering Upgrade

## Indicators I Would Log

- HTTP response sizes and content-length values
- MIME/content-types such as `image/jpeg` and `text/html`
- Request frequency per client and per destination
- URI and path patterns over time
- Repeated retrieval of the same objects

## What Would Trigger Alerts

- Excessive image downloads from one host in a short correlation window
- Large JPEG transfers inconsistent with expected browsing behavior
- High-frequency, regular-interval HTTP GET requests (possible automation/beaconing)
- Same file name requested repeatedly with changing file size
- Internal host activity that looks scripted instead of user-driven browsing
- Outbound transfer to unknown or unapproved destinations

## Suricata and Zeek Monitoring Focus

Suricata mindset:

- Alert when `content-type` is `image/jpeg` and transfer size exceeds threshold
- Alert on burst patterns such as repeated GETs to one host per minute

Zeek mindset:

- Use `http.log` for request timing, URI, and user-agent patterns
- Use `files.log` for file type, size, and transfer repetition analysis

## Mini Challenge Reflection - Steganography Thinking

Question: If an attacker wanted to hide data in this PCAP using images, how might they do it and how would I detect it?

My answer:

An attacker could hide data inside image files using steganography, such as modifying pixel least significant bits, appending encoded data to image payloads, or abusing metadata fields.

I would look for:

- Image size anomalies relative to expected resolution/content
- Repeated downloads at fixed intervals (possible command-and-control or chunked transfer)
- High-entropy image files compared with normal baselines
- Behavior mismatches where image traffic appears automated and lacks normal browsing context
- Same image path delivered with unusual size variation over time

## Skills Demonstrated

- Packet-level HTTP investigation
- Stream reconstruction using TCP flow analysis
- HTTP object extraction and artifact counting
- Translation of findings into detection logic
- Defensive thinking about abuse of legitimate protocols

## Key Terms

- PCAP: packet capture file containing recorded network traffic
- Stream reconstruction: rebuilding application data from packet sequences
- HTTP object extraction: recovering transferred files from HTTP sessions
- Steganography: hiding data inside benign-looking files (for example, images)
- Correlation window: time range used to group related events for detection
- Detection coverage: how well monitoring logic can identify known suspicious behaviors

## My Takeaways

What clicked for me today:

- I can navigate packets, streams, and extracted objects with more confidence
- "Looks normal" is not enough without evidence-based justification
- Better SOC answers are specific, measurable, and actionable
- Detection quality depends on behavior patterns, not just file extensions

## Next Up

Week 3 Day 2 - Zeek network monitoring and log-driven investigation at scale.