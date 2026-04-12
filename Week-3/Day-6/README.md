# Week 3 Day 6 - Advanced Detection Engineering (Suricata)

This module captures my Week 3 Day 6 learning on multi-condition detection engineering in Suricata, including how to resist attacker evasion and reduce false positives.

## Day Objective

Today I focused on moving from single-indicator rules to layered, behavior-aware detections.

By the end of Day 6, I wanted to be able to:

- Explain why basic content-only rules are easy to bypass
- Build Suricata rules that combine flow, behavior, and context
- Detect potential HTTP beaconing with threshold logic
- Improve a rule to reduce false positives
- Evaluate whether my rule survives low-and-slow evasion

## Concept in Practical Terms

Basic rules are brittle.

If I alert only on one static indicator like content type or one string, an attacker can change that field and bypass detection. Strong detection engineering uses layered logic that is harder to evade:

- Flow: where traffic is going and connection state
- Behavior: repetition, timing, and frequency
- Context: protocol field, URI, user-agent, or destination scope

The mindset shift for me today:

I should detect attacker behavior patterns, not just one value in one packet.

## Why Basic Rules Fail

A basic rule like `content:"image/jpeg"` can be bypassed by:

- Changing headers
- Using a different MIME type
- Encoding data differently
- Blending traffic through legitimate-looking infrastructure

Attackers can also use low-and-slow patterns to stay under threshold limits.

## Evasion Thinking

Common evasion techniques I modeled today:

- Rotating or spoofing User-Agent values
- Modifying Content-Type
- Using legitimate domains and cloud infrastructure
- Slowing beacon intervals to avoid count-based alerts

This is why multi-condition logic matters in SOC triage. It improves detection coverage while controlling alert fatigue.

## Rule Design Strategy

I used this layered structure:

1. Flow control:

```suricata
flow:to_server,established;
```

2. Behavioral threshold:

```suricata
threshold:type both, track by_src, count 5, seconds 180;
```

3. Context field selection:

- `http.method; content:"GET";`
- `http.user_agent; content:"curl";`
- Optional URI scoping for stronger precision

## Lab - My Detection Rules

### 1. Basic Exercise: Detect all HTTP GET requests

```suricata
alert http any any -> any any (
msg:"HTTP GET request observed";
flow:to_server,established;
http.method; content:"GET";
sid:100060;
rev:1;
)
```

### 2. Intermediate Exercise: Detect requests to /dagbok

```suricata
alert http any any -> any any (
msg:"HTTP request to /dagbok";
flow:to_server,established;
http.uri; content:"/dagbok";
sid:100061;
rev:1;
)
```

### 3. Advanced Exercise: Repeated requests from one source

```suricata
alert http any any -> any any (
msg:"Repeated HTTP requests from same source";
flow:to_server,established;
threshold:type both, track by_src, count 10, seconds 60;
sid:100062;
rev:1;
)
```

### 4. Real-World Exercise: Possible beaconing with context

```suricata
alert http any any -> any any (
msg:"Possible HTTP Beaconing Activity - repeated curl check-ins";
flow:to_server,established;
http.method; content:"GET";
http.user_agent; content:"curl";
threshold:type both, track by_src, count 5, seconds 180;
sid:100063;
rev:1;
)
```

### 5. Expert Direction: Low-and-slow resilience

If attackers beacon every 2 minutes, a short rule window can miss them.

A stronger tuning option is:

```suricata
alert http any any -> any any (
msg:"Possible low-and-slow HTTP beaconing";
flow:to_server,established;
http.method; content:"GET";
threshold:type both, track by_src, count 5, seconds 900;
sid:100064;
rev:1;
)
```

This is still imperfect alone, so in production I would pair it with longer-term behavioral correlation in SIEM.

## Scenario-Based Q&A

### Q1. Would my original rule detect slow beaconing?

Original idea:

```suricata
alert http any any -> any any (
msg:"Possible HTTP Beaconing Activity";
flow:to_server,established;
http.method; content:"curl";
threshold:type both, track by_src, count 5, seconds 180;
sid:100010;
rev:1;
)
```

My answer:

No, not reliably. It can miss low-and-slow beacons because the threshold window is tight.

### Q2. What is the correction I learned?

- `http.method` should match values like `GET` or `POST`
- `curl` belongs in `http.user_agent`, not `http.method`

### Q3. How would I adapt for evasion?

- Extend correlation window (for example 10 to 15 minutes)
- Lower count where justified by baseline
- Add contextual filters such as URI pattern or destination scope
- Correlate repeated periodicity over longer time ranges in SIEM

## Detection Engineering Reflection

What improved in my logic today:

- I matched indicators to the correct protocol fields
- I designed rules around behavior plus context instead of one string
- I considered adversary adaptation up front (especially low-and-slow)
- I treated false-positive control as part of detection quality, not a later cleanup task

## Skills Demonstrated

- Writing multi-condition Suricata rules
- Applying threshold-based behavioral detection
- Using protocol-aware field selection (`http.method`, `http.user_agent`, `http.uri`)
- Tuning logic for evasion resistance
- Balancing detection coverage with practical SOC signal quality

## Key Terms

- Multi-condition detection: combining multiple indicators (behavior + context) in one rule
- Thresholding: triggering alerts based on event count in a defined time window
- Low-and-slow: attacker behavior spread over longer intervals to avoid rate-based detection
- Evasion resistance: ability of a detection to remain effective when attacker tactics change
- Correlation window: time interval used to group related events for alert logic
- Alert fatigue: reduced analyst effectiveness due to excessive low-value alerts

## My Takeaways

What clicked for me today:

- Single-condition rules are easy to evade
- Correct protocol field usage is critical for rule quality
- Repetition and timing are high-value behavioral signals
- Strong detections need both coverage and false-positive control
- Low-and-slow behavior requires wider windows and cross-event correlation

## Next Up

Week 3 Day 7 - False Positives and Tuning (Suricata).