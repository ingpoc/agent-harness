# Context Graph System - Evolved Design

## Key Insight

> **Rules are instructions, not enforcements. The system needs verification gates, not more documentation.**

Current state: 500+ lines of "MUST", "NEVER", "CRITICAL" rules across agents. Claude can ignore them all.

Needed: Runtime mechanisms that **block invalid actions** rather than instruct against them.

---

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: ORCHESTRATION                                     │
│  "Who does what, when"                                      │
│                                                             │
│  • Main agent auto-selects next action (no user prompting)  │
│  • State machine: init → code → test → next                 │
│  • Proactive agent spawning based on state                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: ENFORCEMENT                                       │
│  "Verification gates that block invalid transitions"        │
│                                                             │
│  • Hooks that BLOCK, not just log                           │
│  • tested:true requires non-empty data verification         │
│  • Tool usage enforcement (MCP for logs, not Read)          │
│  • Subagents literally cannot write certain fields          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: LEARNING                                          │
│  "Context graph that feeds back into enforcement"           │
│                                                             │
│  • Capture when enforcement triggers                        │
│  • Extract patterns from violations                         │
│  • Create new guards from repeated violations               │
│  • Query before decisions for precedent                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Current Agents Analysis

| Agent | Keep | Change | Remove |
|-------|------|--------|--------|
| **initializer** | Project setup, feature breakdown | Add: query past project patterns | - |
| **coding** | Implementation, MCP usage, scripts | Remove: 500 lines of rules → Move to enforcement layer | Health check (duplicate) |
| **tester** | Browser testing, validation | Remove: "EMPTY = FAIL" rules → Move to enforcement gate | - |
| **verifier** | - | - | **Remove entirely** - redundant with coding-agent health check |

### Agent Simplification Principle

> Agents should be **focused on their task**, not policing themselves. Enforcement is external.

**Before** (current):
```
coding-agent.md: 500 lines
  - 200 lines: "how to implement"
  - 300 lines: "what NOT to do" (rules)
```

**After** (proposed):
```
coding-agent.md: 150 lines
  - 150 lines: "how to implement"

enforcement-hooks/: handles "what NOT to do"
```

---

## Layer 1: Orchestration

### State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                    SESSION STATE MACHINE                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [SESSION_START]                                            │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────┐    no feature-list    ┌─────────────┐         │
│  │ CHECK   │ ──────────────────────▶ INITIALIZER │         │
│  │ STATE   │                        └──────┬──────┘         │
│  └────┬────┘                               │                │
│       │ has feature-list                   │                │
│       ▼                                    ▼                │
│  ┌─────────────────────────────────────────────────┐       │
│  │              FEATURE LOOP                        │       │
│  │  ┌────────┐     ┌────────┐     ┌────────┐      │       │
│  │  │ CODING │ ──▶ │ TESTER │ ──▶ │  NEXT  │ ─┐   │       │
│  │  └────────┘     └────────┘     └────────┘  │   │       │
│  │       ▲                              │     │   │       │
│  │       └──────────────────────────────┘     │   │       │
│  │                (if more features)          │   │       │
│  └────────────────────────────────────────────┼───┘       │
│                                               │            │
│                                               ▼            │
│                                        [SESSION_END]       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Auto-Orchestration Rules

| State | Condition | Action | No User Prompt Needed |
|-------|-----------|--------|----------------------|
| Session start | No feature-list.json | Spawn initializer | ✓ |
| Session start | Has pending features | Spawn coding-agent | ✓ |
| Coding complete | status: completed | Spawn tester-agent | ✓ |
| Test passed | tested: true | Select next feature | ✓ |
| Test failed | tested: false, retry < 2 | Resume coding-agent | ✓ |
| Test failed 2x | retry >= 2 | Mark blocked, next feature | ✓ |
| All complete | No pending features | End session | ✓ |

### Main Agent Becomes Pure Orchestrator

