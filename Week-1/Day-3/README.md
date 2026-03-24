# Week 1 Day 3 - Correlation Rules and Sigma

This module captures my Week 1 Day 3 learning on correlation rules and Sigma.

## Day 3 Objective

Today I moved beyond just reviewing alerts and started thinking more about how detections are actually designed.

By the end of Day 3, I wanted to be able to:

- Understand what a correlation rule is
- Explain what Sigma is in practical terms
- Build a basic detection rule using failed and successful login events
- Think about how attackers might evade a rule
- Compare different thresholds and correlation windows

## Concept in Simple Terms

A correlation rule links multiple related events together instead of evaluating each event in isolation.

Example:

- Multiple failed logins happen first
- A successful login happens after that
- That sequence may point to suspicious activity

That is event correlation in a very simple form.

Sigma is a standardized way to write detection rules so the same logic can be translated across different security tools.

I think of Sigma as:

> Write once, use anywhere.

This matters because the real skill is not just knowing one tool. It is understanding detection logic well enough to apply it across platforms like:

- Splunk
- ELK Stack
- Microsoft Sentinel

## Simple Sigma Example

```yaml
title: Possible Brute Force with Successful Login
logsource:
  product: linux
  service: ssh
detection:
  selection_fail:
    message: "Failed password"
  selection_success:
    message: "Accepted password"
  condition: selection_fail followed by selection_success
```

## What This Rule Means

In plain English, this rule is trying to detect failed login attempts followed by a successful login.

That helped me realize Sigma is not a completely separate skill. It is the same detection thinking, just written in a more structured and reusable format.

## Practice Log

```text
Mar 22 10:01:10 Failed password from 192.168.1.10
Mar 22 10:01:15 Failed password from 192.168.1.10
Mar 22 10:02:00 Accepted password from 192.168.1.10
Mar 22 10:10:00 Failed password from 10.0.0.5
Mar 22 10:20:00 Accepted password from 10.0.0.5
```

## My Answers

### 1. Which IP should trigger the Sigma rule?

My answer: `192.168.1.10`

Why: the failed logins and successful login happen close together, which makes the sequence more suspicious from a correlation standpoint.

### 2. Why does the other IP not trigger the rule?

My answer: the failed and successful events are too far apart.

Better wording:

> The failed and successful login events are too far apart in time, so they fall outside the defined correlation window.

That introduced a useful term for me: correlation window.

### 3. Add a time condition

My answer: within `5 minutes`

### 4. Add a threshold

My answer: after `3 failed attempts`

### 5. Write the full detection rule in plain English

My first version:

> Alert if successful login occurs after 3 failed attempts within 5 minutes from the same IP.

Refined version:

> Alert if 3 or more failed login attempts are followed by a successful login from the same IP within 5 minutes.

The refined version is better because it makes the threshold clearer and uses sequence language more directly.

## Bonus Question - How Could an Attacker Avoid This Rule?

My answer was basically delaying the attempts over a longer period of time.

The formal term for that is:

- Low and slow attack

Interview-ready version:

> An attacker could bypass this rule by performing a low-and-slow attack, spreading login attempts over a longer period of time to avoid triggering time-based thresholds.

## Detection Tradeoff Exercise

I also compared these two options:

### Option A

- 3 failed attempts in 1 minute

### Option B

- 5 failed attempts in 10 minutes

My first thought was that Option B seemed better because it could catch slower activity.

After reviewing it more carefully, I learned the better answer is that neither rule is perfect on its own.

- Option A is better for fast brute force attempts
- Option B is better for slower and more stealthy attempts
- Using both together provides broader detection coverage

That showed me that detection engineering is not about finding one perfect rule. It is about balancing coverage, timing, thresholds, and false positives.

## Key Terms

- Correlation rule: a rule that links multiple related events together
- Sigma: a standardized detection rule format
- Correlation window: the time range in which events must occur to match a rule
- Threshold: the number of events needed before a rule triggers
- Low and slow attack: an attack spread out over time to avoid detection
- Detection coverage: how well rules catch different attacker behaviors

## My Takeaways

Today felt like a jump from reading logs to thinking more like someone who builds and tunes detections.

What clicked for me:

- Detection rules depend on both sequence and timing
- Thresholds can make a rule too weak or too noisy
- Attackers do not always move fast, so detection logic has to account for that
- Good detection is usually layered, not based on one single rule

## Next Up

Week 1 Day 4 will focus on dashboards and visualization so I can understand how analysts actually see patterns and anomalies in real time.
