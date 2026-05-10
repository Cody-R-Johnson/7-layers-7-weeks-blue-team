# Week 6 Day 5 - Intel-Driven Detection Prioritization

This day converts enrichment into decision logic so triage is driven by risk context, not one-size-fits-all escalation.

## Day Objective

Today I upgraded the pipeline from severity-by-behavior to a multi-factor prioritization model:

Behavior + Intel Confidence + Actor Risk + Campaign Priority -> Priority Score -> Severity -> Routing -> Response

I implemented:

- `prioritization.py` for signal-specific scoring
- Final priority score aggregation with component visibility
- Dynamic severity mapping from priority score
- SOC override rule for state-sponsored high-behavior activity
- `analyzer.py` integration using priority-derived severity
- Priority payload propagation into case output for auditability

## Concept in Practical Terms

Before today, the pipeline behavior was effectively:

All suspicious/malicious paths -> `critical` -> Incident Response queue

That creates alert flooding and hides what is truly urgent.

After this change, detections are separated into three dimensions:

- Detection Strength: how strong behavior indicators are
- Intel Confidence: how reliable matched IOC intelligence is
- Threat Context: campaign priority and actor risk

This is the shift from enrichment-only context to operational triage logic.

## What I Implemented

### 1) Prioritization Engine (`prioritization.py`)

I added scoring functions for each dimension:

- `get_intel_confidence_score(enrichment)`
- `get_actor_risk_score(campaign_matches)`
- `get_campaign_priority_score(campaign_matches)`
- `calculate_priority(score, enrichment, campaign_matches)`
- `get_severity_from_priority(priority, campaign_matches=None)`

Priority output now preserves component breakdown:

```json
{
  "behavior_score": 7,
  "intel_score": 3,
  "actor_score": 4,
  "campaign_score": 3,
  "total_score": 17,
  "override_applied": false,
  "override_reason": null
}
```

### 2) Override Escalation Rule

I added a SOC-style forced escalation condition:

```python
if has_state_sponsored_actor(campaign_matches) and behavior_score >= 6:
    priority["override_applied"] = True
    priority["override_reason"] = "State-sponsored actor with high behavior score"
    return "critical"
```

This guarantees severe handling for high-risk actor + strong behavior combinations, even when score thresholds might otherwise under-prioritize edge cases.

### 3) Analyzer Integration (`analyzer.py`)

I replaced legacy severity derivation:

- Old: `severity = get_severity(score)`
- New:
  - `priority = calculate_priority(score, enrichment, campaign_matches)`
  - `severity = get_severity_from_priority(priority, campaign_matches)`

I also added priority to analyzer output:

- `"priority": priority`

### 4) Case Visibility Path (`case.py`)

To make SOC decisions auditable, I ensured priority details are persisted in each case record:

- `"priority": analysis_result.get("priority", {})`

This exposes component scoring and override metadata directly in `cases.json`.

## Validation Results

### Baseline Priority Behavior

Expected and observed model behavior:

- APT C2 path -> `critical`
- Financially motivated phishing path -> `high`
- Unknown-actor suspicious path -> `high`

### Exercise 2 - No Campaign Match

Test IOC existed in local intel but not in `campaigns.json`.

Observed:

- `campaign_matches: []`
- `actor_score: 0`
- `campaign_score: 0`
- Severity remained elevated only from behavior + intel confidence

Outcome: context-aware downgrade worked.

### Exercise 3 - High Behavior, No Intel

Behavior-only command tested with base64 decode and shell execution.

Observed:

- `intel_score: 0`
- `actor_score: 0`
- `campaign_score: 0`
- Severity `medium`

Outcome: behavior alone matters, but no automatic escalation to critical.

### Exercise 4 - Multi-Campaign Match

Same IOC was mapped to two campaigns.

Observed:

- Two `campaign_matches`
- Aggregated MITRE techniques preserved
- Campaign contribution increased priority score

Outcome: campaign stacking logic worked as designed.

### Exercise 5 - Override Rule

State-sponsored actor plus strong behavior path was tested.

Observed:

- Severity `critical`
- Override metadata populated:
  - `override_applied: true`
  - `override_reason: "State-sponsored actor with high behavior score"`

Outcome: forced SOC escalation rule worked and remained visible in case output.

## Scenario-Based Q and A

### Why split behavior, intel confidence, and threat context instead of one score?

Each signal dimension answers a different question: Did something malicious-looking happen, how trustworthy is the IOC, and how dangerous is the campaign/actor context. Combining separated dimensions improves triage explainability.

### Why keep a component breakdown in case output?

SOC teams need to justify routing and response. Priority component visibility makes decisions reviewable and tunable without reverse-engineering logic from code.

### Why add override rules on top of scoring thresholds?

Threshold models are useful but can miss policy-level priorities. Override rules let SOC leadership enforce strict escalation for specific risk patterns.

### Why should no-campaign IOC detections not be treated as critical by default?

Unknown campaign context increases uncertainty, not always urgency. Routing these to investigation instead of immediate IR reduces noise while preserving analyst attention.

## Key Terms

- Detection Strength: Behavior-based confidence derived from process and command indicators
- Intel Confidence: Reliability weighting from local threat intelligence metadata
- Threat Context: Campaign and actor information that influences business risk
- Priority Score: Combined risk score used for severity and routing decisions
- Override Rule: Explicit escalation logic that supersedes normal threshold mapping

## My Takeaways

- Prioritization quality depends on explainability, not only score math
- Campaign and actor context materially improves SOC triage outcomes
- Behavior-only detections are important but should not always jump to IR
- Override logic is essential for policy-driven escalation scenarios
- Persisting priority details in case records is critical for audits and tuning

Week 6 Day 5 is complete.

## Next Up

Week 6 Day 6 focuses on building an intelligence feedback loop so incident outcomes can improve future detections automatically.
