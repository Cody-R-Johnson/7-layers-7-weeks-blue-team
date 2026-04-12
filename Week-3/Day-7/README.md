# Week 3 Day 7 - False Positives and Tuning (Suricata)

This module captures my Week 3 Day 7 learning on reducing false positives in Suricata while preserving detection coverage in a real SOC workflow.

## Day Objective

Today I focused on the balance between detection quality and alert noise.

By the end of Day 7, I wanted to be able to:

- Explain why IDS alerts become noisy in production
- Tune rules safely without creating blind spots
- Reduce false positives with scope, context, and exceptions
- Keep coverage for low-and-slow beaconing behavior
- Write a tuned rule and defend the tuning decisions

## Concept in Practical Terms

In real SOC operations, most alerts are false positives.

If I do not tune detection logic, analysts get alert fatigue and real incidents can be missed. But if I over-tune, I create blind spots. Good tuning is controlled reduction of noise, not deleting visibility.

The mindset shift for me today:

Detection engineering is not finished when a rule fires. It is finished when the rule is useful at scale.

## Why My Day 6 Rule Can Be Noisy

From Day 6, one condition was:

```suricata
http.user_agent; content:"curl";
```

This can trigger on legitimate behavior:

- Admin scripts
- Dev automation
- Monitoring and health-check tooling
- Internal API polling

So the signal is not useless, but it needs more context and scoping.

## False Positive Investigation Workflow

Before tuning, I should answer:

- WHO triggered the alert?
- WHAT process or workflow caused it?
- WHEN does it occur (schedule, burst, random)?
- WHERE is the destination (internal, external, known-good, unknown)?

This prevents premature tuning that hides real threats.

## Tuning Techniques I Applied

### 1. Scope by Network Direction

Instead of broad matching:

```suricata
any any -> any any
```

Use directional scope:

```suricata
$HOME_NET any -> $EXTERNAL_NET any
```

This keeps focus on outbound activity and removes some internal noise.

### 2. Exclude Verified Known-Good Systems

If one monitoring server legitimately uses curl, I can exclude it with a targeted exception (for example via address variables or a pass rule), while still monitoring that host separately.

Important: baseline first, then exception.

### 3. Add Context Beyond One Indicator

Do not rely on `curl` alone. Combine with:

- Frequency thresholding
- Destination scope
- Optional URI or host filtering

### 4. Preserve Coverage with Multi-Condition Logic

Tuning should reduce random hits, not disable detection.

## LAB - SOC Scenario Answers

### 1. How do I tune the rule?

My tuning plan:

- Keep the curl indicator but restrict traffic scope to outbound
- Exclude only verified known-good internal automation hosts
- Require repeated behavior in a correlation window
- Optionally add URI or destination context if a campaign pattern exists

### 2. What do I NOT do?

- I do not disable the rule entirely
- I do not blindly trust all internal traffic
- I do not suppress broad IP ranges without evidence

Internal traffic can still be compromised, so I tune narrowly.

### 3. Final Tuned Rule

```suricata
alert http $HOME_NET any -> $EXTERNAL_NET any (
msg:"Suspicious curl beaconing";
flow:to_server,established;
http.user_agent; content:"curl";
threshold:type both, track by_src, count 10, seconds 300;
sid:100020;
rev:1;
)
```

## Advanced Challenge - Slow Beaconing Without Extra Noise

Scenario: attacker uses curl once every 5 minutes.

Exact time-mark matching is weak because attackers can add jitter (for example 290s, 310s, 305s). Instead, I use longer windows and lower counts with context.

Example approach:

```suricata
alert http $HOME_NET any -> $EXTERNAL_NET any (
msg:"Possible slow HTTP beaconing - curl";
flow:to_server,established;
http.user_agent; content:"curl";
threshold:type both, track by_src, count 3, seconds 600;
sid:100030;
rev:1;
)
```

Then I correlate this behavior in SIEM with:

- Same source repeatedly contacting same destination
- Recurring intervals over longer periods
- Supporting telemetry from Zeek and proxy logs

This improves low-and-slow detection without flooding alerts.

## Detection vs Noise Reflection

What improved in my thinking today:

- I now treat false-positive analysis as part of rule design, not an afterthought
- I tune with scoped, evidence-based exceptions rather than broad suppression
- I keep the principle that internal traffic is not automatically trusted
- I understand that behavioral correlation is required for stealthy beaconing

## Skills Demonstrated

- False-positive root-cause analysis for Suricata alerts
- Safe rule tuning using scope, thresholds, and exceptions
- Outbound-focused detection design with `$HOME_NET` and `$EXTERNAL_NET`
- Slow-beaconing detection strategy with longer windows and correlation
- Balancing alert quality and detection coverage

## Key Terms

- False positive: benign activity incorrectly flagged as malicious
- Alert fatigue: reduced analyst performance from excessive alert noise
- Tuning: refining rules to improve precision while preserving coverage
- Correlation window: time interval used to aggregate repeated behavior
- Blind spot: missing visibility caused by over-suppression or over-filtering
- Jitter: slight timing randomization used to evade strict periodic detection

## My Takeaways

What clicked for me today:

- Good tuning is controlled precision, not rule removal
- Narrow exceptions are safer than broad exclusions
- Internal traffic still needs monitoring and validation
- Slow beaconing is better detected by long-window behavior than exact timestamps
- SOC-quality detections require both accuracy and operational usability

## Week 3 Final Progress

Week 3 - Network Security is complete.

Day status:

- Day 1: Packet Analysis complete
- Day 2: Zeek Logs complete
- Day 3: Suricata Rules complete
- Day 4: DNS Analysis complete
- Day 5: Flow Analysis complete
- Day 6: Detection Engineering complete
- Day 7: Tuning and False Positives complete

Overall Week 3 progress: complete.

## Next Up

Week 4 Day 1 - Endpoint Detection and Response fundamentals.