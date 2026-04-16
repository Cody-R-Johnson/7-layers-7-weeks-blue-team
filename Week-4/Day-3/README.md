# Week 4 Day 3 - Timeline and Attack Reconstruction

This module captures my Week 4 Day 3 investigation using Osquery to reconstruct process activity as a timeline instead of treating events in isolation.

## Day Objective

Today I focused on sequence-based endpoint analysis.

By the end of this lab, I wanted to be able to:

- Build a timeline from process start times
- Reconstruct parent-child execution chains
- Separate user-driven behavior from attacker-like behavior
- Correlate process activity with network activity
- Write a clear reconstruction narrative, even on a clean system

## Concept in Practical Terms

A single process is rarely enough to make a strong detection decision.

The key question is not: "Is this process bad?"

The key question is: "What sequence does this process belong to?"

Timeline reconstruction means connecting:

- Initial action
- Follow-on process activity
- Network behavior
- Potential persistence outcomes

That approach is what turns endpoint telemetry into incident response evidence.

## Query Output Summaries

### A) Process Start-Time Timeline

```sql
SELECT pid, parent, name, path, cmdline, start_time
FROM processes
ORDER BY start_time ASC;
```

Summary:

- Early entries were expected system and kernel processes (`systemd`, `kthreadd`, `kworker` variants).
- User-session sequence appeared later and in a logical order.
- Key interactive chain identified near the end of the timeline:
  - `sshd` (listener)
  - `sshd: cody [priv]`
  - `sshd: cody@pts/0`
  - `bash`
  - `script my_session.txt`
  - `bash -i`
  - `osqueryi`

Assessment:

Timeline ordering is consistent with normal remote admin usage over SSH followed by live endpoint investigation.

### B) Parent-Child Reconstruction

```sql
SELECT
  p.pid,
  p.name,
  p.parent,
  pp.name AS parent_name,
  p.cmdline,
  p.start_time
FROM processes p
LEFT JOIN processes pp
  ON p.parent = pp.pid
ORDER BY p.start_time ASC;
```

Summary:

- Parent-child mapping validated session flow from daemon to user shell.
- High-value chain from the dataset:
  - `sshd` -> `sshd` (privileged session) -> `sshd` (user session) -> `bash` -> `script` -> `bash` -> `osqueryi`

Assessment:

No suspicious lineage like interpreter-driven download/execute behavior was observed. Parent-child relationships match expected interactive activity.

### C) Late-Stage / Recently Started Processes

```sql
SELECT pid, name, path, cmdline, start_time
FROM processes
ORDER BY start_time DESC
LIMIT 20;
```

Summary:

Most recent processes were:

- `osqueryi` (`/opt/osquery/bin/osqueryd`)
- `script` (`script my_session.txt`)
- `bash -i`
- Active SSH session processes for user `cody`

Assessment:

Recent process activity aligns with my own analysis workflow. No newly started unknown binaries required escalation.

### D) Processes With Network Connections

```sql
SELECT
  p.pid,
  p.parent,
  p.name,
  p.cmdline,
  s.remote_address,
  s.remote_port
FROM processes p
JOIN process_open_sockets s
  ON p.pid = s.pid
WHERE s.remote_address != '';
```

Summary:

- No rows returned in this session output.

Assessment:

No network-correlated process activity was detected at collection time. This reduces likelihood of active command-and-control or outbound exfiltration during the observed window.

### E) Suspicious Execution Paths in Timeline Context

```sql
SELECT pid, parent, name, path, cmdline, start_time
FROM processes
WHERE path LIKE '/tmp/%'
   OR path LIKE '/dev/shm/%'
   OR path LIKE '/var/tmp/%'
ORDER BY start_time ASC;
```

Summary:

- No rows returned in this session output.

Assessment:

No evidence of temp-directory execution or staged payload launch from common attacker-controlled writable paths.

## Exercise Responses

### Exercise 1 - One Benign Process Chain as a Story

An SSH session was established to the host, then user `cody` authenticated and entered a shell. From that shell, I started `script my_session.txt` to record the terminal session, opened an interactive `bash` shell, and launched `osqueryi` to investigate endpoint activity. This chain reflects normal administrative and investigation behavior.

### Exercise 2 - Recent Activity Review

Most recent processes were `osqueryi`, `script`, `bash -i`, and active `sshd` session processes tied to user access. These are directly tied to my own actions during the lab and do not indicate attacker execution.

### Exercise 3 - Suspicious-Looking but Benign Chain

Chain:

`bash -> script -> bash -> osqueryi`

Why it could look suspicious:

- It is a shell-chained sequence.
- It includes scripted session control before additional execution.
- It could be mistaken for staged or automated attacker activity without context.

Why it is benign here:

- `script` was intentionally used to record the lab session.
- Follow-on execution was an interactive shell, not hidden payload execution.
- Final process was `osqueryi`, a legitimate endpoint investigation tool.

### Exercise 4 - Network-Correlated Timeline

No network-correlated process activity was identified by the join query in this dataset. This rules out observable active outbound process communications during the captured session.

## Timeline Reconstruction

1. Initial access / session activity:
SSH listener accepted a remote connection, followed by authentication stages (`sshd` processes for privileged and user session).

2. User or parent process involved:
User `cody` session transitioned into a user shell (`bash`) after successful login.

3. Child process activity:
From `bash`, I launched `script my_session.txt`, then `bash -i`, and then `osqueryi` for endpoint inspection.

4. Network activity observed:
No outbound network-correlated process activity observed in the query output.

5. Persistence observed:
No persistence mechanism indicators identified in this session evidence.

6. Final assessment:
Observed activity is consistent with legitimate SSH-based administrative use and investigative endpoint querying. No indicators of compromise were identified in the captured process timeline.

## Scenario-Based Q and A

Q: What was the best anchor event in this dataset?
A: The interactive `osqueryi` launch near the end of the timeline was the clearest anchor. Tracing backward from it exposed the full SSH-to-shell chain.

Q: Did any process sequence suggest execution from suspicious locations?
A: No. Temp-path hunting (`/tmp`, `/dev/shm`, `/var/tmp`) returned no process results.

Q: Did process plus network correlation support a compromise hypothesis?
A: No. The network join returned no rows, so there was no evidence of active outbound process communication in this collection window.

## Mini Challenge Reflection

The biggest skill gain for me was converting raw process output into an ordered narrative. I also learned that "suspicious-looking" and "malicious" are different: the `bash -> script -> bash -> osqueryi` chain can look risky until context confirms investigator-driven behavior.

## Key Terms

- Timeline reconstruction: Rebuilding event sequence from endpoint artifacts
- Parent-child lineage: Process ancestry used to identify execution context
- Anchor event: The starting suspicious or high-value event used to pivot backward/forward
- Correlation window: Time alignment between process and network activity
- Narrative precision: Writing findings in defensible, sequence-based language

## My Takeaways

- Sequence beats single indicators.
- Clean output is still a finding when it rules out common attacker behavior.
- Parent-child and start-time context are essential for triage quality.
- I should always explain why suspicious-looking behavior is benign when evidence supports it.


### Concepts
- Process sequencing
- Parent-child reconstruction
- Narrative-based investigation
- Correlating execution with network activity

### Skills
- Building endpoint timelines
- Distinguishing benign vs suspicious chains
- Writing analyst-quality reconstructions

## Next Up

Day 4 - Persistence Mechanisms
