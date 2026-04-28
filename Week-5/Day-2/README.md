# Week 5 Day 2 - API Enrichment and Threat Intelligence Integration

This module captures my Day 2 progression from behavior-only detection into context-aware automated triage using threat intelligence enrichment.

## Day Objective

Today I focused on making the detection pipeline more intelligent.

By the end of this day, I wanted to:

- Extract domains from suspicious command lines
- Enrich domains using the VirusTotal API
- Add enrichment context to scoring and analyst output
- Handle API failures safely (timeout and error handling)
- Validate behavior across malicious, clean, and no-domain scenarios

## Concept in Practical Terms

Day 1 pipeline:

1. Process telemetry
2. Behavioral rules
3. Score and verdict

Day 2 pipeline:

1. Process telemetry
2. Behavioral rules
3. Domain extraction
4. VirusTotal enrichment
5. Context-aware scoring and richer verdict output

Key mindset shift:

- Behavior-only answer: "This looks suspicious"
- Enriched answer: "This looks suspicious and is linked (or not linked) to known malicious infrastructure"

## Lab Implementation

I used two components for Day 2:

- analyzer.py: detection and scoring logic
- enrichment.py: API lookup and parsing logic

Core enrichment additions:

- Extract domain from process cmdline (http/https patterns)
- Query VirusTotal domains API using VT_API_KEY from environment variables
- Add score boost when threat intel reports malicious detections
- Include enrichment block in output JSON

## Reference Enrichment Logic

```python
import os
import re
import requests

VT_API_KEY = os.getenv("VT_API_KEY")


def extract_domain(cmdline):
    match = re.search(r"https?://([^/\s]+)", cmdline)
    if match:
        return match.group(1)
    return None


def check_domain_virustotal(domain):
    if not VT_API_KEY:
        return {"error": "Missing VT_API_KEY", "reputation": "unknown"}

    url = f"https://www.virustotal.com/api/v3/domains/{domain}"
    headers = {"x-apikey": VT_API_KEY}

    try:
        response = requests.get(url, headers=headers, timeout=5)
    except requests.RequestException as exc:
        return {"error": str(exc), "reputation": "unknown"}

    if response.status_code != 200:
        return {
            "error": f"API request failed with status {response.status_code}",
            "reputation": "unknown",
        }

    data = response.json()
    stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})

    malicious = stats.get("malicious", 0)
    suspicious = stats.get("suspicious", 0)

    return {
        "malicious": malicious,
        "suspicious": suspicious,
        "reputation": "malicious" if malicious > 0 else "clean",
    }
```

## Scoring and Output Integration

Behavior score baseline remained from Day 1.

Enrichment scoring rule added:

- +4: domain is flagged malicious by VirusTotal

Output structure expanded with enrichment context:

```json
"enrichment": {
  "domain": "...",
  "virustotal": {
    "malicious": 0,
    "suspicious": 0,
    "reputation": "clean"
  }
}
```

## Validated Results

### 1) Malicious Domain Enrichment Test

Scenario:

- cmdline contained malicious-example.com

Observed result:

- Base behavior score: 7
- VT enrichment boost: +4
- Final score: 11
- Verdict: malicious (lab threshold model)
- Enrichment: malicious=1, suspicious=0, reputation=malicious

### 2) Clean Domain Enrichment Test

Scenario:

- cmdline used example.com with risky behavior pattern

Observed result:

- Final score: 7
- No enrichment boost applied
- Verdict: malicious (behavior-driven risk remained high)
- Enrichment: malicious=0, suspicious=0, reputation=clean

### 3) No-Domain Base64 Scenario

Scenario:

- cmdline had base64 decode and no URL

Observed result:

- Final score: 6
- No API call context required
- Enrichment safely returned domain=null and virustotal=null
- No crash or hang observed

## Exercises Completed

- [x] Domain extraction helper
- [x] API integration with VirusTotal
- [x] Conditional enrichment flow
- [x] Timeout + error handling for API requests
- [x] Multi-scenario validation (malicious, clean, no-domain)

## SOC Engineering Notes

Important operational considerations:

- Free API plans have strict rate limits
- Threat intel can include false positives
- External calls add latency to pipelines

Practical SOC logic:

- Do not alert only because VT is malicious
- Use behavior plus intelligence to increase confidence

## Detection Model Characteristics (Day 2)

- Stateless per-event analysis
- Real-time enrichment on extracted domain indicators
- Confidence improved by combining behavior and external intelligence

## Known Limitations

- No hash enrichment yet (planned for later modules)
- No IP enrichment yet in this implementation
- No caching yet (duplicate domains can trigger duplicate API calls)
- No asynchronous enrichment path for high-throughput environments

## Future Improvements

- Add domain lookup caching to reduce API usage and latency
- Add IP and hash enrichment modules
- Introduce confidence tiers separate from raw score
- Add response recommendations (alert, contain, isolate)
- Add fallback queues/retries for API outage scenarios

## Key Terms

- Threat enrichment: adding external intel context to raw detections
- IOC: indicator of compromise (domain, IP, hash)
- Confidence scoring: weighted model strengthened by corroborating data
- Rate limiting: API usage ceiling that constrains enrichment volume
- Timeout handling: defensive control to prevent blocking on slow dependencies

## My Takeaways

- Enrichment improved confidence without replacing behavioral logic.
- Clean intel does not override clearly dangerous execution behavior.
- Robust API error handling is required for production reliability.
- Behavior plus intelligence is stronger than either source alone.

## Day 2 Completion Checklist

- [x] VirusTotal domain enrichment integrated
- [x] Domain extraction from cmdline implemented
- [x] Enriched JSON output added
- [x] Malicious domain score boost validated
- [x] Clean domain no-boost behavior validated
- [x] No-domain scenario handled safely
- [x] Timeout and API error handling added

## Next Up

Week 5 Day 3 - Full SOAR Playbook logic (triage, enrich, and response recommendation workflows).
