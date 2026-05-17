# Week 7 Day 2 Report: Evidence Collection and Triage

Week 7 Day 2 focused on turning the Day 1 incident artifacts into a practical evidence collection and triage workflow. The goal was not just to extract indicators, but to show the process end-to-end: inventory hosts, extract IOCs, rank systems by criticality, apply escalation logic, and generate collection tasks for investigation.

## Objective

Build a lightweight incident triage pipeline that demonstrates:

- IOC extraction from logs and timeline artifacts
- Suspicious host triage using severity scoring
- Escalation logic based on ownership and exposure
- Collection task generation for investigation-ready systems
- False-positive tuning for noisy IOC detection

## Day Scope

Implemented four small scripts and a host inventory file:

- `host_inventory.json`: Host list with hostname, IP, criticality, and owner
- `ioc_extractor.py`: Regex-based IOC extraction from logs and timeline output
- `triage.py`: Host prioritization and escalation logic
- `collector.py`: Generate collection tasks for hosts that require investigation

The workflow used Day 1 artifacts as input and Day 2 logic to move from evidence preservation into operational triage.

## Starting State

Before writing new logic, the Day 1 artifacts were already available in the directory:

```bash
cd ~/soar-lab/week7/day2
ls
```

The folder contained the evidence and timeline outputs needed for triage, including:

- `alerts.log`
- `failed.log`
- `success.log`
- `incident_timeline.json`
- other JSON evidence files from the prior module

## 1. Host Inventory

Created a simple host inventory for triage ranking:

```json
{
  "hosts": [
    {
      "hostname": "wkstn-01",
      "ip": "10.0.1.15",
      "criticality": "high",
      "owner": "finance"
    },
    {
      "hostname": "srv-web-01",
      "ip": "10.0.2.10",
      "criticality": "critical",
      "owner": "web"
    },
    {
      "hostname": "devbox-02",
      "ip": "10.0.3.44",
      "criticality": "medium",
      "owner": "engineering"
    }
  ]
}
```

This inventory becomes the anchor for prioritization and escalation decisions.

## 2. IOC Extraction

The first version of the extractor used a simple regex set for IPv4, domains, and SHA256 hashes:

```python
IOC_PATTERNS = {
    "ipv4": r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b",
    "domain": r"\b[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b",
    "sha256": r"\b[a-fA-F0-9]{64}\b"
}
```

The extraction routine scanned multiple files:

```python
FILES_TO_SCAN = [
    "alerts.log",
    "failed.log",
    "success.log",
    "incident_timeline.json"
]
```

The core flow was:

```python
def extract_iocs():
    results = {
        "ipv4": set(),
        "domain": set(),
        "sha256": set()
    }

    for filename in FILES_TO_SCAN:
        try:
            with open(filename, "r") as f:
                content = f.read()

            for ioc_type, pattern in IOC_PATTERNS.items():
                matches = re.findall(pattern, content)
                for match in matches:
                    results[ioc_type].add(match)
        except FileNotFoundError:
            print(f"[-] Missing file: {filename}")
```

### Initial IOC Extraction Command

```bash
python3 ioc_extractor.py
cat ioc_report.json
```

### Initial Result

The first pass correctly extracted a suspicious IP and a malicious domain, but it also caught noisy false positives like filenames and script names. That was a useful triage lesson: a broad domain regex will happily match things that look domain-like but are not actionable indicators.

## 3. False-Positive Tuning

To reduce noise, the domain logic was tightened and a small denylist was added.

### Improved Domain Pattern

```python
IOC_PATTERNS = {
    "ipv4": r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b",
    "sha256": r"\b[a-fA-F0-9]{64}\b",
    "md5": r"\b[a-fA-F0-9]{32}\b",
    "url": r"https?://[^\s\"']+",
    "email": r"\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b",
    "domain": r"\b(?:[a-zA-Z0-9-]+\.)+(?:com|net|org|io|co|biz|info)\b"
}
```

### Noise Filter

```python
NOISE_DOMAINS = {
    "actors.json",
    "alerts.log",
    "campaigns.json",
    "cases.json",
    "failed.log",
    "success.log",
    "payload.exe",
    "dropper.sh",
    "a.sh"
}
```

### Filter Logic

```python
if ioc_type == "domain" and match in NOISE_DOMAINS:
    continue
```

After the tuning pass, the extraction output was much cleaner and the reported domains were mostly real IOC-style indicators.

### Improved IOC Output

