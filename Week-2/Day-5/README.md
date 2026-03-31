# Week 2 Day 5 - Persistence and Backdoor Detection

This module captures my Week 2 Day 5 learning on how attackers maintain access after compromise through persistence mechanisms and backdoors.

## Day 5 Objective

Today I focused on identifying persistence techniques that allow attackers to return even after initial malicious activity is detected.

By the end of Day 5, I wanted to be able to:

- Explain persistence in practical SOC terms
- Identify account-based persistence behavior in logs
- Recognize suspicious SSH key and privilege assignment activity
- Investigate scheduled task abuse as an automated persistence mechanism
- Distinguish one-time malware execution from startup persistence risk

## Concept in Practical Terms

Persistence is how attackers keep access after compromise.

Common persistence methods include:

- Creating unauthorized user accounts
- Granting elevated privileges to those accounts
- Adding SSH keys for key-based re-entry
- Modifying startup items or scheduled tasks
- Installing backdoors that execute repeatedly

This matters because removing one payload is not enough if the access mechanism remains.

## Scenario Review

I observed the following command activity:

```text
User: cody
Commands:
- sudo useradd backup_admin
- sudo usermod -aG sudo backup_admin
- echo "ssh-rsa AAA..." >> /home/backup_admin/.ssh/authorized_keys
```

## Scenario-Based Q&A

### 1. What is happening here?

My answer:

A new privileged user account is being created, granted administrative access, and configured with SSH key-based authentication.

### 2. Why is this suspicious?

My answer:

This creates a new administrative account with persistent access, which deviates from normal user provisioning and may indicate unauthorized access.

### 3. What type of persistence is this?

My answer:

Account-based persistence through a backdoor admin account with SSH key access.

### 4. What would I investigate next?

My answer:

I would verify whether the account creation was authorized, review logs for additional privilege escalation activity, check for other persistence mechanisms, and determine whether the original account was compromised.

Additional checks:

- Audit who initiated each privileged command
- Search for added keys in other users' authorized_keys files
- Review recent changes to sudoers, startup scripts, and service configurations

## Second Scenario Review

I then observed:

```text
Process:
- Cron job added
- Runs every 5 minutes
- Executes unknown script
```

### 5. Why is this suspicious?

My answer:

A scheduled task running an unknown script at regular intervals may indicate automated malicious activity or persistence.

### 6. What is the attacker trying to achieve?

My answer:

The attacker is attempting to maintain persistent access or execute recurring malicious actions, such as data exfiltration, command execution, or re-establishing access.

## Bonus Analysis

Question: Which is more dangerous and why?

- A. Malware that runs once
- B. Malware that runs every time the system starts

My answer: **B**

Reason:

Malware that executes on startup is more dangerous because it ensures persistence and allows long-term attacker access even after reboots.

## Mini Challenge Reflection

Question: Which is more suspicious and why?

- A. New user account created by IT admin during business hours
- B. New admin account created at 3 AM with SSH key access

My answer: **B**

Reason:

An admin account created outside normal hours with SSH key access strongly indicates potential unauthorized persistence.

## Key Terms

- Persistence: techniques attackers use to maintain long-term access after compromise
- Backdoor account: an unauthorized user account created to regain access later
- Account-based persistence: persistence achieved by creating or modifying user credentials and privileges
- Authorized keys abuse: adding attacker-controlled SSH keys to enable passwordless access
- Scheduled task abuse: using cron or task schedulers to execute malicious code repeatedly
- Startup persistence: malware configured to run automatically on boot

## My Takeaways

What clicked for me:

- Persistence is often the reason attackers return after initial cleanup
- New privileged account creation plus SSH key insertion is a high-risk signal
- Recurring scheduled tasks can quietly automate malicious activity
- Effective response means removing both malware and persistence mechanisms

## Next Up

Week 2 Day 6 - Threat hunting investigation (full scenario).
