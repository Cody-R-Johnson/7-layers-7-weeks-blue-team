# Week 5 Day 5 - Controlled Automated Response (Containment Simulation to Safe Execution)

This module captures the shift from response simulation to controlled, auditable response execution in a SOAR pipeline.

The key objective was not to make actions more aggressive, but to make them safer. In real SOC automation, taking action without controls causes outages. Day 5 focuses on guardrails first, execution second.

## Day Objective

Today I extended the Day 4 case-and-routing pipeline with a controlled response engine.

By the end of this day, I wanted to:

- Move from `auto_response` simulation to explicit controlled execution logic
- Add safety checks before any action path is considered
- Add approval gates for high-risk actions
- Add dry-run mode so execution can be validated safely
- Simulate command construction with process context (PID)
- Add auditable execution metadata (`executed_by`, timestamps, reasons)
- Split action logging into successful and failed execution streams

## Concept in Practical Terms

Before Day 5:

Detection -> Enrichment -> Decision -> Case -> Routing -> Simulated response

After Day 5:

Detection -> Enrichment -> Decision -> Case -> Routing -> Controlled response execution

The practical change is this:

- Before: "We would isolate this host"
- Now: "We checked policy and safety conditions, evaluated approval state, generated an auditable command in dry-run mode, then logged a controlled execution decision"

## Day 5 Architecture

Day 5 adds a dedicated execution layer:

- `responder.py`: response execution engine with safety checks, approval gate, dry-run support, command simulation, and split logging
- `success.log`: JSONL log of successful execution decisions
- `failed.log`: JSONL log of blocked or non-executable decisions

And Day 4 components continue to feed this layer:

- `analyzer.py`: orchestrates scoring, case creation, routing, auto-response simulation, then execution call
- `case.py`: includes PID in evidence to support command simulation
- `router.py`: still drives queue, priority, SLA, and ownership

## Execution Design

Execution follows a strict sequence:

1. Build baseline execution metadata (`timestamp`, `case_id`, `severity`, `executed_by`, `dry_run`)
2. Run `safety_check(case)`
3. Enforce approval gate for critical cases
4. Select response action by severity / recommended action
5. Generate simulated command string using case evidence (PID-aware)
6. Enforce dry-run mode behavior
7. Write structured outcome to `success.log` or `failed.log`
8. Attach execution result back to the case object

This keeps the system auditable and deterministic while remaining non-destructive.

## Guardrails Implemented

- No action for informational severity
- Protected process safeguard (`systemd`, `init`)
- Critical-severity approval gate (`approved` required)
- Dry-run mode default (`DRY_RUN = True`)
- Full decision logging for every execution attempt
- Actor attribution via `executed_by = "soar_engine"`

## Exercise Implementation Summary

### Exercise 1 - Approval Gate

Implemented in `execute_response(case)`:

- If severity is critical and case is not approved, execution is blocked
- Result includes explicit reason: `Awaiting approval for critical response`

### Exercise 2 - Dry Run Mode

Implemented global:

- `DRY_RUN = True`

When enabled:

- Action is marked executed in `dry_run` mode
- No real system command runs
- Message states command was simulated only

### Exercise 3 - PID Command Simulation

Added PID-aware command generation:

- `collect_context` -> `SIMULATED: collect-context --pid <pid>`
- `isolate_host` -> `SIMULATED: isolate-host --target current_host`
- Optional `kill_process` mapping placeholder -> `SIMULATED: kill -9 <pid>`

### Exercise 4 - executed_by Attribution

Execution results include:

- `executed_by: "soar_engine"`

This supports accountability and audit traceability.

### Exercise 5 - Split Success / Failure Logs

Replaced single response log with split logs:

- Executed results -> `success.log`
- Blocked or unmatched results -> `failed.log`

This allows clean operational dashboards and review workflows.

## Data Model Changes

To support execution context:

- `analyzer.py` adds `pid` into `analysis_result`
- `case.py` includes `pid` under `evidence`

This allows downstream execution and forensic workflows to consume process identity cleanly.

## Validation Results

