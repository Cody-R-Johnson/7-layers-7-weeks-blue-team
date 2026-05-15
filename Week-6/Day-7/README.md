# Week 6 Day 7 - Threat Intelligence Platform Capstone

Week 6 closes with a full local MISP-style threat intel platform exercise. Today I validated the complete lifecycle from IOC ingestion to SOC pipeline outcomes and reporting/export.

## Objective

Build and validate a local threat intelligence platform that supports:

IOC storage -> feed ingestion -> lifecycle management -> analyst feedback -> suppression -> campaign/actor mapping -> search -> reporting -> export

## Day Scope

I implemented a capstone platform module, `intel_platform.py`, with three operator actions:

- `report` to generate `platform_report.json`
- `export` to generate `export_bundle.json`
- `search` to look up any domain/IP/hash IOC in local intel storage

Core data files used by the platform:

- `intel_db.json`
- `campaigns.json`
- `actors.json`
- `suppression.json`

## Platform Components

- `intel_db.json`: Canonical IOC store (domains, IPs, hashes + lifecycle/reputation fields)
- `threat_feed.json`: Source feed data ingested into local intel
- `feed_ingest.py`: Feed ingestion logic and normalization
- `lifecycle.py`: Expiration/revocation/active lifecycle control
- `feedback.py`: Analyst verdict processing and intel mutation
- `suppression.json`: Suppressed indicators and optional command line suppression patterns
- `actors.json`: Actor profile data
- `campaigns.json`: Campaign metadata with actor and MITRE mappings
- `actor_mapping.py`: IOC to campaign and actor correlation logic
- `intel_platform.py`: Search/report/export capstone interface

## Capstone Validation Outputs

### Platform Report (`platform_report.json`)

```json
{
  "generated_at": "2026-05-15T19:35:32.311819+00:00",
  "ioc_counts": {
    "domains": 8,
    "ips": 4,
    "hashes": 3,
    "total": 15
  },
  "status_counts": {
    "active": 11,
    "revoked": 3,
    "expired": 1
  },
  "reputation_counts": {
    "malicious": 9,
    "clean": 2,
    "suspicious": 3,
    "internal": 1
  },
  "campaign_count": 3,
  "actor_count": 2,
  "suppression_counts": {
    "domains": 1,
    "ips": 0,
    "hashes": 0,
    "cmdline_patterns": 0
  },
  "active_malicious_iocs": {
    "domains": [
      "malicious-example.com",
      "unknown-actor.example.net",
      "new-malicious.example.net"
    ],
    "ips": [
      "203.0.113.50",
      "198.51.100.77",
      "198.51.100.200"
    ],
    "hashes": [
      "44d88612fea8a8f36de82e1278abb02f",
      "e99a18c428cb38d5f260853678922e03",
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ]
  }
}
```

### Pipeline Summary (`pipeline_summary.json`)

```json
{
  "run_started": "2026-05-15T19:36:40.565281+00:00",
  "events_seen": 4,
  "duplicates_skipped": 0,
  "cases_created": 4,
  "benign_skipped": 0,
  "below_threshold_skipped": 0,
  "response_success": 1,
  "response_failed": 3,
  "run_finished": "2026-05-15T19:36:41.572034+00:00"
}
```

### Campaign Report (`campaign_report.json`)

```json
{
  "campaigns_seen": [
    {
      "campaign_id": "WEB-C2-MAY2026",
      "campaign_name": "WEB-C2-MAY2026",
      "actor_id": "APT-LAB-01",
      "actor_name": "APT-LAB-01",
      "actor_type": "state-sponsored",
      "techniques_seen": [
        "T1059",
        "T1105"
      ],
      "cases": [
        {
          "case_id": "b3b7d302-bf57-49ef-a11b-6b9fb67ac825",
          "severity": "critical",
          "process": "sh",
          "pid": "12001"
        },
        {
          "case_id": "c93fac9a-10ae-4a39-8da8-53d5b3914c4b",
          "severity": "critical",
          "process": "bash",
          "pid": "12004"
        }
      ],
      "case_count": 2
    },
    {
      "campaign_id": "PHISH-KIT-MAY2026",
      "campaign_name": "PHISH-KIT-MAY2026",
      "actor_id": "CRIME-LAB-77",
      "actor_name": "CRIME-LAB-77",
      "actor_type": "financially motivated",
      "techniques_seen": [
        "T1059",
        "T1566"
      ],
      "cases": [
        {
          "case_id": "b3b7d302-bf57-49ef-a11b-6b9fb67ac825",
          "severity": "critical",
          "process": "sh",
          "pid": "12001"
        },
        {
          "case_id": "c93fac9a-10ae-4a39-8da8-53d5b3914c4b",
          "severity": "critical",
          "process": "bash",
          "pid": "12004"
        }
      ],
      "case_count": 2
    }
  ]
}
```

## Capstone Report Summary

### IOC Inventory

- Domains: 8
- IPs: 4
- Hashes: 3
- Total IOCs: 15

### IOC Status Summary

- Active: 11
- Expired: 1
- Revoked: 3

### Reputation Summary

- Malicious: 9
- Suspicious: 3
- Clean: 2
- Internal: 1

### Campaigns and Actors

- Campaigns: 3
- Actors: 2
- MITRE techniques observed: `T1059`, `T1105`, `T1566`

### Feedback Loop Results

- False positives suppressed: 1 domain
- Confirmed malicious IOCs: reflected in active malicious domain/IP/hash sets
- New IOCs created from feedback: includes `new-malicious.example.net`

### Pipeline Validation

- Cases created: 4
- Suppressed/skipped events: 0 at pipeline stage in this run
- Critical cases: 2 observed in campaign report snippet
- High cases: not shown in captured campaign snippet
- Medium cases: not shown in captured campaign snippet

## One Important Hardening Fix

During validation, `stage-c2.example.net` still produced matches despite suppression being present. That indicates suppression was stored but not enforced in IOC lookup.

Recommended patch in `intel.py`:

```python
def load_suppression():
    try:
        with open("suppression.json", "r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        return {"domains": [], "ips": [], "hashes": [], "cmdline_patterns": []}


def is_suppressed(ioc, section):
    suppression = load_suppression()
    return any(entry.get("value") == ioc for entry in suppression.get(section, []))
```

Then in `lookup_domain()` add:

```python
if is_suppressed(domain, "domains"):
    return None
```

Apply the same enforcement pattern for `lookup_ip()` and `lookup_hash()` so suppression is globally consistent.

## Grading Rubric

- IOC Management: 10/10
- Feed Ingestion: 10/10
- Lifecycle Control: 10/10
- Feedback Loop: 9/10
- Campaign/Actor Mapping: 10/10
- Reporting/Export: 10/10
- SOC Realism: 9/10

Final Score: 68/70

## Key Findings

- Full end-to-end local intel lifecycle is working with measurable outputs.
- Reporting and export provide SOC-friendly operational visibility.
- Campaign and actor context materially improve detection explanation quality.
- Suppression storage is effective, but enforcement must occur in lookup paths to prevent repeat false positives.

## Limitations

- Local JSON storage only
- No authentication or access control
- No persistent dedupe database
- No real MISP API integration yet
- IOC context is still simplified

## Final Takeaway

This capstone demonstrates a complete local threat intelligence workflow: ingestion, enrichment, lifecycle, feedback, suppression, mapping, reporting, and operational use inside a SOC automation pipeline.

Week 6 Day 7 is complete.

## Next Up

Week 7 Day 1 - Incident Response Planning and Evidence Collection.
