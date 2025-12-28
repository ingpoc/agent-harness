# Agent Harness System - Expert-Backed Design v2

## Design Philosophy

> **"Don't Build Agents, Build Skills"** — Barry Zhang & Mahesh Murag, Anthropic
>
> **"Share context, share full traces, not just messages"** — Cognition AI
>
> **"Code is deterministic, this workflow is consistent and repeatable"** — Anthropic Engineering

---

## Key Changes from v1

| v1 (Multi-Agent) | v2 (Single Orchestrator + Skills) | Why |
|------------------|-----------------------------------|-----|
| 4 agents (initializer, coding, tester, verifier) | 1 orchestrator + skills library | Context continuity, no conflicting decisions |
| 500+ lines per agent | ~100 lines orchestrator + skills on-demand | 80% token reduction |
| Subagent spawning loses context | Single context window preserved | Reliability |
| Rules in prompts | Deterministic hooks + code execution | Enforcement > Instructions |

---

## Four-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 0: DETERMINISM                                                       │
│  "Reproducible, auditable behavior"                                         │
│                                                                              │
│  • Versioned prompts (hash-validated)                                       │
│  • temperature=0 for critical paths                                         │
│  • Code execution for verification (not LLM judgment)                       │
│  • Structured outputs with schema validation                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1: ORCHESTRATION                                                     │
│  "Single orchestrator, skills for depth"                                    │
│                                                                              │
│  • ONE agent maintains full context (no subagent spawning)                  │
│  • State machine with valid transitions only                                │
│  • Skills invoked on-demand (progressive disclosure)                        │
│  • Compression model for long sessions                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 2: ENFORCEMENT                                                       │
│  "Hooks that BLOCK, code that VERIFIES"                                     │
│                                                                              │
│  • Exit code 2 blocks invalid actions                                       │
│  • Scripts verify outcomes (not LLM judgment)                               │
│  • External enforcement, not internal rules                                 │
│  • Zero tokens in context (hooks are external)                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3: LEARNING                                                          │
│  "Skills as externalized memory"                                            │
│                                                                              │
│  • Traces captured on enforcement triggers                                  │
│  • Patterns extracted → new skills or guards                                │
│  • Skills = reusable procedural knowledge                                   │
│  • Query before decisions (semantic search)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layer 0: Determinism

### Sources of Non-Determinism (to eliminate)

| Source | Problem | Solution |
|--------|---------|----------|
| LLM judgment for verification | "I think tests passed" | Script returns boolean |
| Dynamic datetime in prompts | Different outputs per run | Fixed context or omit |
| Non-versioned prompts | Drift across sessions | Hash-validated prompts |
| Parallel agents | Conflicting decisions | Single orchestrator |
| Temperature > 0 | Random variations | temperature=0 for critical paths |

### Deterministic Verification Pattern

```python
# BAD: LLM judgment
"Check if the tests passed and update the feature status"

# GOOD: Code execution
def verify_tests():
    result = subprocess.run(["pytest", "--tb=short"], capture_output=True)
    return {
        "passed": result.returncode == 0,
        "output": result.stdout.decode()[-500:]  # Last 500 chars only
    }
```

### Prompt Versioning

```python
# .claude/prompts/orchestrator.md
# Version: 1.2.0
# SHA256: a3f2b8c9...
# Last validated: 2025-12-28

# On load, verify hash matches expected
```

---

## Layer 1: Orchestration

### Single Orchestrator Pattern

