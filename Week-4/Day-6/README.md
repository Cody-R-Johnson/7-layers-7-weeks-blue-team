# Week 4 Day 6 - Endpoint Detection Engineering (Build Your Own Detections)

This module captures my Week 4 Day 6 work turning endpoint hunting observations into repeatable detection logic using Osquery.

## Day Objective

Today I focused on moving from manual hunts to engineered detections.

By the end of this lab, I wanted to be able to:

- Convert hunt hypotheses into detection rules/queries
- Prioritize high-value endpoint signals from Days 3-5
- Reduce false positives with context-based filtering
- Document detection coverage and known blind spots
- Produce a SOC-ready conclusion even when data collection is noisy

## Concept in Practical Terms

Hunting answers:

- What is happening right now?

Detection engineering answers:

- How do I reliably catch this again tomorrow?

The mindset shift is from one-time investigation to continuous, repeatable logic.

## Detection Design Inputs (From Previous Days)

I used prior findings as baselines:

- Day 3: process lineage and timeline context
- Day 4: persistence mechanisms (cron/startup/SSH keys/SUID)
- Day 5: fileless indicators (command-line, interpreters, null-path process context)

These gave me a clean baseline and clear attacker behavior patterns to detect.

## Detection Strategy

I designed detections around four categories:

1. Execution Abuse
- suspicious command-line patterns
- shell chaining and encoded content

2. Persistence Changes
- cron entries from risky paths
- unexpected startup/service execution origin

3. Privilege/Access Abuse
- SSH authorized keys changes
- suspicious SUID placement

4. Context Correlation
- parent-child chain quality
- user context and execution path

## Engineered Detection Queries

### A) Suspicious Inline Command Execution

```sql
SELECT pid, parent, name, path, cmdline
FROM processes
WHERE cmdline LIKE '%bash -c%'
   OR cmdline LIKE '%curl%|%bash%'
   OR cmdline LIKE '%wget%|%sh%'
   OR cmdline LIKE '%base64 -d%'
   OR cmdline LIKE '%nc -e%';
```

Why this matters:

- Targets common in-memory payload launch patterns.

Tuning notes:

- Filter known admin automation accounts.
- Review parent process and terminal context before escalation.

### B) Interpreter Abuse With Parent Context

```sql
SELECT
  p.pid,
  p.name,
  p.path,
  p.cmdline,
  p.parent,
  pp.name AS parent_name,
  pp.cmdline AS parent_cmdline
FROM processes p
LEFT JOIN processes pp
  ON p.parent = pp.pid
WHERE p.name IN ('bash','sh','python','perl')
  AND (
    p.cmdline LIKE '%-c%'
    OR p.cmdline LIKE '%base64%'
    OR p.cmdline LIKE '%http%'
  );
```

Why this matters:

- Interpreters are normal tools but frequent attacker launch points.

Tuning notes:

- Exclude known package-install and provisioning scripts.
- Raise priority when parent is unusual for that host role.

### C) Cron Persistence in Risky Locations

```sql
SELECT minute, hour, day_of_month, month, day_of_week, command, path
FROM crontab
WHERE command LIKE '%/tmp/%'
   OR command LIKE '%/dev/shm/%'
   OR command LIKE '%/home/%'
   OR command LIKE '%curl%'
   OR command LIKE '%wget%';
```

Why this matters:

- Detects likely attacker persistence scheduling.

Tuning notes:

- Most baseline cron jobs should remain in trusted system paths.

### D) Startup/Service Path Risk Filter

```sql
SELECT name, path, type, source, status
FROM startup_items
WHERE path LIKE '/tmp/%'
   OR path LIKE '/dev/shm/%'
   OR path LIKE '/home/%'
   OR path LIKE '/var/tmp/%';
```

Why this matters:

- File location often signals risk faster than service name.

Tuning notes:

- Validate dev tooling exceptions in lab environments.

### E) SSH Key Persistence Visibility

```sql
SELECT uid, key, path
FROM authorized_keys;
```

Why this matters:

- Key insertion is a stealth persistence favorite.

Tuning notes:

- Compare against known-good user key baseline.

### F) SUID Drift Hunting (Constrained Paths)

```sql
SELECT path, mode, uid, gid
FROM file
WHERE directory IN ('/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin','/usr/local/sbin')
  AND mode LIKE '4%';
```

Why this matters:

