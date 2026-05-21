# Week 7 Day 3 Report: Log and Timeline Correlation

Week 7 Day 3 moved from evidence triage into active correlation and threat reconstruction. The focus was to take raw log activity, connect it to known IOCs, classify attacker behavior into attack stages, map IOC activity to hosts, and produce an analyst-usable intrusion timeline.

This day was built as a practical SOC/DFIR workflow: parse, correlate, enrich, stage, map impact, and validate whether a full multi-stage intrusion chain is present.

## Objective

Build a lightweight correlation pipeline that demonstrates:

- Event correlation across multiple log sources
- IOC-to-event attribution
- Severity and confidence enrichment
- Attack stage reconstruction and ordering
- Host-to-IOC impact mapping
- Multi-stage intrusion chain detection

## Day Scope

Implemented and executed the following workflow components:

- `log_parser.py`: Parse `alerts.log`, `failed.log`, and `success.log` into normalized event records
- `correlator.py`: Match parsed events against IOC intelligence and enrich with severity/confidence
- `attack_path.py`: Classify events into attack stages, order events, and detect multi-stage intrusion chains
- `host_ioc_map.py`: Map suspicious hosts to matched IOC activity and summarize host risk

Produced artifacts:

- `parsed_logs.json`
- `correlation_report.json`
- `attack_path.json`
- `host_ioc_map.json`
- `week7_day3_report.md`

## Starting State

Day 3 started by carrying forward Day 2 artifacts:

```bash
mkdir -p ~/soar-lab/week7/day3
cd ~/soar-lab/week7/day3
cp ~/soar-lab/week7/day2/*.json .
cp ~/soar-lab/week7/day2/*.log .
```

Created working files:

```bash
touch log_parser.py
touch correlator.py
touch attack_path.py
touch correlation_report.json
touch attack_path.json
touch week7_day3_report.md
```

## 1. Log Parsing and Normalization

`log_parser.py` reads all designated logs, extracts IP and domain indicators from each line, and emits structured JSON records for downstream processing.

Core parser behavior:

- Sources: `alerts.log`, `failed.log`, `success.log`
- Extractors:
  - IPv4 regex
  - domain regex
- Output fields per event:
  - source file
  - line number
  - raw log line
  - extracted IPs
  - extracted domains
  - parser timestamp

Execution:

```bash
python3 log_parser.py
cat parsed_logs.json
```

Result:

- Parsed log events were successfully written to `parsed_logs.json`
- Structured event data became the correlation input layer

## 2. IOC Correlation with Severity/Confidence Enrichment

`correlator.py` was upgraded to include Exercise 2 requirements:

- IOC matching for both IP and domain indicators
- Event scoring via `score_event(raw_log)`
- Severity and confidence annotations per correlated event

Scoring logic highlights:

- beacon/C2 activity -> `high`, 90
- malware/payload/download -> `high`, 85
- phishing -> `medium`, 75
- failed login/credential activity -> `medium`, 70
- default -> `medium`, 60

Execution:

```bash
python3 correlator.py
cat correlation_report.json
```

Observed correlation output included:

- `stage-c2.example.net`
- `new-malicious.example.net`
- `beacon.badcommand.org`
- `evil.example.com`
- host IOC IP `10.0.1.15`

Representative enriched events:

- Beacon/C2 activity scored high confidence (90)
- Malware download scored high confidence (85)
- Phishing sender observation scored medium confidence (75)

This established a meaningful event signal layer, not just IOC matching.

## 3. Attack Path Reconstruction and Stage Ordering

`attack_path.py` was replaced with an expanded stage classifier to satisfy Exercises 1, 4, and 5.

### Stage Model

The stage order model was implemented as:

- initial_access
- payload_delivery
- persistence
- privilege_escalation
- credential_access
- lateral_movement
- command_and_control
- unknown

### Added Classification Coverage

Classification logic now recognizes:

- persistence via scheduled task/startup
- privilege escalation via admin/privilege/sudo
- lateral movement via wmic/psexec/remote service
- command-and-control via beacon/c2/command

