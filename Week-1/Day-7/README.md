# Week 1 Day 7 - False Positives and Detection Tuning

This module captures my Week 1 Day 7 learning on false positives, false negatives, and tuning detections to reduce alert noise.

## Day 7 Objective

Today I focused on why alerts go wrong in real environments and how detection rules need to be tuned so they stay useful.

By the end of Day 7, I wanted to be able to:

- Explain what a false positive is and why it matters in SOC work
- Use baseline context to tell likely benign activity from higher-risk activity
- Improve a noisy detection rule with better conditions
- Understand why different user roles can trigger different normal behaviors
- Compare the risk of false positives versus false negatives

## Concept in Practical Terms

A false positive happens when a detection rule triggers, but the activity is not actually malicious.

Simple example:

- A user mistypes their password several times
- A brute-force rule fires
- The activity turns out to be normal user error

This matters because too many false positives create alert fatigue.

That can lead to:

- Analysts ignoring alerts
- Real threats being missed
- Slower response and lower trust in detections

Detection tuning is the process of improving rules so they keep meaningful threats while reducing unnecessary noise.

## Scenario Review

### Current rule

> Alert if 3 failed logins occur in 5 minutes.

### Real activity observed

- User `cody` fails login 3 times at 9:00 AM
- User `cody` logs in successfully at 9:02 AM

## My Analysis

### 1. Is this a real threat or a false positive?

This looks like a false positive, although I would still verify it before dismissing it.

Why:

- The activity happens during normal working hours
- The same user successfully logs in almost immediately after
- The pattern fits a likely password mistake more than an active attack

### 2. What part of the baseline helps explain it?

The activity aligns with baseline behavior because it involves a known user during normal office hours, which supports the idea of ordinary user error rather than malicious activity.

### 3. How I would improve the rule

I would add more context so the rule does not trigger on every short burst of failed attempts.

Improved approach:

> Alert if multiple failed login attempts occur from an unfamiliar IP or outside normal hours, and are not followed by a successful login within a short time window.

That keeps suspicious behavior in scope while reducing noise from normal login mistakes.

## Tuning Mindset

Scenario:

The rule also triggers on:

- IT admins running scripts
- Developers installing tools
- Normal automation

### 4. Why this is a problem

Different users and roles have different baseline behaviors, so a rule that ignores context can create excessive false positives.

In practice, activity that looks unusual for one group may be completely normal for another.

### 5. Two ways to reduce false positives

- Use baseline-aware logic such as time, user role, location, and expected behavior patterns
- Filter or whitelist known-good activity such as trusted IP ranges, expected admin actions, or normal automation

Other valid tuning methods could include threshold changes or excluding known benign processes.

## Bonus Concept

Which is worse?

- A: Too many false positives
- B: Too many false negatives

My conclusion: false negatives are worse.

Reason:

- A false positive creates noise and wastes analyst time
- A false negative means a real attack is missed
- Missed attacks allow attackers to stay active, cause damage, or exfiltrate data without being detected

Interview-ready version:

> False negatives are worse because they represent real threats that were not detected, giving attackers more time and freedom to operate.

## Mini Challenge Reflection

The biggest lesson from Day 7 was that tuning is not about making alerts disappear.

It is about improving signal quality.

Good tuning should:

- Reduce unnecessary noise
- Preserve high-value detections
- Make analyst time more effective

## Key Terms

- False positive: benign activity incorrectly flagged as malicious
- False negative: malicious activity that is not detected
- Detection tuning: refining rules to improve signal quality and reduce noise
- Alert fatigue: reduced effectiveness caused by excessive alert volume
- Whitelisting: excluding known-good activity from detection logic
- Signal-to-noise ratio: how much useful alerting value exists compared to unnecessary noise

## My Takeaways

Day 7 helped tie together everything from Week 1.

What clicked for me:

- A rule can be technically correct and still be operationally noisy
- Baselines and context make detections much more practical
- Tuning is essential if alerts are going to stay useful
- Missed attacks are more dangerous than wasted analyst time, even though both matter

## Next Up

Week 2 will shift into threat hunting.