- Detects privilege escalation opportunities and unauthorized SUID changes.

Tuning notes:

- Alert on new or moved SUID binaries outside approved directories.

## Detection Logic I Would Alert On

High-confidence alert conditions:

- Interpreter process with `-c` plus network retrieval pattern
- Cron command executing from `/tmp` or `/dev/shm`
- Startup item launching from user-writable paths
- New authorized key for privileged account outside maintenance window
- New SUID binary in non-standard location

Medium-confidence conditions (require analyst triage):

- Repeated shell execution with ambiguous command-line
- Legitimate tool usage from unusual parent process

## False Positive Control

I built tuning around:

- baseline-aware filtering
- parent-child context
- path-based risk scoring
- maintenance window awareness
- analyst notes for recurring benign patterns

SOC impact:

- Better detection coverage without creating alert fatigue.

## Handling the "Bumpy" Collection Session

Collection was noisy due to repeated session import attempts, but the validated output still supported engineering decisions.

How I handled it:

- Used only consistent, repeatable query results
- Avoided conclusions from incomplete fragments
- Anchored final logic to stable baseline observations from Days 3-5

## Exercise Responses

### Exercise 1 - Build a Detection for Fileless Execution

Built command-line and interpreter detections targeting inline shell execution, payload retrieval, and encoded command patterns.

### Exercise 2 - Build a Detection for Persistence

Built cron and startup path-risk detections focused on user-writable or transient directories.

### Exercise 3 - Build a Detection for Privilege Abuse

Built SUID drift and SSH key visibility checks to detect stealth privilege and access persistence.

### Exercise 4 - Tuning and False Positives

Applied filters for expected admin workflows, known tools, and baseline host behavior to keep signal quality high.

### Exercise 5 - Real-World Scenario

Scenario: attacker uses fileless execution, then adds persistence and privileged re-entry.

Coverage built:

- command-line + interpreter abuse
- cron/startup persistence
- key/SUID privilege-access persistence

Assessment:

Detection coverage is now layered across execution, persistence, and privilege paths, improving resilience against single-technique evasion.

## Scenario-Based Q and A

Q: Why is one query never enough?
A: Attackers chain techniques. Single-query logic misses multi-step behavior.

Q: What is the strongest pivot for endpoint detection engineering?
A: Parent-child lineage plus command-line intent and execution path.

Q: How do I avoid over-alerting on normal admin activity?
A: Keep a baseline, apply context filters, and score by path + behavior rather than tool name alone.

## Mini Challenge Reflection

The biggest gain for me was translating hunting into repeatable logic. Instead of saying "it looks clean right now," I can now say "this is the detection coverage I built to catch it next time." That feels much closer to real SOC engineering work.

## Key Terms

- Detection engineering: Designing repeatable logic to identify malicious behavior
- Coverage: The set of attacker techniques a detection can observe
- Tuning: Reducing false positives while preserving useful signal
- Drift: Changes from baseline that may indicate compromise
- Context enrichment: Adding lineage, path, and user/session details to improve decisions

## My Takeaways

- Great hunts should become reusable detections.
- Path plus lineage is often stronger than process name alone.
- Baseline knowledge is mandatory for high-confidence triage.
- Detection quality depends on both coverage and precision.
- Even with rough collection sessions, disciplined validation keeps conclusions solid.

## Submission Summary

### Detection Rules/Queries Built

- Suspicious inline command execution query
- Interpreter abuse with parent context query
- Cron risky-path persistence query
- Startup risky-path persistence query
- Authorized SSH key visibility query
- SUID drift hunting query

### Suspicious Findings (or Justification of None)

No active malicious endpoint behavior was confirmed during this collection window. Existing observations remained consistent with baseline administrative and system activity.

### Final Statement

Engineered endpoint detections were successfully built for fileless execution, persistence, and privilege-abuse scenarios. No confirmed indicators of compromise were identified in validated session evidence, and detection coverage for future activity was substantially improved.

### Concepts

- Detection engineering lifecycle
- Behavioral query design
- Baseline-aware tuning
- Coverage mapping across attacker stages

### Skills

- Translating hunts into repeatable detections
- Building layered endpoint query logic
- Reducing false positives through context
- Writing SOC-defensible detection outcomes

## Next Up

Day 7 - Week 4 Capstone: Endpoint Investigation and Defensive Reporting
