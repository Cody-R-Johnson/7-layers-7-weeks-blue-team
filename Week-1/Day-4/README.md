# Week 1 Day 4 - Dashboards and SOC Visibility

This module captures my Week 1 Day 4 learning on SOC dashboards and real-time visibility.

## Day 4 Objective

Today I focused on how analysts actually monitor activity in real time instead of manually reading raw logs all day.

By the end of Day 4, I wanted to be able to:

- Explain what a SOC dashboard is and why it matters
- Identify common dashboard panels and what they show
- Interpret a suspicious dashboard scenario quickly
- Distinguish brute force from password spraying behavior
- Understand alert fatigue and why tuning matters

## Concept in Practical Terms

A dashboard is a visual layer on top of log and alert data.

Instead of searching endless log lines, analysts can track key signals in one view, such as:

- Failed logins over time
- Top source IPs
- Alert severity distribution
- User authentication activity

A good comparison is a car dashboard:

- Speed
- Fuel
- Warning lights

A SOC dashboard does the same thing for security operations. It surfaces what needs attention right now.

## Common SOC Dashboard Panels

In platforms like Splunk and the ELK stack, common panels include:

1. Failed logins over time
What it helps with: spotting spikes that may indicate automated attack activity.

2. Top source IPs
What it helps with: identifying concentration of suspicious activity from specific hosts.

3. Alerts by severity
What it helps with: triaging work by impact and urgency.

4. User activity
What it helps with: seeing which accounts are failing authentication and which accounts successfully log in.

## Scenario Review

Dashboard signals observed:

- Spike in failed logins at 10:01
- Most activity from `192.168.1.10`
- Successful root login shortly after
- Alert triggered: Brute Force Suspected

### 1. What stands out immediately?

A spike in failed login attempts from a single IP followed by a successful root login and a brute-force alert.

### 2. Why dashboards are better than raw logs for this stage

Dashboards provide real-time visualization of key security events, which helps me identify anomalies much faster than manually reviewing large volumes of logs.

### 3. What a spike usually indicates

A spike usually indicates abnormal behavior, potentially an attack pattern or automated activity such as brute-force attempts.

### 4. What I would investigate next

I would investigate activity from the source IP, review authentication logs for the root account, and check for actions performed after login (privilege changes, command execution, file modifications, and persistence-related behavior).

## Scenario 2 - Pattern Classification

Observed pattern:

- 50 failed logins in 1 minute
- From one IP
- Across multiple usernames

### 5. What type of attack is this?

Most likely password spraying.

Reason: multiple usernames are targeted with a common password set, rather than one account being hammered repeatedly.

### 6. Why this differs from earlier brute-force examples

This pattern spreads attempts across many users, while classic brute force typically focuses on many attempts against one user account.

## Bonus - Too Many Alerts

If the dashboard is showing too many alerts and analysts become desensitized, that problem is called:

- Alert fatigue

Interview-ready definition:

> Alert fatigue occurs when excessive alert volume overwhelms analysts, reducing monitoring effectiveness and increasing the risk of missed threats.

## Mini Challenge Reflection

Question:

- A: 50 failed logins, no success
- B: 3 failed logins, then a successful root login

My conclusion: B is more dangerous.

Why:

A has high noise and is clearly suspicious, but no access was confirmed. B indicates likely account compromise with root-level access, which has much higher impact even with fewer attempts.

Key distinction:

- A is easier to detect
- B is more critical to contain

## Key Terms

- Dashboard: visual interface for monitoring security telemetry
- Spike: sudden increase in event volume, often requiring investigation
- Password spraying: trying one or a few passwords across many accounts
- Brute force: repeated password attempts against one account
- Alert fatigue: reduced analyst effectiveness from excessive alert volume
- Triage: prioritizing alerts by risk and urgency

## My Takeaways

Day 4 helped connect detection logic to real SOC operations.

What clicked for me:

- Dashboards improve speed and visibility, not just presentation
- Context matters more than event count alone
- Successful privileged access is usually higher priority than repeated failed attempts
- Detection quality depends on good rule logic plus alert tuning

## Next Up

Week 1 Day 5 will focus on baselining so I can better separate normal behavior from suspicious behavior.
