# Week 4 Day 7 - False Positive Tuning (Production-Ready Detections)

This module captures my final Week 4 work turning endpoint detections into SOC-usable logic with lower noise and higher confidence.

## Day Objective

Today I focused on the real detection engineering goal: reducing alert fatigue while still catching meaningful attacker behavior.

By the end of Day 7, I wanted to be able to:

- Tune detections by removing known false-positive patterns
- Add context (parent process, network behavior) to improve confidence
- Build one high-fidelity detection that is practical for SOC use
- Explain tradeoffs, including what my detection might miss
- Decide when detections should alert vs log-only

## Concept in Practical Terms

In production SOC operations, missed detections are bad, but noisy detections can be worse because analysts stop trusting the signal.

My job is not to detect everything.

My job is to detect the right things with minimal noise.

Common false-positive sources I accounted for:

- Legitimate admin commands during maintenance
- System processes like cron and systemd
- Package managers and automation tools
- Monitoring agents with expected network traffic

## Tuned Detection (Submission Requirement 1)

I tuned a noisy `bash -c` detection by excluding known benign patterns:

```sql
SELECT pid, name, cmdline
FROM processes
WHERE cmdline LIKE '%bash -c%'
  AND cmdline NOT LIKE '%apt%'
  AND cmdline NOT LIKE '%snap%'
  AND cmdline NOT LIKE '%systemd%'
  AND cmdline NOT LIKE '%cron%';
```

Why this is better:

- Keeps visibility for suspicious inline shell execution
- Removes common package manager and system service noise
- Reduces scheduled-task related command churn

## High-Fidelity Detection (Submission Requirement 2)

I combined execution path, command behavior, parent context, and network activity:

```sql
SELECT 
  p.pid,
  p.name,
  p.path,
  p.cmdline,
  pp.name AS parent_name,
  s.remote_address
FROM processes p
LEFT JOIN processes pp
  ON p.parent = pp.pid
LEFT JOIN process_open_sockets s
  ON p.pid = s.pid
WHERE (
  p.path LIKE '/tmp/%'
  OR p.cmdline LIKE '%bash -c%'
)
AND pp.name = 'bash'
AND s.remote_address != ''
AND p.cmdline NOT LIKE '%apt%'
AND p.cmdline NOT LIKE '%snap%';
```

Why this is high confidence:

- Focuses on suspicious execution origin (`/tmp`) or inline shell behavior
- Requires shell-based process chain context
- Requires active remote network behavior
- Excludes frequent benign package-management activity

## False Positives Removed (Submission Requirement 3)

I explicitly removed noise from:

- `apt` and `snap` package update/install workflows
- system service command execution (`systemd`)
- scheduled task related shell usage (`cron`)

This improved detection coverage quality and lowered expected alert fatigue.

## What My Detection Might Miss (Submission Requirement 4)

Tradeoffs:

- Attacker execution from trusted paths like `/usr/bin` instead of `/tmp`
- Renamed binaries or tool substitution to evade name-based logic
- Very short-lived fileless activity between collection intervals
- Attacks that do not create outbound network connections

This is the key tuning reality: better precision can reduce visibility for some evasive edge cases.

## Alert vs Log Decision (Submission Requirement 5)

I would configure this way:

### Trigger Alert (High Confidence)

- Temp-path or inline-shell execution
- Parent is `bash`
- Active remote connection exists

### Log Only (Lower Confidence)

- `bash -c` usage with no suspicious child/process-chain context
- cron entries that are unusual but not clearly malicious
- single weak indicators with no supporting telemetry

This split keeps triage focused on high-signal behavior and preserves lower-confidence data for correlation windows.

## Scenario-Based Q&A

Q: Why not alert on every `bash -c` execution?
A: Because it burns analyst time on normal operations and reduces trust in detections.

Q: What made the high-fidelity rule SOC-grade?
A: It required multiple aligned signals (execution behavior, parent context, network activity) before generating a high-confidence event.

Q: What is the most important tuning question after writing a rule?
A: "What could this miss?" because every filter is a coverage tradeoff.

## Mini Challenge Reflection

The biggest shift for me was learning that a detection is only successful when analysts can actually use it at scale. I can now move from one-off hunts to repeatable logic that balances detection coverage with practical triage workload.

## Key Terms

- False positive: benign activity incorrectly flagged as malicious
- Alert fatigue: analyst desensitization from high alert volume
- Detection tuning: refining logic to improve signal quality
- High-fidelity detection: multi-condition logic with stronger confidence
- Correlation window: time span used to link related activity
- Coverage tradeoff: precision gains that may reduce visibility in edge cases

## My Takeaways

- Tuning is part of detection engineering, not a cleanup step.
- High-confidence alerts should require behavioral context, not a single keyword.
- Logging lower-confidence indicators still matters for correlation.
- I should always document both what a rule catches and what it can miss.

## Week 4 Final Assessment Snapshot

Week 4 is complete.

Skills consolidated:

- Process analysis
- Behavioral hunting
- Timeline reconstruction
- Persistence detection
- Fileless detection
- Detection engineering
- False-positive tuning


## Next Up

Week 5 Day 1 - Security Automation (SOAR fundamentals, scripting mindset, and automated response workflow design).

Ready for Week 5.