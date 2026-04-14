# Week 4 Day 1 - Process Analysis (Osquery)

This module captures my Week 4 Day 1 learning on endpoint process analysis using Osquery to identify abnormal behavior and distinguish legitimate from suspicious activity.

## Day Objective

Today I shifted focus from network-layer detection to the endpoint.

By the end of Day 1, I wanted to be able to:

- Enumerate running processes and establish a baseline
- Map parent-child process relationships
- Identify processes making outbound network connections
- Detect execution from non-standard and attacker-controlled directories
- Write a custom detection query targeting high-risk endpoint behavior

## Concept in Practical Terms

Not all threats announce themselves on the network. Some stay entirely on the endpoint — living off the land, executing from temp directories, or hiding inside normal-looking process trees.

Osquery gives me a SQL-style interface into live endpoint telemetry. I can query processes, open sockets, files, and more as if I am running SELECT statements against a database. This makes it easier to write repeatable, structured detection logic instead of grepping through raw output.

The mindset shift for me today:

Understanding what normal looks like is the starting point for detecting what is not.

## What I Ran and What I Learned

### 1. Process Enumeration

```sql
SELECT pid, name, path, cmdline FROM processes;
```

This gave me a full list of running processes — PIDs, names, binary paths, and command-line arguments. I used this as my baseline. Nothing unusual stood out. Standard Linux system services, kernel threads, and my own interactive session were all visible and expected.

### 2. Parent-Child Relationship Analysis

```sql
SELECT 
  p.pid, 
  p.name, 
  p.parent, 
  pp.name AS parent_name 
FROM processes p
LEFT JOIN processes pp ON p.parent = pp.pid;
```

Process lineage matters. Malware often manipulates parent-child relationships — for example, a Word document spawning PowerShell — because those chains are easy to flag.

In my case, the chain I expected was:

```
systemd → sshd → bash → osqueryi
```

That is exactly what I saw. A standard interactive SSH session with no anomalies in the lineage.

### 3. Network-Linked Process Analysis

```sql
SELECT 
  p.pid, 
  p.name, 
  s.remote_address, 
  s.remote_port 
FROM processes p
JOIN process_open_sockets s ON p.pid = s.pid;
```

I joined processes against open sockets to see which processes had active network connections. No meaningful outbound connections were observed. No evidence of command-and-control (C2) activity. This is what I would look at first in a real triage — any process unexpectedly phoning home is immediately worth investigating.

### 4. Suspicious Path Detection

```sql
SELECT pid, name, path 
FROM processes 
WHERE path LIKE '/tmp/%'
   OR path LIKE '/dev/shm/%'
   OR path LIKE '/var/tmp/%';
```

Attackers frequently drop payloads into writable temp directories because those locations are often not monitored and do not require elevated privileges to write to. `/dev/shm` in particular is a common fileless staging area.

No results came back, which ruled out temp-based payload execution on this endpoint.

### 5. Baseline Deviation Detection

```sql
SELECT pid, name, path 
FROM processes 
WHERE path NOT LIKE '/usr/%'
  AND path NOT LIKE '/bin/%'
  AND path NOT LIKE '/sbin/%'
  AND path NOT LIKE '/lib/%';
```

This query inverts the logic — instead of looking for known-bad paths, I looked for anything outside the standard binary directories. The only result was `/opt/osquery/bin/osqueryd`, which is a legitimate but non-standard path. That is expected and easily explained. No other anomalies were found.

### 6. Custom Detection Query

I wrote this as a high-confidence detection for a specific attacker technique: process executing from a temp directory and making an outbound network connection.

```sql
SELECT 
  p.pid, 
  p.name, 
  p.path, 
  s.remote_address, 
  s.remote_port
FROM processes p
JOIN process_open_sockets s 
  ON p.pid = s.pid
WHERE (
  p.path LIKE '/tmp/%'
  OR p.path LIKE '/dev/shm/%'
  OR p.path LIKE '/var/tmp/%'
)
AND s.remote_address != '';
```

A process running from `/tmp` or `/dev/shm` AND making a network connection is a strong behavioral indicator. Combined, these two conditions narrow the noise significantly. This is the kind of logic I would want running continuously in a real detection pipeline.

## Behavioral Classification

What I observed across all queries:

**User Activity**
- `sshd → bash → osqueryi` — legitimate interactive administrative session, nothing unexpected

**System Activity**
- Kernel threads: `kworker`, `kthreadd`
- Services: `systemd`, `cron`, `dbus-daemon`
- All expected background operations

**Suspicious Activity**
- None identified

## Final Assessment

Process analysis revealed only legitimate system and user-driven activity. No processes were executing from non-standard directories. No suspicious parent-child chains were present. No outbound connections linked to unrecognized processes. No persistence mechanisms or C2 behavior was observed.

Absence of evidence is still a finding — it rules out several common attacker techniques and narrows investigation scope.

## Skills Demonstrated

- Process enumeration and endpoint baseline building
- Parent-child relationship mapping in a process tree
- Joining processes with open socket data for network-linked triage
- Execution path validation against known-good directories
- Custom detection query development targeting high-confidence behaviors

## Key Terms

- **Osquery**: open-source tool that exposes OS data via SQL-based queries
- **Process lineage**: the parent-child chain of a running process
- **C2 (command-and-control)**: communication channel between malware and attacker infrastructure
- **Fileless staging**: executing payloads from memory-mapped locations like `/dev/shm` without writing to disk
- **Baseline deviation**: any process behavior that falls outside expected normal activity
- **Living off the land**: attacker technique using legitimate system tools to avoid detection

## My Takeaways

What clicked for me today:

- Baselines come first — I cannot detect abnormal without knowing what normal looks like
- Context separates signals from noise: user processes, system processes, and suspicious processes require different responses
- Joining Osquery tables unlocks behavioral detection that single-table queries cannot find
- Temp directory execution combined with network activity is a high-confidence detection pattern worth engineering toward
- Detection logic should focus on behavior, not just static indicators like hashes or IPs

## Next Up

Day 2 — Endpoint Behavioral Hunting
