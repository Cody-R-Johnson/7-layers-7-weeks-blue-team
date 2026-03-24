# Week 1 Day 5 - Baselining and Normal Behavior

This module captures my Week 1 Day 5 learning on baselining and anomaly detection.

## Day 5 Objective

Today I focused on understanding normal behavior first, so abnormal behavior is easier to spot and prioritize.

By the end of Day 5, I wanted to be able to:

- Define what a baseline is in a SOC context
- Identify deviations from normal behavior patterns
- Explain why time, source IP, and privilege level matter
- Evaluate suspicious activity using context instead of assumptions
- Apply anomaly detection thinking to triage decisions

## Concept in Practical Terms

A baseline is a reference for normal behavior in an environment.

It helps answer:

- What is normal for login timing?
- What level of failed logins is expected?
- Which systems and IP ranges are regularly seen?
- How often are privileged accounts used?

Once normal behavior is established, deviations become easier to investigate.

Without a baseline:

- Everything can look suspicious
- Or nothing gets treated as suspicious

With a baseline:

- Outliers are easier to detect
- Prioritization becomes more consistent
- Triage decisions are more evidence-based

## Scenario Review

### Established baseline behavior

- 2-5 failed logins per hour
- Logins mostly between 9 AM and 5 PM
- Admin/root logins are rare (1-2 times per week)
- Typical source range is internal: 10.0.0.x

### New observed activity

- 30 failed logins in 2 minutes
- Login at 2:30 AM
- Successful root login
- Source IP: 185.220.101.45 (external)

## My Analysis

### 1. Three abnormal indicators

- 30 failed logins in 2 minutes is significantly above baseline volume
- Authentication activity at 2:30 AM is outside normal business-hour behavior
- The source IP is external and outside the known internal range

### 2. Why time matters in baselining

Time helps establish behavior patterns. Activity outside expected operating windows can indicate unauthorized access or compromised credentials.

### 3. Why the IP is suspicious

The source does not match the normal internal network range, so it represents a baseline deviation and possible unauthorized external access.

### 4. Why root login is high priority here

Root access is high impact, and root usage is rare in baseline behavior. A successful root login combined with other anomalies should be treated as potentially suspicious until validated.

## Context-Based Judgment Exercise

Scenario:

A user logs in at 3 AM from a new country with no failed attempts.

### 5. Is this suspicious?

It is suspicious, but not conclusive by itself.

Possible benign explanation: legitimate travel or time-zone difference.

SOC approach: treat it as higher-priority activity for validation because it deviates from baseline and includes successful access.

## Bonus Concept

Using normal behavior to detect unusual behavior is called:

- Anomaly detection

Interview-ready definition:

> Anomaly detection is the practice of identifying deviations from established baseline behavior to surface potential security threats.

## Mini Challenge Reflection

Question:

- A: 5 failed logins at 10 AM from internal IP
- B: 1 successful login at 3 AM from a new country

My final conclusion: B is more suspicious from a risk perspective.

Reasoning:

- Option A occurs during normal hours and from expected network space, and may be common user error
- Option B is a successful access event with unusual time and location context
- Even if B could be legitimate travel, the potential impact is higher and should be prioritized

Key mindset shift from this exercise:

- Not just Could this be normal?
- Also What is the impact if this is malicious?

## Key Terms

- Baseline: established reference of normal environment behavior
- Anomaly: deviation from expected behavior pattern
- Anomaly detection: identifying unusual events compared to baseline
- Outlier: event that significantly differs from normal distribution
- Triage: prioritizing investigation based on risk and impact
- Privileged access: elevated account permissions with greater potential impact

## My Takeaways

Day 5 helped me think less in terms of isolated events and more in terms of behavior patterns and context.

What clicked for me:

- Baselining makes anomaly detection practical, not guesswork
- Time, source, and privilege level change the risk meaning of events
- Successful unusual access can be higher priority than high-volume failed attempts
- Better SOC decisions come from combining pattern awareness with impact assessment

## Next Up

Week 1 Day 6 will focus on detection engineering for endpoint and behavior-based detections.
