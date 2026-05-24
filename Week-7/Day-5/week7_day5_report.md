# Week 7 Day 5 Report: Containment and Recovery

Week 7 Day 5 transitioned the incident workflow from analysis and attribution into active response operations. The focus shifted to containment execution logic, escalation controls, eradication planning, recovery orchestration, and validation tracking.

This day was built as an operational IR pipeline: classify containment urgency, generate host-level actions, produce an eradication plan, define recovery and rollback workflow, and automatically decide whether the host should be monitored, contained, or reimaged.

## Analyst

cody

## Objective

Build a practical containment and recovery workflow that demonstrates:

- Automated containment action generation
- Host isolation and escalation decisioning
- IOC-derived blocklist recommendations
- Eradication workflow planning
- Recovery tracking with rollback planning
- Post-containment validation controls
- Automated IR decision engine output

## Day Scope

Implemented and executed the following components:

- containment_engine.py: Host-level containment recommendations with escalation levels and IOC blocklist generation
- eradication_plan.py: Standardized eradication sequence for compromised systems
- recovery_manager.py: Recovery coordination workflow with rollback planning and business validation gate
- validation_checks.py: Post-containment verification checklist output
- decision_engine.py: Automated decision logic for contain, monitor, recover, escalate, or reimage

Produced artifacts:

- containment_report.json
- eradication_report.json
- recovery_report.json
- validation_report.json
- ir_decision_report.json
- week7_day5_report.md

## Starting State

Day 5 began by carrying forward Day 4 outputs into the Day 5 workspace and creating the new operational scripts and report files.

Base workflow:

- Create day workspace
- Copy JSON, log, and markdown artifacts from Day 4
- Initialize containment, eradication, recovery, validation, and decision scripts

Setup commands used:

```bash
mkdir -p ~/soar-lab/week7/day5
cd ~/soar-lab/week7/day5

cp ~/soar-lab/week7/day4/*.json .
cp ~/soar-lab/week7/day4/*.log .
cp ~/soar-lab/week7/day4/*.md .

touch containment_engine.py
touch recovery_manager.py
touch eradication_plan.py
touch validation_checks.py
touch containment_report.json
touch recovery_report.json
touch week7_day5_report.md
```

## 1. Baseline Containment Automation

The initial containment engine consumed host impact mapping and malware capability scoring, then produced recommended actions per host.

Core behavior:

- Read host_ioc_map.json and capability_report.json
- Evaluate highest host severity plus global malware risk
- Recommend containment actions such as:
  - isolate_host
  - disable_user_sessions
  - preserve_memory_capture
  - block_iocs
  - increase_monitoring

Initial result:

- wkstn-01 was identified as high severity
- Containment recommendation set was generated successfully

Execution:

```bash
python3 containment_engine.py
cat containment_report.json
```

Observed output:

```text
[+] Containment recommendations generated
[
  {
    "host": "wkstn-01",
    "highest_severity": "high",
    "recommended_actions": [
      "block_iocs",
      "disable_user_sessions",
      "increase_monitoring",
      "isolate_host",
      "preserve_memory_capture"
    ]
  }
]
```

## 2. Containment Escalation Enhancements (Exercises 1, 2, 4)

The containment engine was then upgraded with operational controls.

### 2.1 Escalation Levels

Added containment level classification:

- low
- medium
- high
- critical

Decision inputs:

- host highest severity
- max malware risk score

Operational effect:

- high and critical levels trigger stronger active containment actions
- critical level triggers executive escalation behavior and approval requirements

### 2.2 IOC-Based Blocking Recommendations

Added automatic blocklist generation from IOC intelligence.

Generated block categories:

- domains_to_block
- ips_to_block
- urls_to_block

This connected intel extraction directly into containment actioning, reducing manual translation during active response.

### 2.3 Approval Workflow

Added management approval logic:

- requires_management_approval is set to true when containment level is critical

This reflects real-world governance where aggressive containment or reimage actions require formal authorization.

### 2.4 Final Containment Output

Final containment state for wkstn-01:

- highest_severity: high
- max_malware_risk: 10
- containment_level: critical
- requires_management_approval: true
- escalation actions included:
  - initiate_management_escalation
  - notify_incident_commander
  - prepare_reimage

Blocklist generated included domains, IP, and payload URLs observed in prior stages.

Execution after enhancement:

```bash
python3 containment_engine.py
cat containment_report.json
```

Observed output:

```text
[+] Containment recommendations generated
[
  {
    "host": "wkstn-01",
    "highest_severity": "high",
    "max_malware_risk": 10,
    "containment_level": "critical",
    "requires_management_approval": true,
    "recommended_actions": [
      "block_iocs",
      "disable_user_sessions",
      "increase_monitoring",
      "initiate_management_escalation",
      "isolate_host",
      "notify_incident_commander",
      "prepare_reimage",
      "preserve_memory_capture"
    ]
  }
]
```

## 3. Eradication Planning

The eradication module produced a standardized immediate-priority plan.

Generated eradication steps:

- Terminate malicious processes
- Remove persistence mechanisms
- Delete malicious scripts
- Reset compromised credentials
- Block malicious domains and IPs
- Patch exploited vulnerabilities
- Scan for additional malware artifacts

Operational flags:

- requires_reboot: true
- credential_reset_required: true
- recommended_priority: immediate

This provided a clear bridge between containment and host sanitization.

Execution:

```bash
python3 eradication_plan.py
cat eradication_report.json
```

Observed output:

```text
[+] Eradication plan generated
{
  "eradication_steps": [
    "Terminate malicious processes",
    "Remove persistence mechanisms",
    "Delete malicious scripts",
    "Reset compromised credentials",
    "Block malicious domains and IPs",
    "Patch exploited vulnerabilities",
    "Scan for additional malware artifacts"
  ],
  "requires_reboot": true,
  "credential_reset_required": true,
  "recommended_priority": "immediate"
}
```

