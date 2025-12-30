# Learning Layer Hooks Design

## Principle

> **Learning requires data** - Decision traces + outcomes = better future decisions

But: **Don't over-enforce** - Agent discretion for when to query, when traces matter.

---

## Hook: `require-outcome-update.py`

### Purpose

Block marking feature as `tested:true` unless the decision trace outcome is updated.

### When

PreToolUse on `Write` to `.claude/progress/feature-list.json`

### Verification

```python
# When tested:true is being set
if '"tested": true' in content:
    # Get the feature_id being marked tested
    feature_id = extract_feature_id(content)

    # Query context-graph for traces with this feature_id
    traces = context_query_traces(feature_id=feature_id)

    # Check if at least one trace has outcome != "pending"
    if all(t.outcome == "pending" for t in traces):
        print("BLOCKED: Update trace outcome before marking tested", file=sys.stderr)
        print(f"Use: context_update_outcome(trace_id, outcome='success|failure')", file=sys.stderr)
        sys.exit(2)
```

### Blocks If

- Feature has traces with `feature_id` but all outcomes are still `pending`
- Agent hasn't validated the decision that led to this feature

### Allows

- No traces exist for this feature (agent discretion)
- At least one trace has outcome set (success/failure)

---

## Hook: `remind-decision-trace.sh`

### Purpose

Non-blocking reminder to store decision trace after implementation.

### When

PreToolUse on `Write` to source files (`.py`, `.js`, `.ts`, etc.)

### Verification

```bash
# After implementation, check if trace was recently stored
recent_files=$(find .claude/progress -name "*.json" -mmin -5)
feature_modification=$(echo "$recent_files" | grep -q "feature-list")

if [[ $feature_modification ]]; then
    # Feature was just marked implemented
    # Check if context-graph has recent trace (last 10 min)
    recent_trace=$(context-query --since "10 minutes ago" | grep -c "decision")

    if [[ $recent_trace -eq 0 ]]; then
        echo "REMINDER: Consider storing decision trace for this feature"
        echo "Use: context_store_trace(decision='...', category='framework|api|...')"
        # Exit 0 - reminder only, don't block
    fi
fi
```

### Blocks

**Never** - This is a reminder, not a block

---

## Hook: `link-feature-to-trace.py`

### Purpose

Auto-link feature_id to traces when feature is created.

### When

PreToolUse on `Write` to `.claude/progress/feature-list.json` (creation)

### Verification

```python
# New feature being added
if new_feature_in_content:
    feature_id = extract_feature_id(content)

    # Store a "feature created" trace automatically
    context_store_trace(
        decision=f"Feature created: {feature['title']}",
        category="feature",
        outcome="pending",
        feature_id=feature_id
    )
```

### Blocks

Never - automatic bookkeeping

---

## What's NOT Enforced

| Action | Why Not Enforced |
|--------|-----------------|
| Query before deciding | Agent discretion - sometimes context is obvious, sometimes query helps |
| Auto-generate traces | Requires LLM interpretation - nondeterministic by definition |
| Specific trace content | Agent knows what decision matters |

---

## Trace Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│  1. FEATURE CREATED                                         │
│     → Hook: link-feature-to-trace.py                        │
│     → Auto-stores: "Feature created: [title]"              │
│     → outcome = "pending"                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. DECISIONS MADE (Agent stores manually)                  │
│     → Agent: context_store_trace("Chose FastAPI", ...)      │
│     → Agent discretion: what to log                        │
│     → Reminder: remind-decision-trace.sh (non-blocking)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. IMPLEMENTATION COMPLETE                                 │
│     → Agent marks implemented: true                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. FEATURE TESTED                                          │
│     → Hook: require-outcome-update.py                      │
│     → BLOCKS if trace outcomes still "pending"              │
│     → Agent must: context_update_outcome(trace_id, "...")  │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary Table

| Hook | Trigger | Blocks? | Purpose |
|------|---------|---------|---------|
| `link-feature-to-trace.py` | Feature created | No | Auto-link feature to trace |
| `remind-decision-trace.sh` | Implementation | No | Reminder to log decisions |
| `require-outcome-update.py` | Mark tested | **Yes** | Force outcome validation |

---

## Edge Cases

| Case | Handling |
|------|----------|
| Feature has no traces | Allowed - agent discretion |
| Multiple traces for feature | All must have outcome (or at least one) |
| Feature skipped (no implementation) | No outcome check needed |
| Manual trace (not via MCP) | Hook can't detect - agent responsibility |

---

## Configuration

`.claude/config/project.json`:

```json
{
  "context_graph": {
    "enabled": true,
    "require_outcome": true,
    "reminder_enabled": true,
    "auto_link_features": true
  }
}
```

---

*Version: 1.0*
*Part of: DESIGN-v2 Layer 3 (Learning)*
*Status: Design, not implemented*
