# Week 2 Day 7 - Threat Hunting Wrap-Up and Real SOC Thinking

This module captures my Week 2 Day 7 learning on the part of threat hunting that matters most in a real SOC: making decisions under uncertainty and prioritizing what matters first.

## Day 7 Objective

Today I focused on turning threat hunting observations into analyst decisions instead of just identifying technical indicators.

By the end of Day 7, I wanted to be able to:

- Judge whether unusual activity is normal, suspicious, or clearly malicious
- Explain the difference between anomaly and confirmed compromise
- Decide what additional evidence would raise a case into an incident
- Think like an analyst who has to triage multiple alerts under pressure
- Prioritize alerts based on impact, access, and likelihood of compromise

## Concept in Practical Terms

The hardest part of threat hunting is not reading logs or writing queries.

The hardest part is making decisions with incomplete information.

In a real SOC, I usually do not get a clean, obvious attack story right away. I see partial evidence, unusual timing, small behavior changes, and signals that may or may not connect. That means I have to avoid two mistakes:

- Overreacting to every anomaly
- Ignoring behavior that might be the start of something bigger

This is where triage and prioritization matter. The job is not just to spot something odd. The job is to decide what deserves attention first and what evidence would change the severity.

## Scenario Review

I was given the following activity:

```text
User: cody
Login: 1:30 AM
Source IP: external
No failed attempts

Activity:
- Accessed 20 files
- No compression
- No obvious exfiltration
- No new accounts created
```

## Scenario-Based Q&A

### 1. Is this clearly malicious, clearly normal, or suspicious?

My answer:

This is suspicious, but not clearly malicious.

Reasoning:

The login time and external IP deviate from normal baseline behavior, but there is no confirmed malicious action yet such as script execution, persistence, privilege escalation, or exfiltration. It stands out enough to investigate, but not enough to declare a confirmed incident on its own.

### 2. What makes this different from earlier attack scenarios?

My answer:

Unlike the earlier scenarios, there is no strong evidence of attacker objectives being carried out yet.

What is different:

- No malware execution
- No creation of backdoor accounts
- No privilege escalation observed
- No compression or transfer of files externally
- No clear persistence activity

This is more of an anomalous behavior case than a confirmed attack chain.

### 3. What would determine if this becomes an incident?

My answer:

This would become an incident if additional suspicious activity appears that increases the likelihood of compromise.

Examples that would raise severity:

- More abnormal logins for the same user
- Privilege escalation attempts
- Lateral movement to other systems
- Access to sensitive files outside the user's role
- Compression, staging, or outbound transfer activity
- Correlated alerts tied to the same account or host

Right now, it belongs on the radar, but there is not enough evidence to escalate it as a confirmed incident.

### 4. What would I do next as an analyst?

My answer:

I would continue investigating before escalating.

Next steps I would take:

- Review authentication logs for the full user timeline
- Compare the source IP and login time against the user's normal baseline
- Check whether the 20 accessed files match the user's normal job activity
- Review host and account logs for privilege escalation or unusual commands
- Correlate with other alerts tied to the same user, device, or IP
- Continue monitoring for follow-on behavior

## Prioritization Exercise

I was then asked to rank these alerts by risk:

```text
A. 50 failed logins, no success
B. 1 successful login at 3 AM from a new country
C. User accessed 20 files at 1:30 AM, no exfiltration yet
```

### 5. Rank these in priority

My answer:

1. B
2. C
3. A

Reasoning:

- B is the highest priority because a successful login from a new country means access was gained, which creates immediate compromise risk.
- C is second because the behavior is suspicious and active, but there is still no confirmed malicious action.
- A is third because failed logins matter, but no account access was achieved, which lowers immediate impact.

The main lesson here is that I should prioritize impact and access over alert volume.

## Bonus

Question: What is the skill called when I decide what matters most when multiple suspicious events occur?

My answer:

Alert triage and prioritization.

SOC version:

This is the process of ranking alerts based on risk, impact, and likelihood of compromise so the most important issues get attention first.

## Key Terms

- Triage: the process of sorting events by urgency and risk
- Prioritization: deciding which alert or investigation should be handled first
- Anomaly: behavior that deviates from baseline but is not automatically malicious
- Confirmed compromise: evidence that an attacker successfully gained access or performed malicious actions
- Correlation: connecting multiple events across logs, systems, or time to improve confidence in an investigation
- Severity escalation: raising the priority of a case when stronger evidence appears

## My Takeaways

What clicked for me:

- Not every suspicious event is a confirmed attack
- Real SOC work involves uncertainty much more than obvious evidence
- Good analysts do not panic, but they also do not ignore weak signals
- Successful access usually matters more than noisy failed attempts
- Triage and prioritization are what turn raw alerts into real decision-making

## Next Up

Week 3 Day 1 - Network Security foundations.