## 4. Recovery Coordination with Rollback (Exercise 3)

The recovery manager was expanded to include rollback planning and business validation controls.

Recovery workflow:

- Restore clean system state
- Validate patched systems
- Re-enable network connectivity
- Monitor for reinfection
- Validate business functionality

Rollback workflow added:

- Restore previous VM snapshot
- Revert recent configuration changes
- Reapply known-good firewall rules
- Restore last clean backup
- Document rollback reason and timestamp

Additional control:

- requires_business_owner_validation: true

This made the recovery plan reversible, auditable, and aligned to operational risk management.

Execution:

```bash
python3 recovery_manager.py
cat recovery_report.json
```

Observed output:

```text
[+] Recovery report generated
{
  "recovery_steps": [
    "Restore clean system state",
    "Validate patched systems",
    "Re-enable network connectivity",
    "Monitor for reinfection",
    "Validate business functionality"
  ],
  "rollback_plan": [
    "Restore previous VM snapshot",
    "Revert recent configuration changes",
    "Reapply known-good firewall rules",
    "Restore last clean backup",
    "Document rollback reason and timestamp"
  ],
  "recovery_status": "in_progress",
  "monitoring_period_hours": 72,
  "requires_business_owner_validation": true
}
```

## 5. Validation Engineering

Validation checks were generated as pending controls to confirm containment and recovery quality.

Validation checklist:

- No malicious processes running
- No outbound C2 traffic observed
- Persistence mechanisms removed
- Credentials reset successfully
- No reinfection indicators detected

This artifact supports post-response signoff and transition toward incident closure.

Execution:

```bash
python3 validation_checks.py
cat validation_report.json
```

Observed output:

```text
[+] Validation report generated
[
  {"check": "No malicious processes running", "status": "pending"},
  {"check": "No outbound C2 traffic observed", "status": "pending"},
  {"check": "Persistence mechanisms removed", "status": "pending"},
  {"check": "Credentials reset successfully", "status": "pending"},
  {"check": "No reinfection indicators detected", "status": "pending"}
]
```

## 6. Automated IR Decision Engine (Exercise 5)

A dedicated decision engine was implemented to convert analysis and containment context into host-level action decisions.

Decision inputs:

- Containment level per host
- Malware capability indicators
- Persistence findings
- Attack path status
- Maximum malware risk score

Decision outputs:

- decision
- escalate
- requires_management_approval
- rationale array

Decision logic highlights:

- High or critical containment level pushes toward active containment
- Persistence findings push toward reimage
- Ransomware behavior or risk score at critical threshold pushes toward reimage
- Data theft or multi-stage intrusion flags escalation

Final decision for wkstn-01:

- decision: reimage
- escalate: true
- requires_management_approval: true

Rationale included:

- High containment level
- Remote control capability detected
- Persistence found
- Critical malware risk or ransomware behavior
- Escalate to incident commander

Execution:

```bash
python3 decision_engine.py
cat ir_decision_report.json
```

Observed output:

```text
[+] IR decision report generated
[
  {
    "host": "wkstn-01",
    "decision": "reimage",
    "escalate": true,
    "requires_management_approval": true,
    "rationale": [
      "High containment level",
      "Remote control capability detected",
      "Persistence found",
      "Critical malware risk or ransomware behavior",
      "Escalate to incident commander"
    ]
  }
]
```

## 7. End-to-End Execution Flow

Day 5 execution sequence:

- python3 containment_engine.py
- python3 eradication_plan.py
- python3 recovery_manager.py
- python3 validation_checks.py
- python3 decision_engine.py

Artifact validation:

- cat containment_report.json
- cat eradication_report.json
- cat recovery_report.json
- cat validation_report.json
- cat ir_decision_report.json

All scripts executed successfully and produced expected outputs.

Consolidated run used:

```bash
python3 containment_engine.py
python3 recovery_manager.py
python3 decision_engine.py

cat containment_report.json
cat recovery_report.json
cat ir_decision_report.json
```

## 8. Final Operational Outcome

Final Day 5 status:

- Containment level: critical
- Host decision: reimage
- Escalation required: true
- Management approval required: true
- IOC blocklist generated: yes
- Eradication workflow generated: yes
- Recovery and rollback plans generated: yes
- Validation checklist generated: yes
- IR decision engine functioning: yes

## 9. Practical IR Learnings

Key response engineering outcomes:

- Triage and malware analysis can be directly operationalized into containment action plans
- Risk and persistence indicators should heavily influence isolate versus reimage decisions
- Containment governance controls improve operational safety in high-impact scenarios
- Recovery planning should always include rollback capability to reduce restoration risk
- Validation artifacts are essential for confidence before declaring response completion

## 10. Final Artifacts

- containment_report.json
- eradication_report.json
- recovery_report.json
- validation_report.json
- ir_decision_report.json
- decision_engine.py
- week7_day5_report.md

## Progress Map

Week 7: Incident Response

- [x] Day 1 - IR Planning and Evidence Preservation
- [x] Day 2 - Evidence Collection and Triage
- [x] Day 3 - Log and Timeline Correlation
- [x] Day 4 - Malware Triage and Analysis
- [x] Day 5 - Containment and Recovery
- [ ] Day 6 - Post-Incident Automation
- [ ] Day 7 - Full Incident Simulation

## Day 5 Completion

Week 7 Day 5 is complete.

The operational shift on this day was the key milestone: the workflow moved from detecting and describing attacker activity to making containment decisions, coordinating eradication, planning recovery safeguards, and validating that response actions can be trusted.

## Next Step

Week 7 Day 6: Post-Incident Automation
