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

### Compaction Strategy (Sub-Agent Returns)

From [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):

**Sub-agent distillation pattern**: Specialized agents return condensed summaries (1K-2K tokens), not full context

| Agent Returns | What to Include | Token Budget |
|---------------|-----------------|--------------|
| **coding-agent** | Files changed, tests run, issues found | ~1K tokens |
| **tester-agent** | Test results, evidence paths, pass/fail | ~1K tokens |
| **initializer-agent** | Feature list, setup summary, next steps | ~1.5K tokens |

**What to discard** (compaction):
- Redundant tool outputs
- Raw logs (once analyzed)
- Verbose intermediate results
- Historical context beyond recent 5 files

**What to preserve**:
- Architectural decisions
- Unresolved bugs
- Implementation details
- Recent work artifacts

### Handoff Protocol

From multi-agent coordination research:

| Element | Description | Example |
|---------|-------------|---------|
| **Precondition** | What must be complete | Code written, linted |
| **Artifacts** | What's passed along | File paths, test results |
| **Postcondition** | What next agent expects | Ready-to-test state |
| **Rollback** | How to handle failures | Return to previous state |

**Command object schema** (for handoffs):
```json
{
  "command": {
    "agent": "tester-agent",
    "task": "validate_feature",
    "context": {
      "feature_id": "PT-003",
      "files_changed": ["src/feature.py"],
      "previous_state": "coding"
    },
    "success_criteria": {
      "tests_pass": true,
      "coverage_min": 80
    },
    "next_agent": "main"
  }
}
```

**Handoff best practices**:
- Explicit context (command objects, not implicit state)
- Verification (next agent validates preconditions)
- Idempotency (handoff safe to retry)
- Observability (log every handoff with context)
- Timeout (fail fast if agent unresponsive)

---

## Layer 2: Enforcement

### Research Confirmed: Hooks CAN Block Actions

**Verified mechanisms (Claude Code docs + testing):**

| Mechanism | How | Effect |
|-----------|-----|--------|
| **Exit code 2** | `exit 2` + stderr message | Blocks action, feeds stderr to Claude |
| **JSON decision** | `"permissionDecision": "deny"` | Structured blocking with reason |
| **Parameter modification** | `updatedInput` field (v2.0.10+) | Modify tool params before execution |
| **Stop blocking** | `"decision": "block"` on Stop hook | Forces agent to continue working |

### Hook Timing Points

| Event | Can Block? | Use Case |
|-------|------------|----------|
| **PreToolUse** | ✅ Yes | Block writes, validate state changes |
| **PermissionRequest** | ✅ Yes | Custom approval logic |
| **Stop/SubagentStop** | ✅ Yes | Force continuation until quality gates pass |
| **PostToolUse** | ❌ No | Feedback only (tool already ran) |

**Limitation**: Cannot stop mid-execution. Hooks fire at decision points only.

### Enforcement Hooks

| Hook | Event | Trigger | Action | Replaces |
|------|-------|---------|--------|----------|
| `block-tested-true.py` | PreToolUse | Write to feature-list.json with tested:true | Verify evidence exists, deny if empty | 200 lines of rules |
| `force-tester-completion.py` | SubagentStop | tester-agent tries to stop | Block until tests actually pass | "Don't stop early" rules |
| `enforce-mcp-logs.py` | PreToolUse | Read() on *.log file >1000 lines | Deny + suggest MCP tool | "Use MCP" instruction |
| `block-direct-edit.py` | PreToolUse | Opus edits src/ directly | Deny, suggest coding-agent | "Don't implement" rule |

### Hook Implementation: Exit Code 2 Pattern

```python
#!/usr/bin/env python3
# .claude/hooks/block-tested-true.py
# PreToolUse hook - blocks marking tested:true without evidence

import json
import sys
import os

input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

# Only check Write/Edit to feature files
if tool_name not in ["Write", "Edit"]:
    sys.exit(0)

file_path = tool_input.get("file_path", "")
content = tool_input.get("content", "") or tool_input.get("new_string", "")

if "feature-list.json" not in file_path:
    sys.exit(0)

# Check if marking tested:true
if '"tested": true' in content or '"tested":true' in content:
    # Look for test evidence in session
    evidence_dir = "/tmp/test-evidence"
    has_evidence = os.path.exists(evidence_dir) and os.listdir(evidence_dir)

    if not has_evidence:
        print("BLOCKED: Cannot mark feature as tested without evidence.", file=sys.stderr)
        print("Required: Test logs, screenshots, or API responses in /tmp/test-evidence/", file=sys.stderr)
        sys.exit(2)  # Exit 2 = blocking error

sys.exit(0)
```

### Hook Implementation: JSON Decision Pattern

**Challenge**: SubagentStop input has NO agent identification fields (no agent_id, agent_name, agent_type).

**Solution**: State file handshake - agents write identity on start, hooks read it.

