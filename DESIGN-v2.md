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

## Documentation Hierarchy

Clear separation ensures reliable agent behavior without redundancy.

| File | Scope | Purpose | Maintained By |
|------|-------|---------|---------------|
| `~/.claude/prompts/orchestrator.md` | Global | Agent identity, state machine, core principles | You (once) |
| `~/.claude/CLAUDE.md` | Global | Your habits (token patterns, delegation, workflow) | You (once) |
| `CLAUDE.md` | Project | Project architecture, file structure, conventions | Per project |
| `.claude/CLAUDE.md` | Project | Quick reference (commands, state mapping only) | `init-project.sh` |

**Key principle**: Architectural principles live in `orchestrator.md` (identity), not in project `CLAUDE.md` (reality). The `.claude/CLAUDE.md` is a minimal quick-reference that points to `orchestrator.md` for full details.

**Layered inheritance**:
```
orchestrator.md (WHO I AM)
    ↓
~/.claude/CLAUDE.md (MY HABITS)
    ↓
CLAUDE.md (THIS PROJECT'S STRUCTURE)
    ↓
.claude/CLAUDE.md (QUICK REFERENCE)
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
│  │ SESSION ENTRY PROTOCOL (run first)                                     │  │
│  │  Phase 1: Safety (pwd, git log, health check)                         │  │
│  │  Phase 2: State (init state.json, check features)                     │  │
│  │  Phase 3: Context (load summary, recent files, skill)                 │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                              ↓                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ STATE MACHINE                                                          │  │
│  │                                                                        │  │
│  │  [START] ──┬──→ [INIT] → [IMPLEMENT] → [TEST] → [COMPLETE]            │  │
│  │            │        ↓          ↓          ↓                            │  │
│  │            │     init/      impl/      test/   ← Skills (on-demand)   │  │
│  │            │                                                           │  │
│  │            └──→ [FIX_BROKEN] ← Health check failed                    │  │
│  │                      ↓                                                 │  │
│  │                 enforcement/  ← Must fix before features              │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  Context: Full session history, compressed as needed                        │
│  Tools: Read, Write, Edit, Bash, MCP (with defer_loading)                  │
│  Skills: Loaded via progressive disclosure                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Session Entry Protocol

**Source**: Merged from Skills + [Anthropic Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

Run `scripts/session-entry.sh` at start of every session:

| Phase | Steps | Purpose |
|-------|-------|---------|
| **1. Safety** | pwd, git log -5, health check | Verify environment, detect broken state |
| **2. State** | Init state.json, check features | Determine current/next state |
| **3. Context** | Load summary, recent files | Restore continuity from previous session |

```bash
# Run entry protocol
./scripts/session-entry.sh

# Output: JSON with health_status, feature_status, next_state
```

**Key insight from Anthropic**: *"Verify app hasn't been left in broken state"* - If health check fails, enter FIX_BROKEN state before any feature work.

### State Machine (Enforced)

| State | Entry Condition | Exit Condition | Skill Loaded |
|-------|-----------------|----------------|--------------|
| **START** | Session begins | Entry protocol complete | - |
| **FIX_BROKEN** | Health check fails | Health check passes | `enforcement/` |
| **INIT** | No feature-list.json | Feature list created | `initialization/` |
| **IMPLEMENT** | Pending feature exists | Implementation complete | `implementation/` |
| **TEST** | Implementation complete | Tests pass (verified by code) | `testing/` |
| **COMPLETE** | All features tested | - | - |

**Invalid transitions blocked by hooks**:
- START → IMPLEMENT (skip init when no features)
- FIX_BROKEN → IMPLEMENT (skip fixing broken app)
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

**Progressive Compression** (from autonomous-coding analysis):

When context exceeds thresholds:
- **50%**: Save checkpoint (state + summary)
- **70%**: Pre-compression (remove raw outputs)
- **80%**: Level 1 compression (remove tool outputs)
- **85%**: Level 2 compression (summarize history)
- **90%**: Level 3 compression (full compression to 2K tokens)
- **95%**: Emergency compression (current state only)

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

### Session Resumption (Hybrid Pattern)

**From autonomous-coding quickstart analysis**:

Resume sessions efficiently by combining fresh context with checkpoint summaries:

| Context Usage | Strategy | Token Cost | Continuity |
|---------------|----------|------------|------------|
| < 60% | Continue | 0 | 100% |
| 60-79% | Compress + Continue | ~2K | 95% |
| ≥ 80% | Fresh + Summary | ~3K | 80% |

**Pattern**:
1. Session 1: Full context, execute until checkpoint
2. Session 2+: Load checkpoint summary + recent files (last 5)
3. Continue from where previous session left off

**Benefits**:
- 50% token savings vs fresh context per session
- 80% context continuity vs 100% loss
- Auto-continue between sessions (3s delay)

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

**Global Hooks** (7 hooks - project-agnostic, in `~/.claude/hooks/`):

| Hook | Event | Verification | Blocks If |
|------|-------|--------------|-----------|
| `verify-state-transition.py` | PreToolUse (Write state.json) | Valid transitions only | Invalid state change |
| `require-commit-before-tested.py` | PreToolUse (Write feature-list) | `git status --porcelain` | Uncommitted changes |
| `require-outcome-update.py` | PreToolUse (Write feature-list) | Trace outcomes updated | Outcome still pending |

**Project Hooks** (5 hooks - project-specific, read from `.claude/config/project.json`):

| Hook | Event | Verification | Blocks If |
|------|-------|--------------|-----------|
| `verify-tests.py` | PreToolUse (Write feature-list) | Run test_command | Tests fail |
| `verify-files-exist.py` | PreToolUse (mark completed) | Implementation files exist | Files missing |
| `verify-health.py` | PreToolUse (mark tested) | Health check command | Server not running |
| `require-dependencies.py` | PreToolUse (Write to src/) | Env vars, services present | Deps missing |
| `session-entry.sh` | SessionStart | 3-phase protocol | N/A (info only) |

**Utility Scripts** (2 scripts):

| Script | Purpose | When |
|--------|---------|------|
| `feature-commit.sh` | Commit with `[feat-id]` format | After implementation |
| `session-end.sh` | Checkpoint commit | Session end |

**Auto-Linking** (1 hook):

| Hook | Event | Purpose | Blocks? |
|------|-------|---------|--------|
| `link-feature-to-trace.py` | Feature created | Auto-link to trace | No |

**Reminders** (1 hook):

| Hook | Event | Purpose | Blocks? |
|------|-------|---------|--------|
| `remind-decision-trace.sh` | Implementation | Log decision trace | No (reminder) |

**Total: 12 hooks + 2 scripts**

### Git Integration

From Anthropic Effective Harnesses: *"Git commit history with descriptive messages"*

| Script | Purpose | When |
|--------|---------|------|
| `feature-commit.sh <id>` | Commit with `[feat-id] message` format | After implementation, before marking tested |
| `session-commit.sh` | Checkpoint commit with state info | At session end |

**Flow:**
```
Implement → Test → feature-commit.sh → Mark tested
                        ↑
              Hook blocks if skipped
