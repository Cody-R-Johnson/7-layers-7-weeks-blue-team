# Week 5 Day 1 - Security Automation (SOAR Fundamentals + Python Detection Automation)

This module captures my first Security Automation lab, where I moved from manual endpoint investigation to a reusable, scoring-based detection workflow.

## Day Objective

Today I focused on one practical shift:

- From: manually validating each suspicious process alert
- To: automating enrichment, scoring, and triage output

By the end of this day, I wanted to:

- Build a Python detection engine for suspicious process execution
- Ingest Osquery JSON output (single and multi-process)
- Reduce false positives with system-process tuning
- Preserve detection coverage for webshell and evasion-like behavior
- Produce SOC-readable output with explainable reasons

## Concept in Practical Terms

SOAR at this stage means turning analyst decisions into executable logic.

Manual workflow (before):

1. Alert fires
2. Check process path
3. Check parent process
4. Inspect command line
5. Decide malicious vs suspicious

Automated workflow (today):

1. Ingest process telemetry
2. Apply weighted behavior rules
3. Return score + reasons + verdict
4. Save enriched output for downstream handling

## Lab Build Pattern (Where and How)

I used a simple three-part structure that maps to real SOC pipelines:

- Detection engine: analyzer.py
- Alert/event payload: test_data.json
- Enriched decision output: output.json

Practical mapping:

- test_data.json = SIEM/Osquery payload
- analyzer.py = mini SOAR playbook logic
- output.json = enrichment/case artifact

## Detection Logic Implemented

Core scoring behaviors:

- +2: Execution from temp directories (/tmp or /dev/shm)
- +2: Contextually unusual parent-child relationship (non-standard execution chain)
- +3: Download-and-pipe execution (curl/wget with pipe)
- +2: Suspicious base64 usage in execution chain (for example, decode plus pipe to shell)

False-positive tuning added:

- Known system/kernel process suppression
- Special handling for kernel/system parent PIDs (0, 1, 2) to prevent false positives
- Kernel thread prefix handling (kworker, rcu_, migration, ksoftirqd, watchdog, idle_inject)

Verdict logic tuned:

- score >= 5 => high-confidence suspicious (treated as malicious for lab purposes)
- score > 0 => suspicious
- score = 0 => benign

## Final Day 1 Script (Reference)

```python
import json

SYSTEM_PARENTS = ["0", "1", "2"]
SYSTEM_PROCESS_PREFIXES = [
    "kworker",
    "rcu_",
    "migration",
    "ksoftirqd",
    "watchdog",
    "idle_inject",
]


def is_known_system_process(proc):
    name = proc.get("name", "")
    parent = proc.get("parent", "")

    if name in ["systemd", "init"]:
        return True

    if parent in SYSTEM_PARENTS:
        return True

    if any(name.startswith(prefix) for prefix in SYSTEM_PROCESS_PREFIXES):
        return True

    return False


def analyze_process(proc):
    if is_known_system_process(proc):
        return 0, ["Known system/kernel process"]

    score = 0
    reasons = []

    path = proc.get("path", "")
    parent = proc.get("parent", "")
    cmdline = proc.get("cmdline", "")

    if path.startswith("/tmp") or path.startswith("/dev/shm"):
        score += 2
        reasons.append("Execution from temp directory")

    if parent not in ["bash", "systemd", "init"]:
        score += 2
        reasons.append(f"Contextually unusual parent-child relationship: {parent}")

    if ("curl" in cmdline or "wget" in cmdline) and "|" in cmdline:
        score += 3
        reasons.append("Download + pipe execution")

    if "base64" in cmdline:
        score += 2
        reasons.append("Suspicious base64 decode/execution chain detected")

    return score, reasons


def get_verdict(score):
    if score >= 5:
        return "high_confidence_suspicious"
    if score > 0:
        return "suspicious"
    return "benign"


def main():
    with open("test_data.json", "r", encoding="utf-8") as f:
        processes = json.load(f)

    if isinstance(processes, dict):
        processes = [processes]

    results = []
    for proc in processes:
        score, reasons = analyze_process(proc)
        results.append(
            {
                "process": proc.get("name", "unknown"),
                "score": score,
                "reasons": reasons,
                "verdict": get_verdict(score),
            }
        )

    with open("output.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
```