### Multi-Stage Intrusion Detection

Required chain for alerting:

- initial_access
- payload_delivery
- command_and_control
- credential_access

The script computes observed stages and sets:

- `multi_stage_intrusion_detected: true|false`

Execution:

```bash
python3 attack_path.py
cat attack_path.json
```

Current output from the run showed:

- `multi_stage_intrusion_detected: false`
- observed stages: initial access, payload delivery, command and control, unknown
- missing required stage: credential access

This was a realistic analyst finding: enough evidence exists for malicious activity, but the full required chain had not yet been observed.

## 4. Host-to-IOC Attribution

`host_ioc_map.py` was created for Exercise 3 to connect IOC-correlated events back to hosts.

Mapping behavior:

- Reads `correlation_report.json`
- Reads `host_inventory.json`
- Maps event IPs to inventory hostnames
- Captures host-linked IOC lists, event records, and highest observed severity

Execution:

```bash
python3 host_ioc_map.py
cat host_ioc_map.json
```

Result:

- `wkstn-01` mapped to IOC activity
- matched IOCs included `10.0.1.15` and `beacon.badcommand.org`
- highest severity for `wkstn-01` was `high`

This completed host impact attribution, which is critical for containment prioritization.

## 5. End-to-End Pipeline Run

Full execution order:

```bash
python3 log_parser.py
python3 correlator.py
python3 attack_path.py
python3 host_ioc_map.py

cat correlation_report.json
cat attack_path.json
cat host_ioc_map.json
```

Pipeline status:

- Parsing: successful
- Correlation and enrichment: successful
- Attack staging and ordering: successful
- Host mapping: successful

## 6. Analyst Gap Identified and Fix Path

A key analytical gap was identified: missing `credential_access` prevented full-chain detection.

### Gap

`attack_path.json` indicated:

- required chain includes `credential_access`
- observed stages did not include `credential_access`

### Corrective Action

Append a credential-abuse signal to logs:

```bash
echo 'Failed login attempt detected for admin from 10.0.1.15 using stolen credentials' >> alerts.log
```

Re-run:

```bash
python3 log_parser.py
python3 correlator.py
python3 attack_path.py
cat attack_path.json
```

Expected outcome:

- `multi_stage_intrusion_detected: true`

because all required stages should then be present.

## 7. Classification Improvement Applied

Another tuning issue was identified: one curl-based downloader event was classified as `unknown`.

### Root Cause

Payload delivery detection was too narrow and did not include common fetch tooling keywords.

### Improvement

In `classify_stage()`, payload detection was expanded from:

```python
if "download" in log or "payload" in log:
```

to:

```python
if (
    "download" in log or
    "payload" in log or
    "wget" in log or
    "curl" in log
):
```

Re-run:

```bash
python3 attack_path.py
cat attack_path.json
```

Expected effect:

- Fewer `unknown` classifications
- Better payload delivery attribution for scripted fetch-and-execute activity

## 8. Practical SOC/DFIR Outcomes

Day 3 successfully demonstrated:

- Correlation-first incident analytics
- IOC-driven event enrichment
- Attack chain construction from raw telemetry
- Host impact attribution for prioritization
- Multi-stage detection logic and gap analysis
- Detection tuning based on observed misses

This is representative of real-world Tier 1.5/Tier 2 SOC and junior DFIR workflow progression.

## 9. Final Artifacts

- `parsed_logs.json`
- `correlation_report.json`
- `attack_path.json`
- `host_ioc_map.json`
- `week7_day3_report.md`

## Progress Map

Week 7: Incident Response

- [x] Day 1 - IR Planning and Evidence Preservation
- [x] Day 2 - Evidence Collection and Triage
- [x] Day 3 - Log and Timeline Correlation
- [ ] Day 4 - Malware Triage and Analysis
- [ ] Day 5 - Containment and Recovery
- [ ] Day 6 - Post-Incident Automation
- [ ] Day 7 - Full Incident Simulation

## Day 3 Completion

Week 7 Day 3 is complete.

## Next Step

Week 7 Day 4: Malware Triage and Analysis