```

### External Dependencies

From Anthropic Effective Harnesses: *"init.sh script for development server startup"*

| Script | Purpose | When |
|--------|---------|------|
| `check-dependencies.sh` | Validate env vars, ports, services | Session entry |
| `create-init-script.sh [type]` | Generate init.sh for project type | Project initialization |
| `require-dependencies.py` | Block feature work if deps missing | PreToolUse (Write to src/) |

**Configuration** (`.claude/config/project.json`):
```json
{
  "project_type": "fastapi",
  "dev_server_port": 8000,
  "health_check": "curl -sf http://localhost:8000/health",
  "test_command": "pytest",
  "required_env": ["DATABASE_URL", "API_KEY"],
  "required_services": ["redis://localhost:6379"]
}
```

### Hook Setup Skills

Two skills manage hook installation:

| Skill | Location | Purpose | Run Frequency |
|------|----------|---------|--------------|
| `global-hook-setup` | `.skills/global-hook-setup/` | Install 7 global hooks | Once per machine |
| `project-hook-setup` | `.skills/project-hook-setup/` | Install 5 project hooks | Once per project |

**Setup Workflow:**
```
INIT state → initializer skill
                ↓
    Check: ~/.claude/hooks/ exists?
                ↓ NO
    Load global-hook-setup skill
                ↓
    Check: .claude/hooks/ exists?
                ↓ NO
    Load project-hook-setup skill
```

**Skills Structure:**
```
.skills/
├── global-hook-setup/
│   ├── SKILL.md
│   ├── scripts/ (setup, verify, install)
│   └── templates/ (7 hook templates)
└── project-hook-setup/
    ├── SKILL.md
    ├── scripts/ (setup, config, verify, install)
    ├── templates/ (5 hook templates)
    └── assets/ (project config template)
```

**Flow:**
```
Session Entry → check-dependencies.sh → PASS → Continue
                        ↓
                      FAIL → Block feature work until fixed
