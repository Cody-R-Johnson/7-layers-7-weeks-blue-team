# Week 2 Day 1 - Threat Hunting Foundations

This module captures my Week 2 Day 1 learning on moving from reactive monitoring to proactive threat hunting.

## Day 1 Objective

Today I focused on learning the hunting mindset: not waiting for alerts, but proactively looking for suspicious behavior that detection rules may have missed.

By the end of Day 1, I wanted to be able to:

- Explain what threat hunting is in simple SOC terms
- Use baseline behavior to assess whether activity is normal or suspicious
- Build a hypothesis before jumping to conclusions
- Identify what logs to review next during a hunt
- Distinguish suspicious authentication activity from possible false positives

## Concept in Practical Terms

Threat hunting means proactively searching for threats, even when no alert has fired.

Instead of waiting for detections:

- I ask targeted questions
- I search logs across systems
- I look for patterns that do not fit baseline behavior

Core difference:

| SOC Monitoring | Threat Hunting |
| --- | --- |
| Wait for alerts | Go find threats |
| Reactive | Proactive |
| Rule-based | Hypothesis-based |

## Scenario Review

No alerts fired and everything looked normal at first glance.

I still investigated and found:

- User: `cody`
- Login time: 2:13 AM
- Source IP: `203.0.113.45` (external)
- Failed attempts: none

## Scenario-Based Q&A

### 1. What makes this suspicious based on baseline?

My answer:

The login is outside normal office hours and comes from an external IP.

SOC-level refinement:

The login occurs outside normal business hours and originates from an external IP not seen in the user baseline.

### 2. What is one legitimate explanation?

My answer:

The user could be traveling and working from a different timezone.

Why this matters:

This keeps me from assuming compromise too early and helps reduce false positives.

### 3. What logs would I check next?

My answer:

Files accessed, permission changes, and files executed.

SOC-level upgrade:

- Authentication logs (session history, additional logins)
- Command history and process execution logs
- Privilege escalation logs (`sudo` usage)
- File access and modification logs for sensitive paths

### 4. What am I trying to confirm or rule out?

My answer:

I am trying to determine whether this activity aligns with expected user behavior or indicates unauthorized access using compromised credentials.

### 5. Hunting Hypothesis

My answer:

I suspect potential credential compromise because the login occurred outside normal hours from an unfamiliar external IP, which deviates from established baseline behavior.

## Bonus Analysis (Post-Login Activity)

Additional log evidence:

```text
Login successful
sudo useradd tempadmin
sudo chmod 777 /etc/passwd
```

### 6. What does this indicate?

This indicates likely post-compromise activity involving privilege abuse and persistence.

Breakdown:

- `useradd tempadmin`: likely backdoor account creation for persistent access
- `chmod 777 /etc/passwd`: critical security weakening of a sensitive system file

This is high-risk behavior and should be treated as a potential confirmed compromise pending containment and incident response procedures.

## Mini Challenge Reflection

Question: What is the attacker's main goal here?

- A. Steal data immediately
- B. Maintain long-term access
- C. Crash the system
- D. Reset passwords

My answer: **B**

Reason:

Creating a new privileged account and weakening access controls points to persistence. The attacker likely wants to keep long-term access while reducing the chance of losing foothold.

## Key Terms

- Threat hunting: proactive investigation to find malicious activity missed by alerts
- Hypothesis-driven investigation: starting with a suspicion statement and testing it with evidence
- Baseline behavior: normal activity pattern for users, systems, and networks
- Credential compromise: unauthorized use of valid account credentials
- Privilege abuse: misuse of elevated permissions after access is obtained
- Persistence: attacker techniques used to maintain ongoing access

## My Takeaways

What clicked for me:

- No alert does not always mean no threat
- Baseline context is critical before labeling activity malicious
- A strong hunting hypothesis keeps investigations focused
- Post-login behavior often reveals more than login success alone

## Next Up

Week 2 Day 2 - Advanced hunting patterns across multiple users and systems.