```json
{
  "ipv4": [
    "10.0.1.15"
  ],
  "domain": [
    "beacon.badcommand.org",
    "evil.example.com",
    "new-malicious.example.net",
    "stage-c2.example.net"
  ],
  "sha256": [
    "032aba2a5b544db6924f7ac98b2878f6e9dbd589d1645a4c842b7d1736f55000",
    "0787242bae7cbeebe7147445b16a610d04a7ca93f84bff6405df97b7f61e9daa"
  ],
  "md5": [
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "d41d8cd98f00b204e9800998ecf8427e"
  ],
  "url": [
    "http://evil.example.com/payload.exe",
    "http://new-malicious.example.net/a.sh",
    "http://stage-c2.example.net/dropper.sh"
  ],
  "email": [
    "attacker@evil.example.com"
  ]
}
```

## 4. Triage Logic

The triage script converts host criticality into a priority score and decides whether each host requires investigation.

### Scoring Matrix

```python
SEVERITY_MATRIX = {
    "critical": 10,
    "high": 7,
    "medium": 5,
    "low": 2
}
```

### Escalation Logic

```python
def escalation_action(owner, suspicious):
    if owner == "finance" and suspicious:
        return "escalate immediately"
    if owner == "engineering" and suspicious:
        return "monitor"
    if owner == "web" and suspicious:
        return "isolate if suspicious"
    return "no immediate escalation"
```

### Triage Build Flow

```python
def build_triage():
    inventory = load_json("host_inventory.json")
    iocs = load_json("ioc_report.json")

    suspicious = (
        len(iocs.get("ipv4", [])) > 0 or
        len(iocs.get("domain", [])) > 0 or
        len(iocs.get("sha256", [])) > 0
    )
```

Each host is then scored and annotated:

```python
triage.append({
    "hostname": host["hostname"],
    "ip": host["ip"],
    "owner": host["owner"],
    "criticality": host["criticality"],
    "priority_score": score,
    "requires_investigation": suspicious,
    "escalation_action": escalation_action(host["owner"], suspicious)
})
```

### Triage Command

```bash
python3 triage.py
cat triage_report.json
```

### Triage Outcome

The highest-priority host was `srv-web-01`, followed by the finance workstation and the added suspicious host `weird_PC`. The ownership-based escalation logic worked as intended:

- finance: escalate immediately
- engineering: monitor
- web: isolate if suspicious

## 5. Collection Task Generation

The collector turns triage output into a practical response checklist for every system that requires investigation.

### Collection Script

```python
def generate_collection_tasks():
    triage = load_json("triage_report.json")

    tasks = []

    for system in triage:
        if system["requires_investigation"]:
            tasks.append({
                "hostname": system["hostname"],
                "collection_actions": [
                    "Acquire auth logs",
                    "Collect running processes",
                    "Capture network connections",
                    "Preserve suspicious files"
                ],
                "priority_score": system["priority_score"],
                "generated_at": datetime.now().isoformat()
            })
```

### Collection Command

```bash
python3 collector.py
cat collection_tasks.json
```

### Collection Task Result

All suspicious hosts received the same core collection checklist, with tasks sorted by priority score. That gives the analyst a clean starting queue for evidence gathering.

## 6. Exercises Completed

### Exercise 1
Added another suspicious host to `host_inventory.json`.

### Exercise 2
Appended a fake malicious domain to `alerts.log` and re-ran IOC extraction:

```bash
echo "Suspicious outbound beacon to beacon.badcommand.org from 10.0.1.15" >> alerts.log
python3 ioc_extractor.py
```

### Exercise 3
Adjusted the severity mapping to:

```python
critical = 10
high = 7
medium = 5
low = 2
```

### Exercise 4
Added hostname ownership escalation logic for finance, engineering, and web.

### Exercise 5
Extended IOC extraction to detect:

- MD5 hashes
- URLs
- email addresses

## 7. Final Workflow Summary

The Day 2 workflow looked like this:

```bash
cd ~/soar-lab/week7/day2
ls
python3 ioc_extractor.py
cat ioc_report.json
python3 triage.py
cat triage_report.json
python3 collector.py
cat collection_tasks.json
```

And the process produced the following artifacts:

- `host_inventory.json`
- `ioc_extractor.py`
- `ioc_report.json`
- `triage.py`
- `triage_report.json`
- `collector.py`
- `collection_tasks.json`
- `week7_day2_report.md`

## Key Learning Outcomes

- IOC extraction needs tuning to avoid broad regex false positives.
- Triage should combine technical evidence with business context.
- Severity scoring is more useful when paired with ownership-based escalation.
- Collection planning should be generated from investigation priority, not manually assembled every time.
- Small data files and scripts are enough to model a realistic incident response workflow.

## Day 2 Completion

Week 7 Day 2 is complete.

The main improvement over the first iteration was not just broader IOC extraction, but better signal quality. The false-positive reduction step was the most realistic part of the module because it reflected the kind of tuning analysts actually do in live response work.

## Next Step

Week 7 Day 3: Log and Timeline Correlation
