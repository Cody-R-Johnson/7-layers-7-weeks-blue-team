# Week 3 Day 2 - Network Monitoring with Zeek

This module captures my Week 3 Day 2 learning on log-driven network analysis using Zeek, and how to investigate traffic behavior without relying on raw packet data.

## Day Objective

Today I shifted from packet-level analysis to log-based detection, which is closer to how a real SOC actually operates day to day.

By the end of Day 2, I wanted to be able to:

- Run Zeek against a PCAP and generate structured logs
- Navigate and extract meaningful fields from conn.log, http.log, and files.log
- Identify the top-talking hosts and most common services
- Correlate multiple logs to build an investigation chain
- Translate behavioral patterns into actionable detection logic

## Concept in Practical Terms

The key mindset shift today was understanding that in a real SOC, I usually do not start with a PCAP.

I start with logs.

"What behavior stands out across thousands of connections?"

Zeek turns raw traffic into structured, queryable logs that let me analyze behavior at scale without needing to inspect individual packet payloads.

| Packet Analysis (Wireshark) | Log-Based Analysis (Zeek) |
| --- | --- |
| What is inside this packet? | What behavior stands out? |
| Granular and low-level | Summarized and scalable |
| Best for deep dives | Best for detection at scale |

## Lab Setup

PCAP reused from Day 1:

- `http_with_jpegs.cap`

Zeek command used:

```bash
zeek -r http_with_jpegs.cap
```

This generates structured log files in the working directory.

## Key Zeek Logs

- `conn.log`: connection records with source/destination IPs, protocol, service, duration, and byte counts
- `http.log`: web request activity including host, URI, user-agent, method, and status codes
- `dns.log`: domain lookup records
- `files.log`: transferred file metadata including MIME type, size, and source

## Investigation Workflow and Answers

### 1. Basic Traffic Summary

- Host making the most connections: `10.1.1.101`
- Most common service: HTTP

SOC note: I flagged `10.1.1.101` as the top talker, then went back to verify whether that host was the client or the server. In most HTTP sessions the server generates high response byte counts, so the suspicious actor to watch is usually the client making the requests, not the destination responding to them.

### 2. HTTP Investigation

Domains contacted:

- `websidan`
- `servedby.advertising.com`

URIs requested:

- `http://10.1.1.1/websidan/index.html`
- `/dagbok`

SOC note: `servedby.advertising.com` looks like standard ad traffic, but in a real environment I would verify whether this domain is expected, first-seen, or associated with any threat intel. Domain rarity matters more than domain appearance.

### 3. File Analysis

- File types transferred: `image/jpeg`, `text/html`
- Largest file size: 191,515 bytes (approximately 187 KB)

### 4. Detection Thinking

The correct approach is detecting the behavior directly in Zeek logs without reprocessing raw captures unless absolutely necessary.

### 5. Real SOC Scenario - Possible HTTP Exfiltration

Using only logs:

- Source host: `10.1.1.1`
- Destination: `10.1.1.101`
- Data type: `image/jpeg` and `text/html` per `files.log`
- Volume: tracked via `orig_bytes` in `conn.log`

## Detection Engineering Upgrade

### Fields to Monitor

From `conn.log`:

- `id.orig_h`: source host
- `id.resp_h`: destination host
- `orig_bytes`: data sent outbound
- `resp_bytes`: data received
- `duration`: connection length

From `http.log`:

- `host`
- `uri`
- `user_agent`
- `method` (GET vs POST)

From `files.log`:

- `mime_type`
- `seen_bytes`
- `source`

### Alert Thresholds (SOC-Level)

Rather than a simple "alert if over 1MB in one minute," stronger detection logic accounts for behavioral patterns:

- Repeated HTTP GET requests from one source to one destination in a short window
- High total `orig_bytes` per host over a rolling time period
- Excessive transfers of `image/jpeg` MIME type suggesting possible steganography or bulk staging
- Fixed-interval requests indicating automated behavior rather than user-driven browsing
- Same URI or filename requested multiple times, especially with varying file sizes

## Mini Challenge Reflection - Investigation Chain

Question: If this were data exfiltration, which log would prove it fastest and which field would you use?

My initial answer: `conn.log` because it shows data sent and received.

SOC refinement:

`conn.log` is the correct starting point, but on its own it only shows that something suspicious happened, not what was transferred.

The full investigation chain is:

1. `conn.log` to detect the anomaly — high `orig_bytes` or repeated connections flag suspicious volume
2. `files.log` to validate the data type — `mime_type` and `seen_bytes` confirm what was actually transferred
3. `http.log` for context and intent — `host`, `uri`, and `user_agent` reveal where the data went and how

The single most useful individual field for proving exfiltration is `orig_bytes` in `conn.log`, but the case is only complete when all three logs are correlated.

## Skills Demonstrated

- Generating and navigating Zeek log output
- Identifying top-talking hosts and dominant services
- Extracting domains, URIs, and file metadata from logs
- Correcting workflow direction (logs before PCAPs)
- Building a multi-log investigation chain

## Key Terms

- Zeek: open-source network monitoring framework that converts traffic into structured logs
- conn.log: Zeek log recording connection-level metadata for every network flow
- http.log: Zeek log recording HTTP request and response details
- files.log: Zeek log tracking transferred file metadata such as MIME type and size
- orig_bytes: bytes sent by the originating (source) host in a connection
- MIME type: label identifying the format of transferred content, such as image/jpeg
- Beaconing: regular-interval automated connections indicating possible command-and-control activity

## My Takeaways

What clicked for me today:

- Logs come first in a real SOC — PCAPs are for deep dives, not the default starting point
- `conn.log` is the fastest signal but not the full story
- Good detection logic looks at behavioral patterns, not just single-field thresholds
- Correlating conn.log, files.log, and http.log together is the investigation chain that actually holds up

## Next Up

Week 3 Day 3 - Suricata IDS and writing automated detection rules at scale.
