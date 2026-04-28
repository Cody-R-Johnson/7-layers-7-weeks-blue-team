# 7 Layers in 7 Weeks

A structured Blue Team learning program focused on building practical Security Operations Center (SOC) skills over 7 weeks.

## Project Overview

The curriculum progresses from core monitoring skills into advanced defensive operations:

- Week 1: Security Monitoring
- Week 2: Threat Hunting
- Week 3: Network Security
- Week 4: Endpoint Detection and Response (EDR)
- Week 5: Security Automation
- Week 6: Threat Intelligence
- Week 7: Incident Response

## Repository Structure

Each week is split into daily modules:

- Week-1/Day-1 through Week-1/Day-7
- Week-2/Day-1 through Week-2/Day-7
- Week-3/Day-1 through Week-3/Day-7
- Week-4/Day-1 through Week-4/Day-7
- Week-5/Day-1 through Week-5/Day-7
- Week-6/Day-1 through Week-6/Day-7
- Week-7/Day-1 through Week-7/Day-7

## Where Detailed Content Lives

Detailed lessons, exercises, and learning notes are stored in each day folder.

## Completed Modules

<details>
<summary><strong>Week 1</strong></summary>

- [Week 1 Day 1 - Log Collection Foundations](Week-1/Day-1/README.md)
- [Week 1 Day 2 - Alerting and SIEM Queries](Week-1/Day-2/README.md)
- [Week 1 Day 3 - Correlation Rules and Sigma](Week-1/Day-3/README.md)
- [Week 1 Day 4 - Dashboards and SOC Visibility](Week-1/Day-4/README.md)
- [Week 1 Day 5 - Baselining and Normal Behavior](Week-1/Day-5/README.md)
- [Week 1 Day 6 - Detection Engineering for Endpoint and Behavior](Week-1/Day-6/README.md)
- [Week 1 Day 7 - False Positives and Detection Tuning](Week-1/Day-7/README.md)

</details>

<details>
<summary><strong>Week 2</strong></summary>

- [Week 2 Day 1 - Threat Hunting Foundations](Week-2/Day-1/README.md)
- [Week 2 Day 2 - Advanced Threat Hunting Patterns](Week-2/Day-2/README.md)
- [Week 2 Day 3 - Lateral Movement Detection](Week-2/Day-3/README.md)
- [Week 2 Day 4 - Data Exfiltration Detection](Week-2/Day-4/README.md)
- [Week 2 Day 5 - Persistence and Backdoor Detection](Week-2/Day-5/README.md)
- [Week 2 Day 6 - Full Threat Hunting Investigation](Week-2/Day-6/README.md)
- [Week 2 Day 7 - Threat Hunting Wrap-Up and Real SOC Thinking](Week-2/Day-7/README.md)

</details>

<details>
<summary><strong>Week 3</strong></summary>

- [Week 3 Day 1 - Your First SOC-Style PCAP Investigation](Week-3/Day-1/README.md)
- [Week 3 Day 2 - Network Monitoring with Zeek](Week-3/Day-2/README.md)
- [Week 3 Day 3 - IDS Detection with Suricata](Week-3/Day-3/README.md)
- [Week 3 Day 4 - DNS Analysis (C2 + Exfiltration)](Week-3/Day-4/README.md)
- [Week 3 Day 5 - Flow Analysis and Beaconing Detection](Week-3/Day-5/README.md)
- [Week 3 Day 6 - Advanced Detection Engineering (Suricata)](Week-3/Day-6/README.md)
- [Week 3 Day 7 - False Positives and Tuning (Suricata)](Week-3/Day-7/README.md)

</details>

<details>
<summary><strong>Week 4</strong></summary>

- [Week 4 Day 1 - Process Analysis (Osquery)](Week-4/Day-1/README.md)
- [Week 4 Day 2 - Behavioral Hunting (Osquery Advanced)](Week-4/Day-2/README.md)
- [Week 4 Day 3 - Timeline and Attack Reconstruction](Week-4/Day-3/README.md)
- [Week 4 Day 4 - Persistence Mechanisms (Osquery)](Week-4/Day-4/README.md)
- [Week 4 Day 5 - Memory & Fileless Detection (Osquery)](Week-4/Day-5/README.md)
- [Week 4 Day 6 - Endpoint Detection Engineering (Build Your Own Detections)](Week-4/Day-6/README.md)
- [Week 4 Day 7 - False Positive Tuning (Production-Ready Detections)](Week-4/Day-7/README.md)

</details>

<details>
<summary><strong>Week 5</strong></summary>

- [Week 5 Day 1 - Security Automation (SOAR Fundamentals + Python Detection Automation)](Week-5/Day-1/README.md)

</details>

## Current Progress

- Completed: 29 module(s) (through Week 5 Day 1)
- Next module: Week 5 Day 2

<details>
<summary><strong>Progress Automation (click to expand)</strong></summary>

The root progress sections are maintained by `scripts/sync-progress.ps1`.

Run from the repository root:

```powershell
.\scripts\sync-progress.ps1
```

Value add:

- Demonstrates practical scripting to automate repetitive documentation tasks
- Enforces a single source of truth for module completion and progress tracking
- Improves consistency, reduces manual drift, and keeps updates collaborator-ready

</details>













