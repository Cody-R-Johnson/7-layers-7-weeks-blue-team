# Week 1 Day 2 - Alerting and SIEM Queries

## Day 2 Objective

Move from reading logs manually to searching them like a machine using Security Information and Event Management (SIEM) query logic.

By the end of Day 2, I should be able to:

- Run basic queries against a log dataset
- Filter events by IP address, login status, and account name
- Correlate failed and successful logins into a detection sequence
- Understand why context matters when reading security events

## Core Concepts

- Query: asking a SIEM to show only specific events instead of reading everything line by line
- SIEM (Security Information and Event Management): a platform that collects logs, lets you search them fast, and can trigger automatic alerts based on patterns

Instead of reading logs one line at a time, you ask something like:

> "Show me all failed logins from this IP"

That is what a query does.

Tools being simulated in this module: Splunk and the ELK Stack (Elasticsearch, Logstash, Kibana).

## Sample Log Dataset Used

```text
Mar 22 10:01:10 server1 sshd: Failed password for invalid user admin from 192.168.1.10
Mar 22 10:01:15 server1 sshd: Failed password for invalid user admin from 192.168.1.10
Mar 22 10:02:00 server1 sshd: Accepted password for root from 192.168.1.10
Mar 22 10:05:12 server1 sshd: Failed password for user cody from 10.0.0.5
Mar 22 10:06:33 server1 sshd: Accepted password for cody from 10.0.0.5
Mar 22 10:07:45 server1 sshd: Failed password for invalid user guest from 172.16.0.2
```

## Lab Queries and My Answers

### Query 1 - Find all failed logins

Search term: `Failed password`

My answer: 4 failed login events

Correct. The four events are:
- Failed (admin) from 192.168.1.10
- Failed (admin) from 192.168.1.10
- Failed (cody) from 10.0.0.5
- Failed (guest) from 172.16.0.2

### Query 2 - Find all activity from one IP

Search term: `192.168.1.10`

My answer: 3 events from that IP

Correct. The sequence:
1. Failed login attempt
2. Failed login attempt
3. Successful login as root

That sequence is suspicious on its own.

### Query 3 - Find successful logins

Search term: `Accepted password`

My answer: root and cody successfully logged in

Correct.

### Query 4 - Combine conditions

Search term: `Failed password AND 192.168.1.10`

My answer: two failed attempts from that IP

Better framing: multiple failed login attempts from a single IP address, which may point to a brute force attempt targeting that source.

## Detection Thinking

Goal: detect brute force attempts that actually succeed (not just failed attempts)

### My answers:

1. The two events to correlate are a failed login followed by a successful login from the same IP address.

2. It is more dangerous than just failed logins because the attacker actually got in, which points toward account compromise - not just a probe.

3. My detection rule:

> "Alert if multiple failed login attempts are followed by a successful login from the same IP within 5 minutes."

Key ingredients of this rule:
- Threshold: multiple failures (not just one)
- Sequence: failures come before success
- Source match: same IP address for both events
- Time window: 5 minutes

## Most Suspicious IP

**192.168.1.10**

Why: it shows multiple failed login attempts followed by a successful root login from the same source. Root is the highest privilege account on a Linux system, so gaining that access after repeated failures strongly suggests a brute force attack that worked.

## Key Concept: Loss of Context

If I only searched for `Accepted password`, I would miss the failed login attempts that happened before the successful one.

That means I would see a login that looks normal when it is actually the end of an attack.

> A single event rarely tells the full story - patterns over time reveal threats.

This applies to logs, alerts, network traffic, and user behavior.

## Key Terms Reinforced

- SIEM (Security Information and Event Management): platform for searching and alerting on log data
- Query: a search instruction that filters log data by specific conditions
- Threat Detection Workflow: search logs → identify anomaly → correlate events → create alert
- Loss of Context: missing surrounding events that explain the significance of a single entry
- Account Compromise: an attacker successfully gaining access to a real account

## Day 2 Completion Status

- Status: Complete
- Next: Week 1 Day 3 (Correlation Rules using Sigma)