## Validated Test Results

### 1) Original Suspicious Process Scenario

Input characteristics:

- name: bash
- path: /tmp/.x
- parent: apache2
- cmdline: curl ... | sh

Observed result:

- Score: 7
- Verdict: high-confidence suspicious (lab verdict: malicious)
- Reasons: temp execution + unusual parent + download/pipe behavior

### 2) Webshell Simulation Scenario

Input characteristics:

- name: sh
- path: /tmp/run
- parent: nginx
- cmdline: wget ... -O- | sh

Observed result:

- Score: 7
- Verdict: high-confidence suspicious (lab verdict: malicious)
- Reasons: temp execution + unusual parent + download/pipe behavior

### 3) Evasion-Style Base64 Scenario

Input characteristics:

- name: bash
- path: /dev/shm/.cache
- parent: apache2
- cmdline: echo ... | base64 -d | sh

Observed result:

- Score: 6
- Verdict: high-confidence suspicious (lab verdict: malicious)
- Reasons: temp execution + unusual parent + base64 decoding behavior

### 4) Real Osquery Process Sample (Normal Activity)

Input source command:

```bash
osqueryi "SELECT name, path, parent, cmdline FROM processes LIMIT 5;" --json > test_data.json
```

Observed result:

- systemd and kernel workers correctly returned benign
- Score: 0
- Reason: Known system/kernel process

This confirmed false-positive reduction without losing malicious detection coverage.

## Enhancements Added

- Added /dev/shm temp-path detection
- Added suspicious base64 decode-chain detection
- Added system/kernel allow logic for noise suppression
- Added benign verdict for score 0
- Updated parser to handle list-based Osquery JSON
- Kept explainable reason strings for analyst readability

## Detection Logic Explanation

The design uses behavior-based weighted scoring instead of signatures.

Why this is useful:

- Multiple weak signals combine into higher-confidence triage
- Explanations are returned with each verdict for SOC transparency
- Tuning can be iterative (change weights/rules without rewriting everything)

This is the key Day 1 shift: manual analyst reasoning translated into reusable automation logic.

## Detection Model Characteristics

- Stateless analysis (no historical correlation)
- Single-event evaluation
- No cross-process lineage tracking yet

## Known Limitations

- Does not account for legitimate temp execution (for example, dev scripts or installers)
- No user/context awareness (UID, TTY, session)
- No environment awareness (container vs host)
- No external enrichment (IP/domain reputation)

## Future Improvements

- Add process lineage tracking (parent to grandparent chains)
- Integrate user/session context (UID and login source)
- Add external enrichment (VirusTotal and IP intelligence)
- Convert scoring to explicit rule confidence levels
- Trigger automated response actions (kill process, alert, isolate host)

## Key Terms

- SOAR: Security Orchestration, Automation, and Response
- Orchestration: coordinating multi-step workflows
- Detection automation: code-driven behavioral triage
- False positive tuning: reducing benign alert noise
- Behavioral scoring: weighted decision model using multiple indicators
- Explainable output: verdicts with clear reasoning

## My Takeaways

- Automation quality depends on both detection coverage and noise control.
- A strong Day 1 engine must ingest real telemetry formats, not only handcrafted samples.
- Kernel/system process awareness is mandatory to avoid alert fatigue.
- Explainable outputs make analyst handoff and tuning much faster.

## Day 1 Completion Checklist

- [x] SOAR fundamentals understood
- [x] Python detection automation built
- [x] Temp execution detection (/tmp, /dev/shm)
- [x] Base64 detection added
- [x] Webshell scenario validated
- [x] Multi-process Osquery JSON ingestion implemented
- [x] False-positive tuning pass completed
- [x] JSON output generated

## Next Up

Week 5 Day 2 - API Integration and Threat Enrichment (IP/domain/hash context for stronger automated decisions).
