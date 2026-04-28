# Week 5 Day 3 - Full SOAR Playbook Logic

This module captures my transition from detection-and-enrichment automation into a full SOAR-style playbook that performs triage, enrichment, severity classification, confidence labeling, and response recommendation.

## Day Objective

Today I focused on building a repeatable decision workflow instead of another one-off script.

By the end of this day, I wanted to:

- Keep behavioral triage from Day 1
- Keep API enrichment from Day 2
- Add severity classification for SOC prioritization
- Add confidence labels for analyst communication
- Add recommended response actions for decision support

## Concept in Practical Terms

Day 1:

1. Detect suspicious behavior
2. Score and verdict

Day 2:

1. Detect suspicious behavior
2. Enrich with VirusTotal
3. Improve confidence

Day 3:

1. Triage behavior
2. Enrich indicators
3. Re-score with context
4. Classify severity
5. Label confidence
6. Recommend analyst action

Key shift:

- Output is no longer just alert data
- Output now drives operational SOC decisioning

## Day 3 Playbook Structure

I organized Day 3 in a clean modular layout:

- analyzer.py: core pipeline orchestration and scoring flow
- enrichment.py: domain extraction and VirusTotal lookup
- response.py: severity mapping and response recommendation logic
- test_data.json: event input payload
- output.json: enriched playbook result

## Playbook Workflow

The Day 3 analyzer runs this sequence for each process event:

1. Behavioral analysis and baseline score
2. Threat intel enrichment (domain + VirusTotal)
3. Enrichment-based score adjustment
4. Verdict assignment
5. Severity classification
6. Confidence labeling
7. Recommended response generation
8. Structured output with playbook stage marker

## Day 3 Enhancements Added

- Severity levels: informational, low, medium, high, critical
- Confidence labels: none, low, medium, high
- Recommended SOC response actions per severity/verdict
- Playbook metadata field: playbook_stage=triage_enrichment_response
- Medium-severity response enhancement: collect_more_context

## Validated Test Results

### 1) Multi-Event Validation (Completed)

Input set included:

- Benign system process (systemd)
- Malicious-domain curl/pipe chain from temp path
- Base64 decode execution from /dev/shm with unusual parent

Observed results:

- systemd:
  - score: 0
  - severity: informational
  - confidence: none
  - verdict: benign
  - action: no_action

- malicious-example.com case:
  - score: 11
  - severity: critical
  - confidence: high
  - verdict: malicious
  - action: isolate_host_and_escalate

- base64 no-domain case:
  - score: 6
  - severity: medium
  - confidence: medium
  - verdict: malicious
  - action: collect_more_context

This validated the full triage to enrichment to response workflow end to end.

## Completion Criteria Status

- [x] analyzer.py created
- [x] enrichment.py created
- [x] response.py created
- [x] Malicious domain test completed
- [x] Clean domain test completed
- [x] Base64 no-domain test completed
- [x] Normal Osquery data test completed
- [x] output.json includes severity
- [x] output.json includes recommended_response

## Example Output Shape (Day 3)

```json
{
  "process": "bash",
  "score": 11,
  "severity": "critical",
  "confidence": "high",
  "verdict": "malicious",
  "reasons": [
    "Execution from temp directory",
    "Contextually unusual parent process: apache2",
    "Download + pipe execution",
    "Domain flagged as malicious by VirusTotal"
  ],
  "enrichment": {
    "domain": "malicious-example.com",
    "virustotal": {
      "malicious": 1,
      "suspicious": 0,
      "reputation": "malicious"
    }
  },
  "recommended_response": {
    "action": "isolate_host_and_escalate",
    "description": "High-risk behavior with strong indicators. Isolate host, preserve evidence, and escalate to IR."
  },
  "playbook_stage": "triage_enrichment_response"
}
```

## SOC Engineering Notes

Operational value from Day 3:

- Analysts get a prioritized queue, not just raw detections
- Confidence + severity helps triage under high alert volume
- Response recommendations reduce decision latency

Important caution:

- This remains an advisory playbook stage
- Recommended actions should still be reviewed against environment context and response policy

## Detection Model Characteristics (Day 3)

- Stateless event-by-event processing
- Behavior plus intelligence correlation per event
- Deterministic severity and action mapping
- No automated containment execution yet (recommendation only)

## Known Limitations

- No process lineage depth scoring (parent-to-grandparent chain)
- No user/session awareness (UID, TTY, login source)
- No container/host context distinction
- No caching for repeated domain lookups
- No asynchronous enrichment for high-throughput pipelines

## Future Improvements

- Add domain/IP/hash caching layer
- Add identity and session context to scoring
- Add lineage graph depth scoring
- Add alert routing and automated case creation
- Add policy-gated automated response actions

## Key Terms

- Playbook: repeatable automation workflow for SOC operations
- Severity: operational priority level for handling
- Confidence: strength of evidence supporting detection
- Enrichment: external intelligence context added to detection
- Response recommendation: suggested SOC action based on risk profile

## My Takeaways

- Detection is more useful when paired with action guidance.
- Enrichment is most powerful when merged with behavior, not used alone.
- Severity and confidence labels make escalation decisions faster.
- Modular design (analyzer/enrichment/response) improves maintainability.

## Next Up

Week 5 Day 4 - Automated case creation and alert routing.
