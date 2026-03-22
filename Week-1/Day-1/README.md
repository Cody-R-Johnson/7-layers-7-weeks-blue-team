# Week 1 Day 1 - Log Collection Foundations

This module captures the detailed learning content for Week 1 Day 1.

## Personalized Setup

- Background: Computer Science graduate with Google Cybersecurity Professional Certificate
- Goal: Pass CompTIA Security+ (SY0-701) and build practical SOC experience
- Tool preference: No strict preference
- Sector focus: General
- Prerequisites: Confirmed

## Learning Style for This Program

Daily workflow:

1. Concept (what it is and why it matters)
2. Real-world context (how SOC analysts use it)
3. Hands-on task (learner activity)
4. Guidance (what to watch for)
5. Feedback (review and improvement)

Instruction style:

- Beginner-friendly language
- Full terms first, then abbreviations
- Interview-ready and Security+ relevant framing

## Day 1 Objective

Understand raw logs before using Security Information and Event Management (SIEM) tooling.

By the end of Day 1, the learner should be able to:

- Read authentication and privilege logs
- Identify suspicious login behavior
- Recognize potential account compromise sequences
- Write basic detection logic with threshold and time-window conditions

## Core Concepts Covered

- Log: a record of activity on a system
- Log Collection: gathering logs from many systems into a central place
- Security Information and Event Management (SIEM): platform for collecting, searching, correlating, and alerting on events

Why this matters in a Security Operations Center (SOC):

- Analysts detect threats through event data, not by watching users directly
- Logs provide evidence for brute force activity, malware behavior, suspicious logins, and insider threats

## Practical Analysis Scenario

Sample Linux log sequence:

```text
Mar 22 10:14:32 server1 sshd[1024]: Failed password for invalid user admin from 192.168.1.45 port 53422 ssh2
Mar 22 10:14:35 server1 sshd[1024]: Failed password for invalid user admin from 192.168.1.45 port 53422 ssh2
Mar 22 10:14:40 server1 sshd[1024]: Accepted password for root from 192.168.1.45 port 53422 ssh2
Mar 22 10:20:12 server1 sudo: cody : TTY=pts/0 ; PWD=/home/cody ; COMMAND=/bin/apt update
```

### SOC Interpretation

- Repeated failed login attempts from one Internet Protocol address (IP)
- Successful privileged login as root from the same source after failures
- Follow-on system-level activity occurred after access

This pattern is consistent with a likely compromise sequence and should be treated as incident-level suspicious activity pending validation.

## Skills Demonstrated

- Pattern recognition in authentication logs
- Attack classification refinement (brute force vs password spraying)
- Event sequencing (failures followed by success)
- Plain-English translation of technical log entries

## Detection Engineering Notes

### Detection rule pattern (fast attack)

- Alert if 3 or more failed login attempts from the same IP occur within 5 minutes

### Detection rule pattern (compromise sequence)

- Raise severity if repeated failed logins are followed by a successful privileged login from the same source within a short interval

### Detection rule pattern (low and slow coverage)

- Add a second rule for longer windows, for example: 10 or more failed logins from the same IP in 24 hours

## Key Terms Reinforced

- Brute Force Attack: many password attempts against one account
- Password Spraying: one password attempted across many accounts
- Correlation Rule: combines related events into one higher-confidence alert
- Low and Slow Attack: attacker spreads attempts over time to evade short thresholds
- False Positive: normal activity flagged as suspicious
- Account Lockout Policy: control that limits repeated failed login attempts

## Analyst Decision-Making Outcome

Correct first response in this scenario:

- Investigate the timeline and confirm compromise indicators before containment actions

Reasoning:

- Immediate blocking can remove visibility or disrupt valid administration in rare cases
- Restarting a host can destroy forensic context
- Timeline-first triage supports accurate escalation and response actions

## Day 1 Completion Status

- Status: Complete
- Next: Week 1 Day 2 (Alert Creation and SIEM query mindset)
