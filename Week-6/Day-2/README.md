# Week 6 Day 2 - Automated Threat Feed Ingestion

This day moves from manually curating `intel_db.json` to ingesting threat intel feeds automatically and merging them into the pipeline.

## Day Objective

Today I built an automated feed ingestion system that can:

- Parse a simulated external threat feed (`threat_feed.json`)
- Normalize and validate incoming IOCs before accepting them
- Merge new indicators into the existing `intel_db.json`
- Deduplicate entries and merge tags, sources, and reputation intelligently
- Write an audit log of every ingestion action
- Protect existing high-confidence intel from being downgraded by weaker feeds

The architecture now follows:

Threat Feed → Normalize IOCs → Validate → Merge into Intel DB → Use in Pipeline

## Concept in Practical Terms

Before today, I added IOCs to the local intel database by hand. That works for a small number of known-bad indicators but does not scale.

Real SOC teams consume structured feeds from threat intelligence platforms, ISACs, vendor partners, and government sources. Each feed needs to be:

- Parsed into a common schema
- Validated against expected formats
- Merged without overwriting trustworthy existing data

This is the foundation of operationalizing threat intelligence at scale.

## What I Implemented

### 1) Simulated Threat Feed

I created `threat_feed.json` to represent a structured partner feed with metadata and indicators:

- `feed_name`, `source`, `generated_at` as feed-level attributes
- Individual indicators each carrying `type`, `value`, `reputation`, `confidence`, and `tags`

This mirrors real-world structured formats like STIX or CSV feeds normalized into JSON.

### 2) IOC Validation (`feed_ingest.py`)

I implemented validation functions for each IOC type:

- `is_valid_domain` — regex check for proper domain format
- `is_valid_ip` — splits octets and checks each is between 0 and 255 (Exercise 2)
- `is_valid_hash` — accepts MD5 (32), SHA1 (40), and SHA256 (64) hex strings

Invalid IOCs are rejected before merging and logged as `invalid` in the audit log.

### 3) IOC Normalization

Each validated indicator is normalized into a common record:

- `reputation` from the feed
- `sources` as a list (not a concatenated string)
- `confidence` from the feed
- `tags` as a list
- `last_seen` set to the current UTC date at ingestion time

### 4) Intel DB Merge Logic

The `merge_indicator` function handles deduplication intelligently:

- New IOCs are created directly
- Existing IOCs are updated without overwriting trustworthy data
- Tags are merged as a sorted deduplicated union
- Reputation is only upgraded, never downgraded
- Confidence is only upgraded, never downgraded (Exercise 5)
- Sources are tracked as a list and merged across feeds (Exercise 3)

### 5) Source List Tracking (Exercise 3)

Instead of concatenating sources as a string like `internal_feed+partner_lab`, sources are stored as a proper list:

```json
"sources": [
  "internal_feed",
  "partner_lab"
]
```

A migration function (`get_existing_sources`) handles converting older entries that still use the `source` string format, removing the field after conversion.

### 6) Ingestion Audit Log (Exercise 4)

Every processed indicator writes one JSON line to `ingest.log`:

```json
{"timestamp": "2026-05-07T21:21:40.881226+00:00", "action": "updated", "type": "domain", "value": "stage-c2.example.net", "section": "domains"}
{"timestamp": "2026-05-07T21:21:40.881577+00:00", "action": "invalid", "type": "ip", "value": "999.999.999.999"}
```

This gives an auditable record of every ingestion run, which is essential for incident review and feed quality assessment.

### 7) Feed IOCs in the Detection Pipeline

I updated `test_data.json` to include processes referencing newly ingested IOCs. The pipeline correctly matched and created cases for all four:

- `stage-c2.example.net` — malicious domain, C2 tag matched
- `198.51.100.77` — malicious IP matched
- `e99a18c428cb38d5f260853678922e03` — malicious hash matched
- `phish-login.example.org` — suspicious domain, phishing tag matched

## Validation Results

### Base Ingestion Run

Feed: `simulated_partner_feed` with 5 indicators

```json
{
  "processed": 5,
  "created": 4,
  "updated": 0,
  "invalid": 1
}
```

`bad-format-domain` was correctly rejected as an invalid domain.

### Exercise 1 — Feed Duplicate Update

Added `malicious-example.com` to the feed with `c2` and `botnet` tags. After re-ingestion:

- `updated` count incremented
- Tags merged to `["botnet", "c2", "malware"]`

### Exercise 2 — Invalid IP Rejection

Added `999.999.999.999` to the feed. The improved octet-range validator correctly rejected it:

- `invalid` count incremented
- `ingest.log` recorded `"action": "invalid"` for this entry

### Exercise 3 — Source List

After ingesting the partner feed over existing internal intel:

```json
"sources": [
  "internal_feed",
  "partner_lab"
]
```

No `source` string field remains.

### Exercise 4 — Ingestion Log Output

`ingest.log` produced one JSON line per indicator with `action`, `type`, `value`, and for valid entries the `section`.

### Exercise 5 — Confidence Downgrade Protection

Added `malicious-example.com` with `confidence: low` to the feed. After re-ingestion:

```json
"confidence": "high"
```

Confidence was not downgraded. The merge logic only upgrades confidence when the incoming value is strictly higher than the stored value.

## Scenario-Based Q&A

### Why validate IOCs before merging?

Ingesting malformed data corrupts the intelligence database. A domain with no TLD or an IP with octets over 255 is either a feed error or a typo. Rejecting it keeps the database reliable and prevents false matches downstream.

### Why store sources as a list instead of a concatenated string?

A list is machine-readable and queryable. When reviewing an IOC, I can ask how many independent sources confirmed it, which is a real measure of confidence. A fused string like `internal_feed+partner_lab` loses that structure.

### Why never downgrade confidence or reputation?

If I have high-confidence intel from a trusted internal analyst, a low-quality automated feed should not override it. The higher value represents more reliable knowledge. Only upgrades are accepted.

### Why log each ingestion action?

Feed quality varies. If a feed starts producing a high volume of invalid entries, the audit log reveals it before the database is polluted. It also supports post-incident review to determine when a specific IOC entered the database.

## Key Terms

- Threat Feed: Structured stream of IOCs from an external or partner source
- IOC Normalization: Converting raw feed entries into a consistent internal schema
- Deduplication: Merging new intel with existing records instead of creating duplicates
- Source Tracking: Recording which feeds contributed to an IOC record
- Confidence Downgrade Protection: Ensuring weaker feeds cannot override high-quality existing intelligence
- Ingestion Audit Log: Append-only record of all processing actions during a feed run

## My Takeaways

- Feed ingestion requires validation at the boundary to protect the intel database
- Merging is more complex than inserting — reputation, confidence, and tags all need rules
- Storing sources as a list preserves provenance and supports multi-feed correlation
- Audit logging is not optional in production threat intel pipelines
- Confidence downgrade protection is a small logic check that prevents serious data quality problems

Week 6 Day 2 is complete.

## Next Up

Week 6 Day 3 focuses on IOC lifecycle management — expiration, aging, and automated cleanup of stale indicators.