```markdown
# Main Agent (Opus)

You are the orchestrator. You do NOT implement. You delegate.

## On Session Start
1. Read .claude/progress/session-state.json
2. Read .claude/progress/feature-list.json
3. Determine state → spawn appropriate agent
4. NO user prompting needed

## State Transitions
- No feature-list → spawn initializer-agent
- Pending feature → spawn coding-agent
- Completed feature → spawn tester-agent
- All done → report summary

## Rules
- NEVER implement directly (use coding-agent)
- NEVER test directly (use tester-agent)
- ALWAYS spawn, wait, handle result
```

---

## Layer 2: Enforcement

### Enforcement Hooks (Not Rules)

| Hook | Trigger | Action | Replaces |
|------|---------|--------|----------|
| `block-tested-true.sh` | Write to feature-list.json with tested:true | Verify data non-empty, block if empty | 200 lines of "EMPTY = FAIL" rules |
| `enforce-mcp-logs.sh` | Read() called on *.log file | Warn + suggest MCP tool | "Use MCP for logs" instruction |
| `verify-implementation.sh` | coding-agent returns | Check files actually changed | "Implement before returning" rule |
| `block-direct-edit.sh` | Opus edits src/ directly | Block, spawn coding-agent | "Don't implement directly" rule |

### Hook Implementation Pattern

```bash
#!/bin/bash
# block-tested-true.sh
# Runs BEFORE feature-list.json write is committed

FEATURE_FILE=".claude/progress/feature-list.json"
TEMP_FILE="$1"  # Proposed new content

# Extract the feature being marked tested:true
FEATURE_ID=$(jq -r '.features[] | select(.tested == true and .previously_tested != true) | .id' "$TEMP_FILE")

if [ -n "$FEATURE_ID" ]; then
    # Verify data is non-empty
    VERIFICATION=$(bash .claude/scripts/verify_feature_data.sh "$FEATURE_ID")

    if [ "$VERIFICATION" == "EMPTY" ]; then
        echo "BLOCKED: Cannot mark $FEATURE_ID as tested - data is empty"
        echo "Run tester-agent with actual data verification"
        exit 1  # Block the write
    fi
fi

exit 0  # Allow the write
```

### Enforcement vs Rules Comparison

| Approach | Can Be Ignored? | Token Cost | Effectiveness |
|----------|-----------------|------------|---------------|
| Rule in prompt | Yes | High (loaded every time) | Low |
| Hook that blocks | No | Zero (external) | High |
| Post-hoc check | N/A (too late) | Medium | Low |

---

## Layer 3: Learning (Context Graph)

### Integration with Enforcement

```
┌─────────────────────────────────────────────────────────────┐
│                   LEARNING FEEDBACK LOOP                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Enforcement hook triggers (blocks invalid action)       │
│                    │                                        │
│                    ▼                                        │
│  2. Log to context graph:                                   │
│     {                                                       │
│       "type": "violation_blocked",                          │
│       "agent": "coding-agent",                              │
│       "action": "mark_tested_true",                         │
│       "reason": "empty_data",                               │
│       "context": "feature PT-003"                           │
│     }                                                       │
│                    │                                        │
│                    ▼                                        │
│  3. Pattern detection:                                      │
│     "coding-agent tried to skip testing 5 times"            │
│                    │                                        │
│                    ▼                                        │
│  4. Feedback options:                                       │
│     a) Add stronger enforcement                             │
│     b) Modify agent prompt                                  │
│     c) Create new hook                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Context Graph Tools (in Token-Efficient MCP)

| Tool | Purpose | When Called |
|------|---------|-------------|
| `store_trace()` | Log decision/correction/violation | After enforcement triggers, after user correction |
| `query_traces()` | Find similar past situations | Before agent makes decision |
| `extract_patterns()` | Aggregate traces into patterns | End of session or on-demand |
| `create_guard()` | Generate new enforcement hook | When pattern threshold met |

### Trace Schema

```json
{
    "id": "trace-uuid",
    "project": "project-name",
    "timestamp": "2025-12-27T10:00:00Z",
    "type": "correction|violation|decision|approval",

    "context": {
        "agent": "coding-agent",
        "feature": "PT-003",
        "task": "implement morning session"
    },

    "event": {
        "what_happened": "Agent marked tested:true with empty data",
        "what_was_correct": "Should verify non-empty response first",
        "why": "Empty data means feature not actually working"
    },

    "source": "enforcement_hook|user_correction|auto_detected",

    "embedding": [...]  // For semantic search
}
```

---

## Simplified Agent Specifications

### initializer-agent (unchanged)

```yaml
name: initializer-agent
purpose: Project setup and feature breakdown
tools: Write, Read, Bash, Edit, Grep, Glob
skills: project-initialization
```

### coding-agent (simplified)

```yaml
name: coding-agent
purpose: Implement features, return for testing
tools: Write, Read, Edit, Bash, Glob, Grep, MCP tools
skills: incremental-coding

