# Week 6 Day 3 - IOC Lifecycle Management

This day moves from static IOC storage to a dynamic, time-aware intelligence system with expiration, revocation, and analyst controls.

## Day Objective

Today I built lifecycle management for the local intel database so it can:

- Track IOC state as `active`, `expired`, or `revoked`
- Automatically expire IOCs past their `expiry_date`
- Auto-extend active IOC expiry on each lifecycle run
- Decay confidence to `low` when an IOC expires
- Preserve analyst notes across lifecycle runs
- Write a structured audit log of every lifecycle action

The architecture now follows:

Intel DB → Lifecycle Run → Validate State → Update Status → Log Result → Respected by Pipeline

## Concept in Practical Terms

Before today, my intel database was static. An IOC added months ago still influenced detections at full weight even if it was stale, retracted, or superseded.

Real SOC teams manage intelligence with time-based controls:

- IOCs have a time-to-live (TTL) after which they are no longer trusted
- Analysts can revoke IOCs that were found to be incorrect or benign
- Active IOCs should refresh their expiry when still relevant
- Expired intel should not silently influence scoring at full confidence

Lifecycle management is what separates an intelligence-driven SOC from one that accumulates noise.

## What I Implemented

### 1) Lifecycle Fields (`lifecycle.py`)

The `ensure_lifecycle_fields` function adds missing metadata to each IOC record:

- `first_seen` — date the IOC was first recorded
- `last_seen` — date of most recent activity
- `status` — current lifecycle state (`active`, `expired`, `revoked`)
- `revoked` — boolean flag for analyst-triggered revocation
- `expiry_date` — date after which the IOC is considered stale
- `notes` — analyst notes field, initialized as empty string if absent

### 2) Expiration Logic

Each lifecycle run compares the current UTC date against `expiry_date`:

- If current date is past `expiry_date`, status is set to `expired`
- Expired IOCs receive confidence decay (Exercise 4)

### 3) Revocation Logic (Exercise 2)

If `revoked: true` is set on an IOC, the lifecycle run marks status as `revoked` regardless of expiry date. Revoked IOCs are ignored by the detection pipeline.

### 4) Active IOC Auto-Extend (Exercise 3)

Active IOCs that are not expired or revoked have their `expiry_date` extended by 30 days on each lifecycle run. This prevents IOCs from silently expiring when the pipeline is still seeing activity.

### 5) Confidence Decay (Exercise 4)

When an IOC transitions to `expired`, its confidence is downgraded to `low`. This ensures that if an expired IOC is somehow referenced, it carries minimal scoring weight.

### 6) Analyst Notes Preservation (Exercise 5)

The `notes` field is initialized to an empty string on first lifecycle run if absent. Subsequent runs never overwrite it. This allows analysts to attach context like:

```
"notes": "Seen in webshell campaign May 2026"
```

The lifecycle log includes `notes_preserved: true` to confirm notes were not lost.

### 7) Lifecycle Audit Log

Every processed IOC writes one JSON line to `lifecycle.log`:

```json
{"timestamp": "...", "ioc": "malicious-example.com", "section": "domains", "status": "active", "confidence": "high", "expiry_date": "2026-06-06", "notes_preserved": true}
```

### 8) Pipeline Respect for Lifecycle Status

The `lookup_domain`, `lookup_ip`, and `lookup_hash` functions in `intel.py` were updated to check lifecycle state before returning a record:

- Records with `revoked: true` return `None`
- Records with `status: expired` return `None`
- Only active records influence enrichment and scoring

## Validation Results

### Exercise 1 — Force Expiration

Set `expiry_date: "2025-01-01"` on `unknown-site.org` and ran lifecycle:

```json
{"ioc": "unknown-site.org", "status": "expired", "confidence": "low"}
```

Pipeline run confirmed this IOC no longer affected scoring.

### Exercise 2 — Revocation

Set `revoked: true` on `phish-login.example.org` and ran lifecycle:

```json
"status": "revoked"
```

The revoked IOC was correctly ignored by the detection pipeline.

### Exercise 3 — Active IOC Auto-Extend

After lifecycle run, all active IOCs had their `expiry_date` extended to `2026-06-06`, approximately 30 days forward from the run date.

### Exercise 4 — Confidence Decay

`unknown-site.org` after expiration:

```json
"status": "expired",
"confidence": "low"
```

Confidence was not manually changed — it was automatically decayed by the lifecycle processor.

### Exercise 5 — Analyst Notes Preserved

Added to `malicious-example.com`:

```json
"notes": "Seen in webshell campaign May 2026"
```

After re-running lifecycle, the note remained intact. Lifecycle log confirmed:

```json
"notes_preserved": true
```

### Final Lifecycle Log (tail)

```
{"ioc": "malicious-example.com", "status": "active", "confidence": "high", "notes_preserved": true}
{"ioc": "unknown-site.org", "status": "expired", "confidence": "low", "notes_preserved": true}
{"ioc": "phish-login.example.org", "status": "revoked", "confidence": "medium", "notes_preserved": true}
{"ioc": "198.51.100.77", "status": "active", "confidence": "high", "notes_preserved": true}
{"ioc": "e99a18c428cb38d5f260853678922e03", "status": "active", "confidence": "high", "notes_preserved": true}
```

## Scenario-Based Q&A

### Why expire IOCs instead of keeping them forever?

Threat context changes. A domain used for C2 two years ago may now be a legitimate site. Keeping it as `malicious` indefinitely causes false positives and erodes analyst trust in the system.

### Why decay confidence on expiry instead of just blocking the IOC?

Expired IOCs may still carry some signal value in edge cases. Decaying confidence allows the IOC to remain visible for review while ensuring it contributes minimally to automated scoring.

### Why auto-extend active IOCs?

If the pipeline is still seeing an IOC actively, it should not silently expire just because 30 days passed. Auto-extension keeps active threats in scope without requiring manual intervention.

### Why preserve analyst notes through lifecycle runs?

Analyst notes represent human-added context that automated systems cannot recreate. Overwriting them during a lifecycle refresh would destroy institutional knowledge about why an IOC was added or flagged.

### Why log lifecycle actions?

Lifecycle changes affect detection behavior. An audit log lets analysts trace why an IOC was expired, when it was revoked, and whether confidence was decayed — essential for post-incident review and feed quality audits.

## Key Terms

- IOC Lifecycle: The managed states an indicator moves through from creation to expiration or revocation
- TTL (Time-to-Live): The number of days an IOC remains active before expiring
- Revocation: Analyst-triggered permanent deactivation of an IOC
- Confidence Decay: Automatic reduction of confidence weight when an IOC ages out
- Auto-Extend: Refreshing the expiry date of still-active IOCs during lifecycle processing
- Analyst Notes: Human-authored context attached to an IOC and protected from automated overwrite

## My Takeaways

- Static intelligence databases become noise sources over time without lifecycle control
- Revocation and expiration serve different purposes and should be handled separately
- Confidence decay is a lightweight way to reduce the impact of stale intel without fully removing it
- Analyst notes require explicit preservation logic — automated systems will overwrite them otherwise
- Lifecycle logging is as important as ingestion logging for maintaining a trustworthy intel pipeline

Week 6 Day 3 is complete.

## Next Up

Week 6 Day 4 focuses on threat actor and campaign mapping — connecting IOCs to adversary groups and attack patterns.
