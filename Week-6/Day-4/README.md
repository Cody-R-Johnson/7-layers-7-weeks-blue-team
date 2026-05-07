# Week 6 Day 4 - Threat Actor and Campaign Mapping

This day upgrades detections from IOC-only context to campaign and actor intelligence with MITRE technique mapping.

## Day Objective

Today I built actor and campaign context so detections can map:

IOC -> Campaign -> Actor -> MITRE Techniques -> Detection Priority

I implemented:

- Actor knowledge base in `actors.json`
- Campaign knowledge base in `campaigns.json`
- IOC-to-campaign correlation logic
- Actor-safe enrichment for unknown actor IDs
- Campaign-priority scoring updates
- MITRE technique extraction into case records
- Actor-aware routing behavior
- Campaign-level reporting in `campaign_report.json`

## Concept in Practical Terms

Before today, a detection could say an IOC was suspicious or malicious, but not why it mattered operationally.

Now the system can answer:

- Which campaign this IOC appears in
- Which actor is associated with that campaign
- Which MITRE ATT&CK techniques are linked
- Whether the actor targets our organization sector
- Whether routing priority should change based on actor context

This is the shift from signal classification to intelligence-driven triage.

## What I Implemented

### 1) Actor and Campaign Datasets

I created:

- `actors.json` with actor profile metadata:
  - actor type
  - motivation
  - target sectors
  - known TTPs
  - confidence
- `campaigns.json` with campaign metadata:
  - actor linkage
  - IOC lists
  - MITRE techniques
  - campaign priority

### 2) Mapping Engine (`actor_mapping.py`)

I added:

- `find_campaign_matches(enrichment)` to correlate observed IOC values with campaign IOC sets
- `get_safe_actor(actor_id, actors)` to return fallback defaults for unknown actors
- `apply_campaign_scoring(...)` to add score and reason text for high and medium campaigns
- Sector relevance scoring when actor targets `ORG_SECTOR`
- `extract_mitre_techniques(...)` to deduplicate and normalize case-level MITRE technique tags

### 3) Analyzer Integration (`analyzer.py`)

Inside `analyze_process(proc)`:

- Campaign correlation runs after intel scoring
- Campaign score modifiers are applied
- Full campaign context is added to `analysis_result` as `campaign_matches`

### 4) Case Enrichment (`case.py`)

I updated case creation to include:

- Full `campaign_matches` object in each case
- Aggregated `mitre_techniques` list extracted from matched campaigns

This gives analysts campaign and ATT&CK context directly in the case record.

### 5) Actor-Aware Routing (`router.py`)

Routing now supports actor type logic:

- `critical` still routes to incident response (P1)
- Non-critical cases with a state-sponsored actor route to threat hunting (P2)

This preserves severity-first behavior while still enabling actor-informed handling.

### 6) Sector Relevance (`config.py` + scoring)

I added organization sector configuration:

- `ORG_SECTOR = "technology"`

If an actor targets this sector:

- score +2
- reason added: `Actor targets organization sector`

### 7) Campaign Summary Reporting (`pipeline.py`)

I added `write_campaign_report(cases)` to produce `campaign_report.json` with:

- campaigns seen
- actor details per campaign
- techniques observed
- per-case references
- case counts

### 8) Unknown Actor Safety

I added an unknown campaign with `actor: "UNKNOWN"` and validated:

- no crash
- safe fallback actor object
- campaign still correlated and scored safely

## Validation Results

Pipeline run summary:

```json
{
  "events_seen": 3,
  "cases_created": 3,
  "response_success": 1,
  "response_failed": 2
}
```

Confirmed outcomes:

- MITRE techniques appear in both campaign matches and case-level `mitre_techniques`
- Sector relevance is preserved as `sector_relevant: true/false`
- Reason text includes `Actor targets organization sector` for APT-LAB-01 path
- `campaign_report.json` includes:
  - `WEB-C2-MAY2026`
  - `PHISH-KIT-MAY2026`
  - `UNKNOWN-CAMPAIGN-MAY2026`
- Unknown actor campaign stores safe defaults:
  - `actor_id: UNKNOWN`
  - `name: Unknown Actor`
  - `type: unknown`

## Scenario-Based Q and A

### Why campaign mapping instead of only IOC reputation?

IOCs are short-lived and often reused. Campaign context links multiple indicators into behavior clusters, improving triage confidence and response prioritization.

### Why include actor metadata in cases?

Actor type and motivation provide immediate context for responder decisions, especially when deciding containment urgency and hunting scope.

### Why deduplicate MITRE techniques at case level?

A case can match multiple campaign IOCs. A normalized technique list prevents noisy repetition and supports cleaner reporting and dashboards.

### Why safe defaults for unknown actors?

Intel datasets are incomplete. Unknown actor support prevents pipeline failures while preserving evidence for later attribution.

## Key Terms

- Campaign Mapping: Correlating observed indicators to known operation clusters
- Actor Attribution (Lab Context): Associating campaign records with a threat actor profile
- MITRE Technique Enrichment: Adding ATT&CK TTP IDs to detection output
- Sector Relevance: Prioritization based on actor targeting overlap with organization profile
- Intelligence-Driven Scoring: Risk scoring adjusted by campaign and actor context

## My Takeaways

- Campaign context materially improves SOC decision quality over IOC-only workflows
- Actor-aware routing provides meaningful triage differentiation
- Unknown actor handling is mandatory for robust intel pipelines
- Case-level MITRE tags and campaign reports make analytics and handoffs significantly better

Week 6 Day 4 is complete.

## Next Up

Week 6 Day 5 focuses on intel-driven detection prioritization so response paths adapt by confidence, actor risk, and business relevance.
