# Week 4 Day 2 - Behavioral Hunting (Osquery Advanced)

This module captures my Week 4 Day 2 learning on behavioral anomaly detection using Osquery — moving past basic enumeration into active threat hunting on the endpoint.

## Day Objective

Day 1 gave me a baseline. Day 2 was about proving that baseline holds under scrutiny.

By the end of Day 2, I wanted to be able to:

- Hunt for persistence mechanisms using process start times
- Identify privilege abuse by analyzing root-level processes
- Detect suspicious command-line patterns tied to attacker techniques
- Find rare or anomalous processes using frequency analysis
- Correlate process behavior with network activity for C2 detection

## Concept in Practical Terms

The mindset shift this session was significant for me.

On Day 1 I was looking for obvious red flags — binaries in `/tmp`, unusual parent-child chains. Day 2 pushed me further. Attackers at this stage blend into the environment. They use legitimate tools, mimic system behavior, and avoid anything that triggers a signature-based alert.

What I am actually hunting now is:

**Behavior that does not match normal system usage on THIS system**

Not "what is malicious" globally — but "what is abnormal here."

## Queries I Ran and What I Found

### 1. Persistence Hunt — Process Start Times

```sql
SELECT pid, name, start_time 
FROM processes 
ORDER BY start_time ASC;
```

**What I was looking for:** Processes that have been running for an unusually long time — particularly user-level processes that should not persist across reboots or long sessions.

**What I found:** The oldest processes were all kernel threads and core system components — `systemd`, `kthreadd`, `kworker` variants. User-level processes like `bash`, `sshd`, and `osqueryi` started significantly later, consistent with a single interactive session.

**Assessment:** No evidence of unauthorized persistence. Long-running processes were limited to expected OS-level components.

---

### 2. Privilege Abuse Hunt — Root Processes

```sql
SELECT pid, name, uid, gid 
FROM processes 
WHERE uid = 0;
```

**What I was looking for:** Non-system binaries running as root, which could indicate privilege escalation or misconfigured user processes.

**What I found:** All UID 0 processes were system daemons and kernel services — `systemd`, `sshd`, `cron`, `rsyslogd`, and others. The one entry with a non-zero GID was `login` (GID 1000), which reflects a user context handoff and is expected behavior.

**Assessment:** Elevated privileges were limited to legitimate system services. No anomalous user binaries running as root.

---

### 3. Suspicious Command-Line Hunting

```sql
SELECT pid, name, cmdline 
FROM processes 
WHERE cmdline LIKE '%curl%'
   OR cmdline LIKE '%wget%'
   OR cmdline LIKE '%bash -c%'
   OR cmdline LIKE '%nc%'
   OR cmdline LIKE '%base64%';
```

**What I was looking for:** Command-line arguments associated with download-and-execute patterns, encoded payloads, or reverse shells.

**What I found:**

```
| 4719 | systemd-timesyn | /usr/lib/systemd/systemd-timesyncd |
```

One result — `systemd-timesyncd`. I had run a manual time sync command earlier in the session to fix the system clock, which is why this process was active.

**Context:** `/usr/lib/systemd/systemd-timesyncd` is the system service responsible for NTP time synchronization. My action of correcting the clock triggered or interacted with it, but the process itself is a legitimate system-managed service — not a user-spawned binary.

**Assessment:** `systemd-timesyncd` matched the pattern because its name contains the substring `sync`, which overlaps with the `%nc%` wildcard. This is a false positive driven by a broad wildcard pattern. No malicious command-line activity identified.

---

### 4. Rare Process Frequency Analysis

```sql
SELECT name, COUNT(*) as count 
FROM processes 
GROUP BY name 
ORDER BY count ASC;
```

**What I was looking for:** Processes appearing only once — uncommon binaries that an attacker may have introduced.

**What I found:** Most processes showed `count = 1`. The ones with higher counts were:

- `kworker/R-ext4-`, `kworker/R-kmpat`, `kworker/R-scsi_` → 2 each (kernel threads with multiple instances, expected)
- `psimon` → 2 (process monitor, system-level)
- `systemd` → 2 (user and system instance)
- `bash` → 3 (multiple interactive sessions)
- `sshd` → 3 (listener + active sessions)

**Assessment:** The single-count processes were almost entirely kernel threads and system daemons. Nothing unusual. The key judgment here is that rare alone does not equal suspicious — it has to be rare AND out of context. Everything with `count = 1` was consistent with expected system operation.

---

### 5. Network-Linked Process Hunt

```sql
SELECT 
  p.pid, 
  p.name, 
  p.cmdline,
  s.remote_address 
FROM processes p
JOIN process_open_sockets s 
  ON p.pid = s.pid
WHERE s.remote_address != '';
```

**What I was looking for:** Any process with an active outbound connection — the most direct indicator of C2 or data exfiltration activity.

**What I found:** No results.

**Assessment:** No processes were making outbound network connections at the time of analysis. This eliminates active C2 communication and outbound exfiltration as active threats. I did not call this out explicitly in my initial submission, which was a gap — an empty result set from a high-value query is still a finding worth stating.

## Behavioral Summary

**User Activity**

SSH session spawning `bash` and `osqueryi` — legitimate interactive administrative activity. Process chain consistent with expected behavior.

**System Activity**

Kernel threads, systemd services, and standard background daemons. All consistent with a normal Linux environment baseline.

**Suspicious Activity**

None identified. No evidence of persistence mechanisms, privilege abuse, suspicious command-line usage, rare unauthorized binaries, or active command-and-control communication.

## Mistakes and What I Learned From Them

**1. Broad wildcard matching causes false positives**

The `%nc%` pattern in the command-line query matched `systemd-timesyncd` because the substring appears inside the process name. I knew why this process was active — I had run a time sync command earlier — but the query flagged it anyway. The lesson: broad wildcard patterns like `%nc%` will catch legitimate system services. In a real detection, this pattern needs additional context filters (path, UID, parent) to reduce noise.

**2. Not stating the network result explicitly**

The join query returned no results, and I moved past it without writing up what that means. No results from a network-linked process query is a high-value finding. It rules out active C2. That conclusion needed to be stated, not implied.


## Skills Demonstrated

- Persistence detection using process start time analysis
- Privilege abuse identification through UID/GID analysis
- Command-line pattern hunting for offensive tooling signatures
- Frequency-based rare process analysis
- Network-linked behavior correlation for C2 detection
- False positive analysis and process attribution

## Key Terms

- **LOLBin (Living Off the Land Binary)**: legitimate system tools abused by attackers to blend in — `bash`, `python`, `curl`, `nc`
- **Persistence**: any mechanism that maintains attacker access across reboots or sessions
- **Privilege abuse**: a non-system process operating at elevated privilege without justification
- **Frequency analysis**: using count-based queries to surface rare or anomalous process names
- **Attribution**: correctly identifying who or what owns a process before drawing conclusions
- **C2 (command-and-control)**: external communication channel used by malware or an attacker to maintain post-exploitation access

## My Takeaways

What I actually internalized from this session:

- Behavioral hunting means proving the system is clean — not just assuming nothing stands out
- I need to be precise with reasoning, not just accurate with conclusions
- Empty results from high-value queries are findings worth documenting
- Rare does not mean suspicious — context separates the two
- This session pushed me from running queries to actually defending my analysis

## Next Up

Day 3 — Timeline and Attack Reconstruction