```python
#!/usr/bin/env python3
# .claude/hooks/force-tester-completion.py
# SubagentStop hook - blocks tester from stopping without results

import json
import sys
import os

input_data = json.load(sys.stdin)

# Agent identification via state file (SubagentStop has no agent_id field)
agent_state_file = "/tmp/active-agent.json"
if not os.path.exists(agent_state_file):
    sys.exit(0)  # No agent state, allow stop

with open(agent_state_file) as f:
    agent_state = json.load(f)

# Only enforce for tester-agent
if agent_state.get("agent") != "tester-agent":
    sys.exit(0)  # Not tester, allow stop

# Check test evidence
test_state_file = "/tmp/test-state.json"
if os.path.exists(test_state_file):
    with open(test_state_file) as f:
        test_state = json.load(f)
else:
    test_state = {"tests_run": 0, "tests_passed": 0}

# Block if no tests were actually run
if test_state.get("tests_run", 0) == 0:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "SubagentStop",
            "decision": "block",
            "reason": "No tests executed. Run at least one test before stopping."
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Allow stop if tests ran
sys.exit(0)
```

**Agent-side requirement** (in tester-agent prompt):
```markdown
## On Start
Write agent identity: `echo '{"agent": "tester-agent", "started": "'$(date -Iseconds)'"}' > /tmp/active-agent.json`

## On Test Execution
Update test state: `echo '{"tests_run": N, "tests_passed": M}' > /tmp/test-state.json`
```

### Hook Implementation: Parameter Modification (v2.0.10+)

```python
#!/usr/bin/env python3
# .claude/hooks/enforce-safe-paths.py
# PreToolUse hook - modifies file paths to safe locations

import json
import sys

input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

if tool_name == "Write":
    file_path = tool_input.get("file_path", "")

    # Force summaries to /tmp/summary/
    if "summary" in file_path.lower() and not file_path.startswith("/tmp/"):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Redirecting summary to /tmp/summary/",
                "updatedInput": {
                    "file_path": f"/tmp/summary/{os.path.basename(file_path)}"
                }
            }
        }
        print(json.dumps(output))
        sys.exit(0)

sys.exit(0)
```

### settings.json Hook Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": { "tool_name": "Write" },
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/block-tested-true.py"
          }
        ]
      },
      {
        "matcher": { "tool_name": "Read" },
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/enforce-mcp-logs.py"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/force-tester-completion.py"
          }
        ]
      }
    ]
  }
}
```

### Enforcement vs Rules Comparison

| Approach | Can Be Ignored? | Token Cost | Effectiveness |
|----------|-----------------|------------|---------------|
| Rule in prompt | Yes | High (loaded every time) | Low |
| Hook that blocks (exit 2) | **No** | Zero (external) | **High** |
| Hook with JSON decision | **No** | Zero (external) | **High** |
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

### Progressive Disclosure for Context Graph

Pattern from Anthropic's MCP article: **150K → 2K tokens (98.7% savings)**

> "Models can read tool definitions on-demand, rather than loading them all up-front."

**Apply to trace queries:**

| Detail Level | Returns | Token Cost | When to Use |
|--------------|---------|------------|-------------|
| `metadata` | id, type, timestamp, agent | ~500 | Discovery - what exists |
| `summary` | metadata + what/why | ~1K | Relevance check - is this useful? |
| `full` | Complete trace with context | ~2K | Actual usage - need full details |

**Query pattern:**
```python
# Step 1: Find candidate traces (lightweight)
candidates = query_traces("tested without evidence", level="metadata")

# Step 2: Get summaries to filter relevant ones
summaries = [get_trace(id, level="summary") for id in candidates[:5]]

