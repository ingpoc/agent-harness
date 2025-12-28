# Session Management Patterns

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    SESSION LIFECYCLE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [SESSION START]                                             │
│       │                                                      │
│       ├── Load orchestrator skill                           │
│       ├── Read state.json (or initialize)                   │
│       ├── Check feature-list.json                           │
│       └── Determine initial state                           │
│                                                              │
│  [ACTIVE SESSION]                                            │
│       │                                                      │
│       ├── Execute state procedures                          │
│       ├── Monitor context usage                             │
│       ├── Compress when needed                              │
│       └── Transition states as conditions met               │
│                                                              │
│  [SESSION END]                                               │
│       │                                                      │
│       ├── Update state.json                                 │
│       ├── Write session summary                             │
│       ├── Capture traces for learning                       │
│       └── Clean up temp files                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Session Initialization

```bash
#!/bin/bash
# scripts/session-init.sh

# Create progress directory if needed
mkdir -p .claude/progress

# Initialize state if not exists
if [ ! -f .claude/progress/state.json ]; then
    echo '{"state": "START", "entered_at": "'$(date -Iseconds)'", "history": []}' > .claude/progress/state.json
fi

# Check for feature list
if [ ! -f .claude/progress/feature-list.json ]; then
    echo "NO_FEATURE_LIST"
else
    PENDING=$(jq '[.features[] | select(.status=="pending")] | length' .claude/progress/feature-list.json)
    if [ "$PENDING" -gt 0 ]; then
        echo "HAS_PENDING_FEATURES"
    else
        echo "ALL_COMPLETE"
    fi
fi
```

## Session State Recovery

When resuming a session:

```python
def recover_session():
    state = read_json(".claude/progress/state.json")

    # Check if previous session ended cleanly
    if state.get("dirty", False):
        # Crashed mid-operation
        rollback_to_last_known_good(state)

    # Resume from current state
    return state.get("state", "START")
```

## Session Summary Generation

At session end, generate summary for continuity:

```markdown
# Session Summary - {timestamp}

## State
- Final state: [STATE]
- Features completed: [N]
- Features remaining: [M]

## Work Done
1. [Feature X] - Implemented and tested
2. [Feature Y] - Implementation complete, testing pending

## Decisions Made
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Blockers
- [ ] [Blocker 1] - [Suggested resolution]

## Next Session
1. Resume from state: [STATE]
2. Continue with feature: [FEATURE_ID]
3. Address blockers: [LIST]

## Files Modified
- [file1.py] - [summary]
- [file2.py] - [summary]
```

## Session Files

| File | Purpose | Lifetime |
|------|---------|----------|
| `state.json` | Current state, feature context | Persistent |
| `feature-list.json` | All features with status | Persistent |
| `session-summary.md` | Last session summary | Per session |
| `/tmp/test-evidence/` | Test artifacts | Per session |
| `/tmp/active-agent.json` | Agent identity (for hooks) | Per session |

## Session Handoff (Cross-Session Continuity)

```python
def prepare_handoff():
    """Prepare context for next session"""

    # 1. Update state file
    update_state({
        "dirty": False,
        "last_action": get_last_action(),
        "timestamp": now()
    })

    # 2. Generate summary
    summary = generate_session_summary()
    write_file("/tmp/summary/session_{timestamp}.md", summary)

    # 3. Capture learning traces
    capture_session_traces()

    # 4. Clean temp files (keep evidence)
    cleanup_temp_except(["test-evidence", "summary"])
```

## Auto-Save Checkpoints

```python
CHECKPOINT_INTERVAL = 300  # 5 minutes

def checkpoint():
    """Create recovery checkpoint"""
    save_state({
        "checkpoint_at": now(),
        "context_snapshot": get_context_summary(),
        "pending_actions": get_pending_actions()
    }, ".claude/progress/checkpoint.json")
```

## Session Metrics

Track for optimization:

| Metric | What to Track | Use |
|--------|---------------|-----|
| Duration | Total session time | Efficiency |
| States visited | Count per state | Flow analysis |
| Compressions | Count and triggers | Context management |
| Retries | Failed attempts | Quality issues |
| Tokens used | Total consumption | Cost optimization |

```json
// .claude/progress/session-metrics.json
{
  "session_id": "uuid",
  "started_at": "2025-12-28T10:00:00Z",
  "ended_at": "2025-12-28T11:30:00Z",
  "states_visited": ["START", "INIT", "IMPLEMENT", "TEST", "COMPLETE"],
  "compressions": 2,
  "retries": 1,
  "tokens_used": 45000,
  "features_completed": 3
}
```

## Error Recovery

| Error Type | Detection | Recovery |
|------------|-----------|----------|
| Crash mid-state | `dirty: true` in state.json | Rollback to last checkpoint |
| Hook rejection | Exit code 2 | Log, adjust, retry |
| Context overflow | 95% capacity | Emergency compression |
| Tool failure | Exception | Retry with backoff |
| Test timeout | No response > 5min | Kill, mark blocked |

```python
def recover_from_error(error_type: str):
    if error_type == "crash":
        state = load_checkpoint()
        log_recovery("Recovered from crash to checkpoint")

    elif error_type == "context_overflow":
        compress_context("emergency")
        log_recovery("Emergency compression applied")

    elif error_type == "tool_failure":
        retry_with_backoff(max_retries=3)
```