# REMOVED: 300 lines of rules
# ADDED: Enforcement hooks handle compliance
```

**New coding-agent.md** (~100 lines):
```markdown
# Coding Agent

Implement features from feature-list.json. Return to main agent when done.

## Workflow
1. Read feature-list.json, get next pending
2. Query context graph for similar past work
3. Implement the feature
4. Run local tests
5. Return to main agent (tester-agent will validate)

## Tools
- Use MCP for log analysis
- Use scripts for verification
- Write implementation summaries to /tmp/summary/

## Output
Return: "IMPLEMENTATION COMPLETE - Feature {ID} ready for testing"
```

### tester-agent (simplified)

```yaml
name: tester-agent
purpose: Validate features through systematic testing
tools: Read, Write, Bash, Browser tools, MCP tools
skills: browser-testing

# REMOVED: 200 lines of "EMPTY = FAIL" rules
# ADDED: Enforcement hook blocks invalid tested:true
```

**New tester-agent.md** (~80 lines):
```markdown
# Tester Agent

Validate features. Only mark tested:true when ALL checks pass.

## Workflow
1. Run health check
2. Read feature context
3. Execute tests (unit, API, browser, DB)
4. Report results

## Tests
- Unit: pytest
- API: curl endpoints
- Browser: Required for UI features
- DB: Verify records

## Output
- PASSED: Feature validated, tested:true will be set
- FAILED: Return issues to main agent for fix
```

### verifier-agent: REMOVED

Health check is already in coding-agent. No need for separate verifier.

---

## Implementation Priority

| Priority | Component | Effort | Impact |
|----------|-----------|--------|--------|
| **P0** | State machine in main agent | Medium | Auto-orchestration |
| **P0** | `block-tested-true.sh` hook | Low | Prevent premature completion |
| **P1** | Simplify agent prompts | Low | Reduce token cost |
| **P1** | `store_trace()` in MCP | Medium | Learning foundation |
| **P2** | `query_traces()` in MCP | Medium | Pre-decision context |
| **P2** | Pattern extraction | Medium | Rule evolution |
| **P3** | Auto-guard creation | High | Self-improving system |

---

## Success Metrics

| Metric | Current | Target | How to Measure |
|--------|---------|--------|----------------|
| Premature completion | Frequent | Zero | Enforcement blocks |
| User prompts needed | Many | Minimal | Orchestration handles |
| Agent prompt size | 500 lines | 100 lines | Token count |
| Repeated mistakes | Common | Rare | Trace analysis |
| Rule compliance | Voluntary | Enforced | Hook triggers |

---

## Open Research Questions

| Question | Why It Matters |
|----------|----------------|
| Can hooks block writes mid-action? | Core enforcement mechanism |
| How to detect "user correction" automatically? | Auto-capture for learning |
| Should patterns auto-create hooks? | Self-evolving system |
| How to handle hook bypass for edge cases? | Flexibility vs safety |
| Cross-project learning scope? | Pattern portability |

---

## Key Principles

1. **Enforcement > Rules**: Hooks that block beats instructions that suggest
2. **Orchestrate > Prompt**: State machine beats user prompting
3. **Learn > Repeat**: Traces beat re-discovering same issues
4. **Simple agents > Complex agents**: External enforcement beats internal rules
5. **Verify > Trust**: Gates beat good intentions

---

*Updated: 2025-12-27*
*Status: Evolved Design - Ready for Research/Implementation*