# Step 3: Load full details only for most relevant
relevant = get_trace(best_match, level="full")
```

**Token savings:**
- Without: Load 1000 traces × 50 tokens = 50K tokens
- With: metadata query + 5 summaries + 1 full = ~500 + 5K + 2K = 7.5K tokens
- **Savings: 85%**

### Learning Loop Patterns

From research: [Reflexion (NeurIPS 2023)](https://arxiv.org/abs/2303.11366), [Spotify Engineering](https://engineering.atspotify.com/2025/12/feedback-loops-background-coding-agents-part-3), [OODA Loop](https://tao-hpu.medium.com/agent-feedback-loops-from-ooda-to-self-reflection-92eb9dd204f6)

#### Reflexion Pattern (Two-Phase Reflection)

**Purpose**: Verbal reinforcement learning for across-trial improvement

**Key Mechanism**: Separate error analysis from solution generation

```
1. Agent executes action
2. Receive feedback (test results, errors)
3. REFLECT: "What assumption failed?" (LLM call #1)
4. GENERATE: "How to prevent this?" (LLM call #2)
5. Store in episodic memory
6. Retrieve on next attempt
```

**Context injection**: `LAST_ATTEMPT_AND_REFLEXION` in next prompt

#### OODA Loop (Within-Trial Adaptation)

**Purpose**: Real-time adaptation during task execution

| Stage | Action | Context |
|-------|--------|---------|
| **Observe** | Gather tool outputs, test results | Raw data |
| **Orient** | Apply past reflections + current context | Retrieved memories |
| **Decide** | Select action based on understanding | Planning |
| **Act** | Execute → generates new observations | Tool calls |

**Layered approach**: OODA (within-trial) + Reflexion (across-trial) = complete learning system

#### Spotify Verification Loops

**Architecture**:

| Component | Purpose | Metric |
|-----------|---------|--------|
| **Deterministic verifiers** | Maven/npm/build/test tools | Run on every state transition |
| **LLM Judge** | Evaluate diff + prompt | Vetoes 25% of sessions |
| **Stop hooks** | Block PR without verification | 50% course-correct after veto |

**Safety principle**: Agent doesn't know what verifiers do internally—prevents prompt injection attacks

#### Staged Promotion

```
[EXPERIMENT] → [VALIDATE] → [PRODUCTION]
     ↓              ↓               ↓
  Test suite    Auto-rollback   Versioned memory
```

**When to update vs keep existing behavior**:

| Keep Existing | Update Behavior |
|---------------|-----------------|
| Predictability critical | Performance degradation detected |
| Limited labeled feedback | Data distribution shifts |
| Preventing catastrophic forgetting | New capabilities needed |
| Regulatory/safety requirements | Tool use optimization needed |

#### Anti-Patterns Checklist

| Anti-Pattern | Symptom | Detection |
|--------------|---------|-----------|
| **Reflection without action** | Stored traces never retrieved | Check retrieval frequency |
| **Over-indexing recent failures** | Rapid strategy oscillation | Monitor variance across attempts |
| **Generic reflections** | "Reflect on performance" | Use structured prompts |
| **Self-scoring without validation** | Agent rates itself highly | Compare with external KPIs |
| **Overthinking** | Excessive planning, no action | Set max iteration limits |

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

| Priority | Component | Effort | Impact | Status |
|----------|-----------|--------|--------|--------|
| **P0** | ~~Research hooks~~ | ~~Low~~ | ~~Foundation~~ | ✅ Done |
| **P0** | `block-tested-true.py` hook | Low | Prevent premature completion | Ready |
| **P0** | `force-tester-completion.py` hook | Low | Ensure tests run | Ready |
| **P0** | State machine in main agent | Medium | Auto-orchestration | Next |
| **P1** | Simplify agent prompts | Low | Reduce token cost | |
| **P1** | `store_trace()` in MCP | Medium | Learning foundation | |
| **P2** | `query_traces()` in MCP | Medium | Pre-decision context | |
| **P2** | Pattern extraction | Medium | Rule evolution | |
| **P3** | Auto-guard creation | High | Self-improving system | |

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

## Research Questions

### ✅ Resolved

| Question | Answer |
|----------|--------|
| Can hooks block actions? | **Yes** - Exit code 2 or JSON `"decision": "deny"` |
| What events support blocking? | PreToolUse, PermissionRequest, Stop, SubagentStop |
| Can hooks modify parameters? | **Yes** - `updatedInput` field (v2.0.10+) |
| Mid-execution blocking? | **No** - Only at decision points (pre/post) |
| How to identify agent in SubagentStop? | **State file handshake** - No agent_id in input, agents write `/tmp/active-agent.json` |
| SubagentStop input fields? | session_id, transcript_path, permission_mode, hook_event_name, stop_hook_active |

### 🔍 Open

| Question | Why It Matters | Next Step |
|----------|----------------|-----------|
| How to detect user corrections? | Auto-capture for learning | Analyze PostToolUse + user response patterns |
| Should patterns auto-create hooks? | Self-evolving system | Start manual, evaluate auto-gen later |
| Hook bypass for edge cases? | Flexibility vs safety | Design `--force` flag or admin override |
| Cross-project pattern scope? | Portability | Separate project-specific vs universal traces |

---

## Key Principles

1. **Enforcement > Rules**: Hooks that block beats instructions that suggest
2. **Orchestrate > Prompt**: State machine beats user prompting
3. **Learn > Repeat**: Traces beat re-discovering same issues
4. **Simple agents > Complex agents**: External enforcement beats internal rules
5. **Verify > Trust**: Gates beat good intentions

---

*Updated: 2025-12-28*
*Status: Research Complete - Ready for Implementation*

*Changelog:*

- *Added hook blocking mechanisms (exit 2, JSON decision, updatedInput)*
- *Added SubagentStop research: no agent_id field, use state file handshake*
- *Added progressive disclosure pattern from MCP article (98.7% token savings)*
- *Added Learning Loop Patterns: Reflexion (two-phase), OODA, Spotify verification*
- *Added Compaction Strategy for sub-agent returns (1K-2K token distillation)*
- *Added Handoff Protocol with command object schema*
- *Added Staged Promotion pattern (Experiment → Validate → Production)*
- *Added Anti-Patterns checklist for learning systems*