**Why single over multi-agent** (from [Cognition](https://cognition.ai/blog/dont-build-multi-agents)):

> "When subagents work simultaneously without full context, they make incompatible choices."

| Multi-Agent Problem | Single Orchestrator Solution |
|---------------------|------------------------------|
| Context lost on handoff | Context preserved throughout |
| Conflicting decisions | Single decision authority |
| 15x token overhead | Skills loaded on-demand |
| Debugging nightmare | Single trace to follow |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│           MAIN AGENT (Opus, single context window)                          │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ STATE MACHINE                                                          │  │
│  │                                                                        │  │
│  │  [START] → [INIT] → [IMPLEMENT] → [TEST] → [COMPLETE]                 │  │
│  │              ↓           ↓           ↓                                 │  │
│  │           init/       impl/       test/      ← Skills (on-demand)     │  │
│  │           skill       skill       skill                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  Context: Full session history, compressed as needed                        │
│  Tools: Read, Write, Edit, Bash, MCP (with defer_loading)                  │
│  Skills: Loaded via progressive disclosure                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### State Machine (Enforced)

| State | Entry Condition | Exit Condition | Skill Loaded |
|-------|-----------------|----------------|--------------|
| **START** | Session begins | feature-list.json checked | - |
| **INIT** | No feature-list.json | Feature list created | `initialization/` |
| **IMPLEMENT** | Pending feature exists | Implementation complete | `implementation/` |
| **TEST** | Implementation complete | Tests pass (verified by code) | `testing/` |
| **COMPLETE** | All features tested | - | - |

**Invalid transitions blocked by hooks**:
- INIT → COMPLETE (skip implementation)
- IMPLEMENT → COMPLETE (skip testing)
- TEST → COMPLETE (without passing tests)

### Orchestrator Prompt (~100 lines)

```markdown
# Main Orchestrator

You are a single orchestrator maintaining full context throughout the session.
You do NOT spawn subagents. You invoke skills for domain-specific procedures.

## State Machine
1. Check current state from `.claude/progress/state.json`
2. Load appropriate skill for current state
3. Execute procedures from skill
4. Transition only when exit conditions met (verified by code)

## States
- INIT: Load `skills/initialization/SKILL.md`, create feature-list.json
- IMPLEMENT: Load `skills/implementation/SKILL.md`, implement next pending feature
- TEST: Load `skills/testing/SKILL.md`, verify implementation
- COMPLETE: Summarize session, update progress

## Rules
- NEVER skip states (enforcement hooks will block)
- NEVER judge outcomes yourself (use code verification)
- ALWAYS load skill before executing domain procedures
- ALWAYS compress context when approaching limits

## Compression Trigger
When context > 80% capacity:
1. Summarize: key decisions, unresolved issues, current state
2. Preserve: last 5 files touched, current feature context
3. Discard: raw tool outputs, historical context
```

### Context Compression (from [Cognition](https://cognition.ai/blog/dont-build-multi-agents))

When context threatens overflow:

```python
compression_prompt = """
Distill this conversation into key details:
1. Decisions made (with rationale)
2. Current state and next action
3. Unresolved issues
4. Files recently modified

Discard: raw outputs, redundant context, historical details
Target: 2000 tokens
"""
```

---

## Layer 2: Enforcement

### Code Execution > LLM Judgment

| Task | LLM Judgment (Bad) | Code Execution (Good) |
|------|-------------------|----------------------|
| Tests passed? | "The tests appear to pass" | `pytest --tb=short; echo $?` |
| Feature complete? | "I believe this is done" | Check required files exist |
| Valid JSON? | "This looks like valid JSON" | `python -c "import json; json.load(f)"` |
| Server running? | "The server should be up" | `curl -s localhost:8000/health` |

### Enforcement Hooks

| Hook | Event | Verification | Blocks If |
|------|-------|--------------|-----------|
| `verify-tests.py` | PreToolUse (Write feature-list) | Run pytest, check exit code | Tests fail |
| `verify-files-exist.py` | PreToolUse (mark completed) | Check implementation files exist | Missing files |
| `verify-no-skip.py` | PreToolUse (state transition) | Check valid transition | Invalid transition |
| `verify-health.py` | PreToolUse (mark tested) | curl health endpoint | Server not running |

### Exit Code 2 Pattern (Blocking)

```python
#!/usr/bin/env python3
# .claude/hooks/verify-tests.py
import subprocess
import sys
import json

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
content = tool_input.get("content", "")

# Only check when marking tested:true
if '"tested": true' not in content:
    sys.exit(0)

# Run actual tests
result = subprocess.run(
    ["pytest", "--tb=short", "-q"],
    capture_output=True,
    cwd="/path/to/project"
)

if result.returncode != 0:
    print("BLOCKED: Tests failed. Fix before marking tested:true", file=sys.stderr)
    print(result.stdout.decode()[-500:], file=sys.stderr)
    sys.exit(2)  # Blocking exit code

sys.exit(0)
```

### State Transition Enforcement

```python
#!/usr/bin/env python3
# .claude/hooks/verify-state-transition.py
import json
import sys

VALID_TRANSITIONS = {
    "START": ["INIT", "IMPLEMENT"],
    "INIT": ["IMPLEMENT"],
    "IMPLEMENT": ["TEST"],
    "TEST": ["IMPLEMENT", "COMPLETE"],  # Can go back to fix
    "COMPLETE": []
}

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
content = tool_input.get("content", "")

if "state.json" not in input_data.get("tool_input", {}).get("file_path", ""):
    sys.exit(0)

# Parse current and new state
try:
    new_state = json.loads(content)
    with open(".claude/progress/state.json") as f:
        current_state = json.load(f)
except:
    sys.exit(0)

current = current_state.get("state", "START")
new = new_state.get("state", current)

if new not in VALID_TRANSITIONS.get(current, []):
    print(f"BLOCKED: Invalid transition {current} → {new}", file=sys.stderr)
    print(f"Valid transitions from {current}: {VALID_TRANSITIONS[current]}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

---

## Skills Library

### Structure (Progressive Disclosure)

```
.skills/
├── README.md                    # How to create/maintain skills
│
├── initialization/              # INIT state
│   ├── SKILL.md                 # ~200 tokens, loaded when state=INIT
│   ├── feature-breakdown.md     # Loaded on-demand
│   ├── project-detection.md     # Loaded on-demand
│   └── templates/               # Reference files
│
├── implementation/              # IMPLEMENT state
│   ├── SKILL.md                 # ~200 tokens
│   ├── coding-patterns.md       # On-demand
│   ├── mcp-usage.md             # On-demand
│   └── health-checks.md         # On-demand
│
├── testing/                     # TEST state
│   ├── SKILL.md                 # ~200 tokens
│   ├── browser-testing.md       # On-demand
│   ├── api-testing.md           # On-demand
│   └── verification-scripts/    # Deterministic checks
│
└── enforcement/                 # Hook templates
    ├── SKILL.md                 # ~200 tokens
    ├── hook-templates.md        # Ready-to-use hooks
    └── scripts/                 # Verification scripts
```

### SKILL.md Template (~200 tokens)

```markdown
# [Skill Name]

## Purpose
[One sentence description]

## When to Load
- State: [Which state triggers this skill]
- Condition: [Additional conditions]

## Core Procedures
1. [Step 1 - brief]
2. [Step 2 - brief]
3. [Step 3 - brief]

## Key Files
- `patterns.md` - Detailed patterns (load if needed)
- `examples.md` - Code examples (load if needed)
- `scripts/` - Executable verification scripts

## Exit Criteria
- [ ] [What must be true to exit this state]
- [ ] [Verified by code, not judgment]
```

### Token Efficiency

| Approach | Tokens Loaded | When |
|----------|---------------|------|
| All agent prompts (v1) | ~5000 | Always |
| SKILL.md only | ~200 | On state entry |
| Full skill content | ~2000 | On-demand |
| **Savings** | **96%** | |

---

## Token Efficiency Patterns

### 1. Progressive Disclosure (Skills)

```
Session start: Load orchestrator (~100 tokens)
State=INIT: Load initialization/SKILL.md (~200 tokens)
Need details: Load feature-breakdown.md (~500 tokens)

Total: ~800 tokens vs ~5000 tokens (84% savings)
```

### 2. Tool Search Tool (defer_loading)

From [Anthropic Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use):

```json
{
  "tools": [
    {"name": "Read", "defer_loading": false},
    {"name": "Write", "defer_loading": false},
    {"name": "browser_screenshot", "defer_loading": true},
    {"name": "browser_click", "defer_loading": true},
    {"name": "mcp_process_csv", "defer_loading": true}
  ]
}
```

**Effect**: 85% reduction in tool definition tokens (77K → 8.7K)

### 3. Code Execution for Data Processing

```python
# BAD: Load 10K rows into context
data = read_file("large_log.txt")  # 50K tokens
analyze(data)

# GOOD: Process in sandbox, return summary
result = execute_code("""
import pandas as pd
df = pd.read_csv('large_log.txt')
print(f"Rows: {len(df)}, Errors: {len(df[df.level=='ERROR'])}")
print(df[df.level=='ERROR'].head(5).to_string())
""")
# Returns: ~200 tokens
```

### 4. Compression Triggers

| Condition | Action |
|-----------|--------|
| Context > 80% | Compress non-essential history |
| Tool output > 5K tokens | Summarize before adding to context |
| Skill no longer needed | Unload from active context |

---

## Layer 3: Learning

### Skills as Externalized Memory

From [Anthropic Skills Talk](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills):

> "Skills ground memory as a concrete, reusable artifact. What Claude writes today is usable by future versions."

| Traditional Memory | Skills Approach |
|-------------------|-----------------|
| Vector store of traces | Structured skill files |
| Query at runtime | Progressive disclosure |
| Implicit knowledge | Explicit procedures |
| Model-dependent | Portable, versionable |

### Learning Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    LEARNING FEEDBACK LOOP                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Enforcement hook blocks action                          │
│                    ↓                                         │
│  2. Log violation:                                           │
│     { state, action, reason, context }                      │
│                    ↓                                         │
│  3. Pattern detection:                                       │
│     "Tried to skip TEST state 3 times"                      │
│                    ↓                                         │
│  4. Update skill or create guard:                           │
│     - Add warning to SKILL.md                               │
│     - Create new enforcement hook                           │
│     - Update state machine rules                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Trace → Skill Pipeline

```python
# When pattern detected (e.g., same error 3+ times)
def create_skill_update(traces):
    pattern = extract_pattern(traces)

    if pattern.type == "missing_step":
        # Add to relevant skill
        update_skill(
            f"skills/{pattern.state}/SKILL.md",
            add_warning=pattern.description
        )

    elif pattern.type == "invalid_action":
        # Create enforcement hook
        create_hook(
            f"hooks/block-{pattern.action}.py",
            template="block_action",
            params=pattern
        )
```

---

## Implementation Priority

| Priority | Component | Effort | Impact | Status |
|----------|-----------|--------|--------|--------|
| **P0** | Single orchestrator prompt | Low | Foundation | Ready |
| **P0** | State machine enforcement hooks | Low | Determinism | Ready |
| **P0** | Skills library structure | Low | Token efficiency | ✅ Done |
| **P1** | Verification scripts (pytest, curl) | Medium | Code > Judgment | |
| **P1** | Tool defer_loading config | Low | 85% tool token savings | |
| **P1** | Compression trigger | Medium | Long session support | |
| **P2** | Trace logging | Medium | Learning foundation | |
| **P2** | Pattern detection | Medium | Auto-improvement | |
| **P3** | Auto-skill generation | High | Self-evolving system | |

---

## Success Metrics

| Metric | v1 (Multi-Agent) | v2 Target | How to Measure |
|--------|------------------|-----------|----------------|
| Context continuity | Lost on handoff | 100% preserved | Single trace |
| Token per session | ~50K | ~10K | Usage logs |
| Deterministic outcomes | ~60% | ~95% | Code verification |
| Invalid transitions | Frequent | Zero | Hook block count |
| Debugging time | Hours | Minutes | Single trace to follow |

---

## Migration Path

### Phase 1: Structure (Week 1)
1. Create orchestrator prompt (~100 lines)
2. Verify skills library structure
3. Implement state.json tracking

### Phase 2: Enforcement (Week 2)
1. Deploy state transition hook
2. Deploy verification scripts
3. Remove rules from prompts (hooks handle them)

### Phase 3: Optimization (Week 3)
1. Add defer_loading to tool config
2. Implement compression trigger
3. Add trace logging

### Phase 4: Learning (Week 4+)
1. Pattern detection from traces
2. Auto-update skills from patterns
3. Evaluate auto-hook generation

---

## Key Principles (Updated)

1. **Single Context > Parallel Agents**: One orchestrator maintains full context
2. **Skills > Agent Prompts**: Domain knowledge in skills, not agent rules
3. **Code > Judgment**: Verification by scripts, not LLM opinion
4. **Hooks > Rules**: External enforcement, not internal instructions
5. **Progressive > Eager**: Load on-demand, compress when needed
6. **Determinism > Flexibility**: Reproducible behavior via code paths

---

## Research Sources

| Source | Key Pattern |
|--------|-------------|
| [Cognition: Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) | Single-threaded, context sharing |
| [Anthropic: Skills Talk](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Skills > Agents, progressive disclosure |
| [Anthropic: Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use) | defer_loading, 85% token savings |
| [Anthropic: Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Compression, sub-agent distillation |
| [Google: Multi-Agent Patterns](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/) | When to use multi-agent (not here) |
| [Kubiya: Deterministic AI](https://www.kubiya.ai/blog/deterministic-ai-architecture) | Code paths for reproducibility |
| [StateFlow](https://arxiv.org/html/2403.11322v1) | State machine for LLM workflows |

---

*Version: 2.0*
*Updated: 2025-12-28*
*Status: Expert-backed design, ready for implementation*

*Changelog from v1:*
- Collapsed 4 agents → 1 orchestrator + skills
- Added Layer 0: Determinism
- Replaced LLM judgment with code verification
- Added Tool Search Tool pattern (defer_loading)
- Added compression trigger for long sessions
- Updated research sources with expert consensus
