# Week 2 Day 3 - Lateral Movement Detection

This module captures my Week 2 Day 3 learning on detecting attacker movement inside a network after initial access.

## Day 3 Objective

Today I focused on recognizing post-compromise behavior, especially how attackers move from one host to another and escalate privileges.

By the end of Day 3, I wanted to be able to:

- Explain what lateral movement is in simple SOC terms
- Identify suspicious host-to-host movement patterns
- Distinguish post-compromise activity from initial access
- Investigate authentication chains across multiple systems
- Recognize why rapid multi-server access can indicate active compromise

## Concept in Practical Terms

Lateral movement is when an attacker moves from one system to another inside the environment after gaining an initial foothold.

Simple flow:

- Compromise one machine
- Use that access to reach other systems
- Expand control and permissions across the network

This is how small breaches grow into major incidents.

## Scenario Review


```text
Host A -> login success -> user: cody
Host A -> ssh to Host B -> success
Host B -> ssh to Host C -> success
Host C -> sudo access granted
```

## Scenario-Based Q&A

### 1. What pattern do I see?

My answer:

A user is accessing multiple hosts in sequence and eventually gaining elevated (`sudo`) privileges.

### 2. Why is this suspicious?

My answer:

Moving between systems and then receiving `sudo` access suggests the account may have been used to navigate toward specific targets.

SOC-level refinement:

This is suspicious because the user is accessing multiple systems in sequence and escalating privileges, which deviates from normal behavior and may indicate attacker movement within the network.

### 3. What stage of an attack is this?

My answer:

Lateral movement using an existing foothold to expand access.

Attack lifecycle context:

This is post-compromise activity, specifically lateral movement with privilege escalation.

### 4. What would I investigate next?

My answer:

I would verify whether this account is expected to access those systems, review authentication logs across all involved hosts, check for privilege escalation events, and trace any actions performed after access.

Additional checks:

- Whether this user normally performs cross-host SSH chains
- Whether unusual commands were executed after `sudo`
- Whether persistence or data access actions followed

## Second Scenario Review

```text
User: cody
Accessing:
- Server1
- Server2
- Server3
- Server4
Within 5 minutes
```

### 5. What is suspicious about this?

My answer:

Accessing multiple servers rapidly is unusual and may indicate automated or malicious behavior.

### 6. What could this indicate?

My answer:

This could indicate lateral movement, where an attacker is expanding access to locate valuable systems and potentially change or extract data.

## Bonus Analysis

Question: What is the attacker's goal during lateral movement?

- A. Crash the system
- B. Spread access and find valuable targets
- C. Reset passwords
- D. Reduce logs

My answer: **B**

Reason:

Once an attacker has a foothold, the typical objective is to expand network access, find sensitive assets, and maintain persistence while avoiding detection.

## Mini Challenge Reflection

Question: Which is more suspicious and why?

- A. User logs into 1 server and runs 1 command
- B. User logs into 5 servers in 10 minutes and gains `sudo` access

My answer: **B**

Reason:

Rapid access across multiple systems combined with privilege escalation strongly deviates from normal behavior and may indicate active lateral movement and compromise.

## Key Terms

- Lateral movement: attacker movement from one internal system to another after initial access
- Post-compromise behavior: attacker actions performed after foothold is established
- Privilege escalation: gaining higher permissions than originally held
- Authentication chain: sequence of related logins across hosts or services
- Foothold: initial compromised access point used to expand operations
- Persistence: techniques used to keep long-term access in the environment

## My Takeaways

What clicked for me:

- Detecting compromise means tracking behavior across systems, not single events
- Host-to-host movement plus `sudo` is a high-value signal
- Baseline context is critical for judging whether access patterns are expected
- Lateral movement detection is core to spotting real breaches in progress

## Next Up

Week 2 Day 4 - Data exfiltration detection.