```

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
│       ├── CLAUDE.md            # Quick reference template (minimal)
│       └── feature-list.json    # Feature list template
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

### 5. Session Resumption (Efficiency Pattern)

**Hybrid approach from autonomous-coding quickstart**:

| Context Usage | Strategy | Token Savings |
|---------------|----------|---------------|
| < 60% | Continue existing context | 0% (already optimal) |
| 60-79% | Compress + continue | ~30% |
| ≥ 80% | Fresh context + summary | ~50% |

### 6. MVP-First Feature Breakdown (Efficiency Pattern)

**From autonomous-coding analysis**:

| Tier | Features | Generate Time | Implement Time |
|------|----------|---------------|----------------|
| MVP | 10 | ~2 min | 2-4 hours |
| Expansion | 30 | ~5 min | 8-12 hours |
| Polish | 200 | ~20 min | 40+ hours |

**Benefits**: 90% time savings if pivot needed after MVP

### 7. Async Parallel Operations (Efficiency Pattern)

**For I/O-bound tasks**:

| Pattern | Sequential | Parallel | Speedup |
|---------|-----------|----------|--------|
| Tests + Linter + Git | 46s | 30s | 1.5x |
| File operations (10 files) | 10s | 2s | 5x |
| API calls (5 calls) | 20s | 4s | 5x |

### 8. Sandbox Fast-Path (Efficiency Pattern)

**Hybrid security: allowlist + sandbox-runtime**:

| Command Type | Approach | Overhead |
|--------------|----------|----------|
| Trusted (ls, cat, grep) | Direct execution | ~1ms |
| Unknown/dangerous | sandbox-runtime (srt) | ~100ms |

**Benefits**: 2-3x speedup for common commands while maintaining security

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
| **P0** | Single orchestrator prompt | Low | Foundation | ✅ Done |
| **P0** | State machine enforcement hooks | Low | Determinism | ✅ Done |
| **P0** | Skills library structure | Low | Token efficiency | ✅ Done |
| **P0** | Progressive compression checkpoints | Low | 30% token savings | ✅ Added |
| **P0** | MVP-first feature breakdown | Low | 90% time savings | ✅ Added |
| **P1** | Session resumption pattern | Medium | 50% token savings | ✅ Added |
| **P1** | Async parallel operations | Medium | 30-50% time savings | ✅ Added |
| **P1** | Sandbox fast-path | Low | 2-3x speedup | ✅ Added |
| **P1** | Verification scripts (12 hooks + 2 scripts) | Medium | Code > Judgment | ✅ Done |
| **P1** | Tool defer_loading config | - | 85% tool token savings | ⏳ API feature (see [#12836](https://github.com/anthropics/claude-code/issues/12836)) |
| **P2** | Trace logging | Medium | Learning foundation | ✅ Done (context-graph MCP) |
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
| [Anthropic: autonomous-coding quickstart](https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding) | Two-agent pattern, feature_list.json, MVP-first approach, session resumption, progressive compression |
| [Anthropic: Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Session entry protocol, health checks, broken state handling |

---

*Version: 2.2*
*Updated: 2025-12-30*
*Status: Hooks implemented, ready for use*

*Changelog from v1:*

- Collapsed 4 agents → 1 orchestrator + skills
- Added Layer 0: Determinism
- Replaced LLM judgment with code verification
- Added Tool Search Tool pattern (defer_loading)
- Added compression trigger for long sessions
- Updated research sources with expert consensus

*2025-12-28 - Efficiency Patterns (from autonomous-coding analysis):*

- Progressive compression checkpoints (50/70/80/85/90/95%)
- Session resumption (hybrid fresh context + summary)
- MVP-first feature breakdown (10/30/200 tiered features)
- Async parallel operations (30-50% speedup for I/O tasks)
- Sandbox fast-path (2-3x speedup for common commands)

*2025-12-28 - Session Entry Protocol (from Effective Harnesses article):*

- Added 3-phase session entry: Safety → State → Context
- Added FIX_BROKEN state for broken app handling
- Added project.json for project-specific configuration
- Added block-if-broken hook to prevent feature work on broken apps
- Merged Anthropic safety validation with existing state management

*2025-12-28 - Git Integration (from Effective Harnesses article):*

- Added feature-commit.sh for auto-commit with feature ID
- Added session-commit.sh for checkpoint commits
- Added require-commit-before-tested.py enforcement hook
- Commit required before marking feature as tested

*2025-12-28 - External Dependencies (from Effective Harnesses article):*

- Added check-dependencies.sh for env vars, ports, services validation
- Added create-init-script.sh for auto-generating init.sh by project type
- Added require-dependencies.py enforcement hook (blocks src/ writes if deps missing)
- Integrated dependency check into session entry protocol
*2025-12-30 - Hooks Implementation (DESIGN-v2 Layer 2 Enforcement):*

- Implemented 12 enforcement hooks (7 global + 5 project)
- Created global-hook-setup skill (one-time machine setup)
- Created project-hook-setup skill (per-project setup)
- Global hooks: state transitions, git hygiene, outcome tracking, auto-linking, reminders
- Project hooks: tests, health, dependencies, session entry, file verification
- Utility scripts: feature-commit.sh, session-end.sh
- Hooks read from .claude/config/project.json for project-specific settings
- Integrated hook setup into initializer skill workflow
- All hooks follow Claude Code best practices (exit code 2 for blocking)

*2025-12-30 - Documentation Separation (proper separation of concerns):*

- Added Documentation Hierarchy section explaining file purposes
- Clarified: orchestrator.md (identity) vs CLAUDE.md (project) vs .claude/CLAUDE.md (quick reference)
- Removed redundant architectural principles from project CLAUDE.md
- Simplified .claude/CLAUDE.md to minimal quick reference (commands, state mapping)
- Updated init-project.sh to generate streamlined .claude/CLAUDE.md
- Key principle: Architectural principles live in orchestrator.md, not duplicated in project docs
