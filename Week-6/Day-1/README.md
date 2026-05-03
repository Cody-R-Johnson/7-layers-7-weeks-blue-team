# Week 6 Day 1 - Threat Intelligence Systems (IOC Ingestion and Management)

This day transitions my pipeline from API-only enrichment to a reusable internal intelligence layer.

## Day Objective

Today I built a local threat intelligence system that can:

- Store internal IOCs (domains, IPs, hashes)
- Add local context to detections before API fallback
- Score detections using reputation plus IOC tags
- Cache useful VirusTotal results into local storage
- Ignore stale intel records using expiration logic

The architecture now follows:

Process -> IOC extraction -> Local intel lookup -> Enrichment -> Scoring -> Optional external fallback

## Concept in Practical Terms

Before today, my enrichment flow was reactive:

Process -> extract domain -> query VirusTotal

Now it is intelligence-aware:

Process -> extract IOC -> check local intel DB -> enrich and score -> query external source when needed

This better reflects how real SOC teams operate with internal feeds, past incidents, and analyst-curated IOC knowledge.

## What I Implemented

### 1) Local IOC Database

I used `intel_db.json` as an internal datastore with three IOC collections:

- `domains`
- `ips`
- `hashes`

Each IOC record includes fields such as:

- `reputation`
- `source`
- `confidence`
- `tags`
- `last_seen`

### 2) Local Intel Enrichment Layer

In `intel.py`, I added support to:

- Load and save the intel database
- Lookup domain, IP, and hash IOCs
- Extract IPs and common hash formats (MD5, SHA1, SHA256) from process command lines
- Merge local IOC matches into the existing enrichment object

The enrichment object now carries:

- `local_intel.domain`
- `local_intel.ips[]`
- `local_intel.hashes[]`

### 3) Tag-Based Scoring (Exercise 2)

I extended scoring to increase risk based on intelligence tags:

- `c2` adds score and reason text
- `malware` adds score and reason text
- `phishing` adds score and reason text

This supports context-aware prioritization beyond basic reputation values.

### 4) IP and Hash Detection (Exercise 3)

I extended IOC detection beyond domains:

- IP indicators are extracted from command lines and checked against `ips`
- Hash indicators are extracted and normalized for lookup in `hashes`

This allows detections even when no domain is present.

### 5) VirusTotal Result Caching (Exercise 4)

I added a cache function that stores useful VirusTotal domain reputation into `intel_db.json`:

- Caches only non-empty, meaningful reputation outcomes
- Writes a local IOC record with source tagging and `last_seen`

This turns one-time enrichment into reusable internal intelligence.

### 6) Intel Expiration (Exercise 5)

I implemented age-based expiration using `last_seen`:

- Intel older than 30 days is ignored
- Invalid date format is treated as expired for safety

This keeps scoring and correlation focused on relevant intelligence.

## Validation Results

I validated four test cases through the full pipeline:

1. `malicious-example.com`
2. `203.0.113.50`
3. `44d88612fea8a8f36de82e1278abb02f`
4. `unknown-site.org`

Observed outcomes:

- Domain IOC matching worked with malicious and suspicious reputations
- IP IOC matching worked and added C2 tag scoring
- Hash IOC matching worked and added malware tag scoring
- Local intel still enriched context when VirusTotal was clean or unknown
- Approval gate behavior for critical responses remained intact

## Scenario-Based Q&A

### Why not rely only on VirusTotal?

External APIs are useful but incomplete for SOC operations. Internal intelligence captures organization-specific threat history, analyst notes, and partner feed context that public sources do not provide.

### Why cache external results locally?

Caching reduces repeated API dependence, preserves prior knowledge, and improves resilience if the external service is limited or unavailable.

### Why expiration instead of permanent IOC retention?

Threat context decays over time. Expiration reduces stale matches and avoids over-scoring based on outdated indicators.

## Key Terms

- IOC (Indicator of Compromise): Observable artifact linked to malicious activity
- Local Threat Intel DB: Internal, reusable IOC knowledge store
- Reputation: Trust classification (for example malicious, suspicious, clean)
- Confidence: Estimated reliability of the intelligence entry
- Enrichment: Adding context to raw telemetry before triage and response
- Intel Expiration: Time-based invalidation of stale IOC entries

## My Takeaways

- Threat intelligence becomes much more useful when owned internally
- IOC matching should include multiple types, not just domains
- Tags and confidence make scoring more realistic for triage
- Expiration logic is necessary to keep detections relevant

Week 6 Day 1 is complete.

## Next Up

Week 6 Day 2 focuses on automated threat feed ingestion so I can continuously update local intelligence rather than manually curating all IOC data.
