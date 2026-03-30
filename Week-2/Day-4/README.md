# Week 2 Day 4 - Data Exfiltration Detection

This module captures my Week 2 Day 4 learning on detecting unauthorized data leaving a system or network.

## Day 4 Objective

Today I focused on identifying data exfiltration patterns, including both large obvious transfers and stealthy low-and-slow techniques that are designed to avoid detection.

By the end of Day 4, I wanted to be able to:

- Explain what data exfiltration is in SOC terms
- Identify behavioral indicators of exfiltration in logs
- Explain why compression and off-hours timing raise suspicion
- Recognize low-and-slow exfiltration as a detection evasion technique
- Determine which exfiltration pattern is harder to detect and why

## Concept in Practical Terms

Data exfiltration is the unauthorized transfer of data out of a system or network.

Common methods:

- Downloading and compressing sensitive files for bulk transfer
- Uploading data to external servers or IPs
- Sending repeated small transfers over time to stay under alert thresholds

This is the stage where real damage happens: customer data stolen, credentials leaked, company breach confirmed.

## Scenario Review

I observed the following activity:

```text
User: cody
Time: 2:45 AM
Action:
- Accessed 500 files
- Compressed into archive.zip
- Sent to external IP: 198.51.100.25
```

## Scenario-Based Q&A

### 1. What makes this suspicious?

My answer:

A large number of files were accessed, compressed into an archive, and transferred to an external IP, which strongly indicates potential data exfiltration.

### 2. Why is the time important?

My answer:

The activity occurs outside normal business hours, which deviates from baseline behavior and increases the likelihood of unauthorized activity.

### 3. Why is compression important?

My answer:

Compression allows large amounts of data to be packaged and transferred efficiently, which is a common technique used to prepare data for exfiltration.

### 4. What would I investigate next?

My answer:

I would review file access logs to identify what data was accessed, analyze the destination IP for reputation and ownership, verify whether the activity aligns with normal user behavior, and check for signs of credential compromise.

## Second Scenario Review

I then observed:

```text
User: cody
Uploads:
- 1 MB
- 2 MB
- 1.5 MB
Repeated every 5 minutes to external IP
```

### 5. Why is this suspicious even though the files are small?

My answer:

Even small files are being sent to an external IP repeatedly, likely to avoid triggering alerts that monitor for large data transfers.

SOC-level refinement:

Repeated small data transfers to an external IP may indicate an attempt to evade detection thresholds that monitor large data movement.

### 6. What type of technique is this?

My answer:

Low-and-slow data exfiltration.

Why:

Small amounts of data are transferred over time to avoid triggering volume-based detection rules and blend in with normal network traffic.

## Bonus Analysis

Question: Which is harder to detect and why?

- A. One large data transfer (500 MB)
- B. Many small transfers over time

My answer: **B**

Reason:

Many small transfers are harder to detect because they stay below typical alert thresholds and blend in with normal network activity.

## Mini Challenge Reflection

Question: Which is more suspicious and why?

- A. User downloads 1 large file (500 MB) from internal server
- B. User accesses 300 sensitive files and uploads them externally

My answer: **B**

Reason:

Accessing many sensitive files and transferring them externally indicates potential data exfiltration and high-impact compromise.

## Key Terms

- Data exfiltration: unauthorized transfer of data out of a system or network
- Low-and-slow exfiltration: transferring small amounts of data over time to evade detection thresholds
- Compression: packaging files into an archive to reduce size and simplify bulk transfer
- Detection threshold: the point at which an alert fires based on volume, frequency, or other conditions
- Destination IP analysis: reviewing the reputation and ownership of an external IP involved in suspicious transfers
- Impact stage: the phase of an attack where actual damage occurs, such as data theft

## My Takeaways

What clicked for me:

- Exfiltration is not always obvious — small, repeated transfers can fly under the radar
- Compression combined with off-hours timing is a strong combined indicator
- The destination IP is just as important as the volume of data transferred
- Detecting exfiltration often requires correlating file access, network, and authentication logs together

## Next Up

Week 2 Day 5 - Persistence and backdoor detection.
