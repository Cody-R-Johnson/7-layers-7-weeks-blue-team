# Week 4 Day 4 - Persistence Mechanisms (Osquery)

This module captures my Week 4 Day 4 endpoint persistence investigation using Osquery. The focus was to determine whether any mechanism could re-trigger attacker access after reboot or logout.

## Day Objective

Today I focused on persistence-focused endpoint hunting.

By the end of this lab, I wanted to be able to:

- Enumerate scheduled and startup-based execution points
- Validate whether SSH key-based access persistence exists
- Check for SUID-based privilege persistence opportunities
- Distinguish baseline system behavior from attacker footholds
- Write a defensible SOC-style conclusion when findings are clean

## Concept in Practical Terms

Persistence is how an attacker ensures access continues after the initial compromise.

Instead of asking, "Is this process malicious?" I used the detection mindset question:

"Will this execute again automatically?"

That shifted my analysis toward:

- Scheduled execution (cron)
- Service/startup execution (systemd and startup items)
- Access persistence (authorized SSH keys)
- Privilege persistence (SUID binaries)

## Query Evidence and Analysis

### A) Cron Jobs

```sql
SELECT * FROM crontab;
```

Observed:

- Hourly, daily, weekly, and monthly jobs from `/etc/crontab`
- `e2scrub_all` entries from `/etc/cron.d/e2scrub_all`
- `debian-sa1` entries from `/etc/cron.d/sysstat`

interpretation:

- Entries are consistent with expected Debian/Ubuntu maintenance and performance collection behavior.
- I did not observe attacker-style cron patterns such as execution from `/tmp`, `/home`, or `/dev/shm`, encoded commands, or `* * * * *` persistence loops.

Conclusion:

No suspicious attacker-defined cron persistence identified.

### B) Systemd Services / Startup Persistence

Initial query attempted:

```sql
SELECT name, path, status FROM systemd_units WHERE type='service';
```

Result:

- Query failed due to invalid column naming in this schema (`no such column: name`).

Correct query format for this table:

```sql
SELECT unit, fragment_path, state FROM systemd_units WHERE type='service';
```

Recovery query used for persistence coverage:

```sql
SELECT * FROM startup_items;
```

Observed:

- Startup items were present and mostly mapped to expected system directories such as `/etc/init.d/`, `/usr/lib/systemd/`, and `/usr/bin/`.
- Service names aligned with normal OS/service footprint (for example `cron`, `ssh`, `ufw`, `rsyslog`, `osqueryd`, `suricata`).
- Some services were inactive/failed, but location and naming patterns did not indicate stealth persistence.

interpretation:

- No startup entries executing from high-risk locations (`/tmp`, `/dev/shm`, user home paths) were identified.
- No obvious masquerading names or suspicious path/name mismatch patterns were identified.

Conclusion:

No unauthorized startup or service-based persistence identified from collected output.

### C) Authorized SSH Keys

```sql
SELECT * FROM authorized_keys;
```

Observed:

- No rows returned.

interpretation:

- No evidence of key-based persistence or unauthorized remote access foothold via `authorized_keys` in this dataset.

Conclusion:

No SSH key persistence identified.

### D) SUID Binaries (Privilege Persistence)

Query attempted:

```sql
SELECT path, mode FROM file WHERE mode LIKE '4%';
```

Result:

- Query failed because table `file` requires a constrained path predicate in the `WHERE` clause.

Observed from my investigation context:

- Two SUID instances were identified and verified as user-created during lab activity.

interpretation:

- Verified SUID findings were not unauthorized system-level persistence artifacts.
- No additional suspicious SUID behavior was established from this collection.

Conclusion:

No confirmed attacker-driven SUID persistence identified.

## Exercise Responses

### Exercise 1 - Cron Analysis

All observed cron jobs were baseline maintenance/monitoring jobs. No suspicious paths, no encoded payloads, and no high-frequency attacker-style scheduling patterns were found.

### Exercise 2 - Systemd Hunting

Primary systemd query had a column mismatch issue, but startup persistence visibility was recovered through `startup_items`. Observed services/startup items matched expected system locations and naming.

### Exercise 3 - SSH Backdoor Detection

No authorized SSH keys were present in query output. No unknown key-based access method was identified.

### Exercise 4 - Privilege Persistence

SUID findings were reviewed and verified as expected lab-related binaries. No unexplained SUID binaries outside normal trust expectations were confirmed.

### Exercise 5 - Real-World Scenario

Scenario: an attacker wants to maintain silent long-term access.

What I checked and ruled out:

- Cron-based persistence: ruled out from observed jobs
- Startup/service persistence: no anomalous startup patterns observed
- SSH key persistence: no keys identified
- Privilege persistence via SUID: no unauthorized indicators confirmed

Assessment:

No persistence mechanism indicative of compromise was identified in this dataset.

## Scenario-Based Q and A

Q: What was the key analyst mindset for this lab?
A: I focused on repeat execution conditions, not just whether a single process looked suspicious.

Q: What mattered most when the startup list was very long?
A: Filtering by risk indicators: unusual paths, suspicious naming, and user-writable execution locations.

Q: Why are "inactive" or "disabled" services still worth noting?
A: They can still represent attempted persistence and can be re-enabled later.


## Key Terms

- Persistence: Mechanisms that survive reboot/logout to retain attacker access
- Scheduled execution: Recurring command execution via cron/timers
- Service persistence: Startup logic through systemd/init components
- Key-based persistence: Unauthorized SSH key insertion for silent access
- Privilege persistence: SUID or similar mechanisms enabling elevated re-entry

## My Takeaways

- Clean results still need strong justification.
- Baseline jobs can look suspicious until validated with platform context.
- Path-based triage is one of the fastest ways to prioritize persistence review.
- Query/schema handling matters because technical mistakes can hide real findings.

## Submission Summary

### Results from Required Areas

- Cron: Baseline maintenance/monitoring tasks; no malicious scheduling indicators
- Systemd/Startup: No anomalous startup execution paths or suspicious service patterns identified
- Authorized keys: No entries returned
- SUID binaries: Two identified and verified as user-created; no unauthorized persistence evidence

### Suspicious Findings (or Justification of None)

No persistence indicators of compromise were identified after reviewing cron, startup/service behavior, SSH key persistence, and SUID findings with path- and context-based validation.

### Final Statement

Persistence mechanisms were not identified based on the collected endpoint evidence, and observed behavior is consistent with expected system baseline activity.

### Concepts

- Persistence techniques
- Scheduled execution
- Service-based persistence
- Access persistence (SSH keys)

### Skills

- Identifying attacker footholds
- Verifying startup behavior
- Detecting stealth persistence

## Next Up

Day 5 - Memory and Fileless Detection