Using representative test data (system process, critical curl-pipe payload, medium base64 payload):

- Informational event:
  - blocked by safety policy
  - logged to `failed.log`

- Critical event without approval:
  - blocked by approval gate
  - logged to `failed.log`

- Medium event with `collect_more_context`:
  - executed in dry-run mode
  - command generated with PID (`--pid 5555`)
  - logged to `success.log`

Observed execution object for medium case included:

- `executed: true`
- `action: collect_context`
- `mode: dry_run`
- `command: SIMULATED: collect-context --pid 5555`
- `executed_by: soar_engine`

## End-State Output Snapshot

The final analyzer run showed one actionable medium-severity case in `in_progress` with controlled execution attached.

Key execution fields from `analyzer.py` output:

```json
"execution": {
  "timestamp": "2026-04-30T12:59:55.731914+00:00",
  "case_id": "ecca475e-791c-40bd-af85-92bb6621ec01",
  "severity": "medium",
  "executed_by": "soar_engine",
  "dry_run": true,
  "executed": true,
  "action": "collect_context",
  "mode": "dry_run",
  "command": "SIMULATED: collect-context --pid 5555",
  "message": "DRY RUN: Command was not executed; only simulated."
}
```

`success.log` captured the successful controlled action decision (dry run):

```json
{"timestamp": "2026-04-30T12:59:55.731914+00:00", "case_id": "ecca475e-791c-40bd-af85-92bb6621ec01", "severity": "medium", "executed_by": "soar_engine", "dry_run": true, "executed": true, "action": "collect_context", "mode": "dry_run", "command": "SIMULATED: collect-context --pid 5555", "message": "DRY RUN: Command was not executed; only simulated."}
```

`failed.log` captured blocked decisions:

```json
{"timestamp": "2026-04-30T12:59:55.323772+00:00", "case_id": "e8b92ca3-c9da-44b7-947e-87765fc6ea17", "severity": "informational", "executed_by": "soar_engine", "dry_run": true, "executed": false, "reason": "Informational severity - no action allowed", "command": null}
{"timestamp": "2026-04-30T12:59:55.731419+00:00", "case_id": "733aef68-4fad-40bd-8456-7ddd63284b79", "severity": "critical", "executed_by": "soar_engine", "dry_run": true, "executed": false, "reason": "Awaiting approval for critical response", "command": null}
```

## Overall Change Log (What Was Done)

1. Added controlled response execution layer in `responder.py`.
2. Added safety validation before any execution path.
3. Added critical approval gate (`approved` required).
4. Added dry-run execution mode (`DRY_RUN = True`).
5. Added PID-based command simulation.
6. Added `executed_by` attribution (`soar_engine`).
7. Split action logging into `success.log` and `failed.log`.
8. Integrated execution results into case output as `execution`.
9. Carried PID from input -> analysis -> case evidence for execution context.
10. Validated expected outcomes for informational block, critical approval block, and medium dry-run execution.

End-state pipeline now runs as:

Detection -> Enrichment -> Decision -> Case -> Routing -> Controlled Execution (Safe)

## Completion Criteria Status

- [x] `responder.py` created and integrated
- [x] Safety validation added
- [x] Critical approval gate added
- [x] Dry-run mode added
- [x] PID-based command simulation added
- [x] `executed_by` attribution added
- [x] Split logging to `success.log` and `failed.log`
- [x] `analyzer.py` updated with execution step and PID propagation
- [x] `case.py` updated to carry PID in evidence

## Key Takeaway

Automated response is only valuable when it is controlled, auditable, and safe. The strongest SOC automation does not maximize speed at any cost; it maximizes safe, policy-compliant action.

## Component Reference

| Component | Real SOC Equivalent |
|---|---|
| analyzer.py | SOAR orchestration flow |
| responder.py | Response execution engine |
| safety_check() | Automation guardrail policy |
| approval gate | Human-in-the-loop control |
| dry-run mode | Change-safe validation mode |
| success.log / failed.log | Response audit trails |

## Next Up

Day 6 - Full SOAR Pipeline Integration and Hardening
