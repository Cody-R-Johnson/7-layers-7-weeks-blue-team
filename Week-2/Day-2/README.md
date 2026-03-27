# Week 2 Day 2 - Advanced Threat Hunting Patterns

This module captures my Week 2 Day 2 learning on hunting attack patterns across multiple users and systems instead of focusing on only one account at a time.

## Day 2 Objective

Today I focused on recognizing distributed authentication patterns that may not trigger normal alerts when each individual event looks low severity.

By the end of Day 2, I wanted to be able to:

- Identify hunting patterns across multiple users and IPs
- Distinguish password spraying from distributed brute force activity
- Explain why some attack patterns evade traditional brute force detections
- Expand an investigation beyond one failed login event
- Compare which distributed attack pattern is harder to detect and why

## Concept in Practical Terms

Hunting patterns help me detect suspicious activity that is spread across accounts, systems, or source IPs.

Instead of asking:

- Is this one user suspicious?

I ask:

- Is something happening across many users?
- Is the same source touching multiple accounts?
- Is one account being targeted from many different sources?

This matters because attackers often split activity across users or IPs to stay under rule thresholds.

## Scenario Review

I reviewed authentication activity and found:

```text
User: alice -> failed login -> 192.168.1.50
User: bob   -> failed login -> 192.168.1.50
User: carol -> failed login -> 192.168.1.50
User: dave  -> failed login -> 192.168.1.50
User: eve   -> failed login -> 192.168.1.50
```

## Scenario-Based Q&A

### 1. What pattern do I see?

My answer:

Multiple users are experiencing failed login attempts from the same IP address.

Why it matters:

This shifts my focus away from one account and toward coordinated activity coming from a single source.

### 2. What type of attack is this?

My answer:

Password spraying.

Why:

The attacker appears to be trying a small number of passwords across many accounts instead of repeatedly attacking one user.

### 3. Why might this not trigger a normal brute force rule?

My answer:

Because each user only has a single failed attempt, it does not exceed typical brute force thresholds per account.

Threat hunting takeaway:

Traditional detections often focus on repeated failures against one user, which means spread-out attacks can blend in.

### 4. What would I search for next?

My answer:

I would search for successful login attempts from the same IP across any users, then review post-login activity such as privilege escalation or system changes.

Other useful expansion points:

- Whether the same IP appears in other authentication logs
- Whether any targeted users later logged in successfully from unusual locations
- Whether there were account lockouts, MFA prompts, or suspicious session starts

## Second Scenario Review

I then found a different pattern:

```text
User: alice -> failed login -> IP A
User: alice -> failed login -> IP B
User: alice -> failed login -> IP C
User: alice -> failed login -> IP D
```

### 5. What pattern is this?

My answer:

One user account is receiving failed login attempts from multiple different IP addresses.

### 6. What type of attack might this be?

My answer:

Distributed brute force.

Why:

Multiple sources are targeting one account, which helps the attacker avoid rate limits and single-source detection thresholds.

## Bonus Analysis

Question: Which is harder to detect and why?

- A. One IP attacking many users
- B. Many IPs attacking one user

My answer: **B**

Reason:

Distributed attacks using multiple IPs are harder to detect because they avoid triggering thresholds tied to a single source, making the activity look like ordinary failed login noise.

## Mini Challenge Reflection

Question: Which is more suspicious and why?

- A. 1 failed login from 50 different IPs targeting 1 user
- B. 10 failed logins from 1 IP targeting 1 user

My answer: **A**

Reason:

Option A is more suspicious because it suggests a distributed attack pattern designed to bypass threshold-based detections and rate limiting.

## Key Terms

- Password spraying: trying a small number of passwords across many accounts
- Distributed brute force: many source IPs targeting one user to evade detection thresholds
- Hunting pattern: a repeated behavior across users, systems, or sources that suggests coordinated activity
- Threshold-based detection: an alert that triggers only after a count limit is crossed
- Rate limiting: a control that restricts repeated attempts over time
- Distributed attack: malicious activity intentionally spread across multiple sources or targets

## My Takeaways

What clicked for me:

- Looking across users can reveal attacks that single-user triage misses
- One failed login can still matter when it is repeated across many accounts
- Source-based detections and account-based detections both have blind spots
- Distributed activity is harder to detect because it is designed to blend into normal noise

## Next Up

Week 2 Day 3 - Lateral movement detection.
