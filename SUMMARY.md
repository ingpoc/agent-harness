# Evolving Multi-Agent Harness System

## Vision

A self-orchestrating, self-learning multi-agent system where:
- Agents call the right tools at the right time automatically
- User doesn't have to force or prompt agents
- System evolves from corrections across sessions
- Rules are enforced, not just instructed

---

## Problem Statement

### The Surface Problem: No Learning

| Current State | Desired State |
|---------------|---------------|
| Corrections are ephemeral | Corrections persist as searchable traces |
| Same mistakes repeat across sessions | Agent queries past decisions before acting |
| CLAUDE.md rules always loaded (token bloat) | Rules loaded only when contextually relevant |

### The Deeper Problem: Rules vs Enforcement

| Current State | Root Cause |
|---------------|------------|
| 500+ lines of MUST/NEVER/CRITICAL in agents | Claude can ignore instructions |
| "Never mark tested:true if empty" | No runtime verification |
| "Use MCP for logs, not Read" | No detection of violation |
| User says "test this" to spawn tester | System doesn't auto-orchestrate |
| Features marked complete without testing | No verification gate |

**Core Insight**: Rules are instructions, not enforcements. The system needs runtime guards that BLOCK invalid actions, not just instruct against them.

### The Orchestration Problem

| Current State | Desired State |
|---------------|---------------|
| User prompts "continue implementing" | System auto-detects next action |
| User prompts "now test this" | Tester auto-spawns after implementation |
| User forces tool usage | Agent introspects: "Should I use MCP here?" |
| Manual workflow | State machine: init → code → test → next |

---

## Current Agent Structure

| Agent | Purpose | Status |
|-------|---------|--------|
| **initializer-agent** | Project setup, feature breakdown | Keep |
| **coding-agent** | Feature implementation | Keep |
| **tester-agent** | Validation, browser testing | Keep |
| **verifier-agent** | Health check | Remove (redundant - coding-agent does this) |

---

## Solution: Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: ORCHESTRATION                                     │
│  ├── Main agent (Opus) auto-selects next action            │
│  ├── State machine: init → code → test → next              │
│  ├── No user prompting needed                              │
│  └── Proactive spawning based on feature-list status       │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: ENFORCEMENT                                       │
│  ├── Hooks that BLOCK invalid state transitions            │
│  ├── tested:true requires verification gate                │
│  ├── Tool usage validated (MCP for logs, not Read)         │
│  └── Subagents cannot bypass guards                        │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: LEARNING (Context Graph)                          │
│  ├── Capture when enforcement triggers                     │
│  ├── Store corrections with embeddings                     │
│  ├── Query before decisions                                │
│  ├── Extract patterns from violations                      │
│  └── Feed back into agent prompts + create new guards      │
└─────────────────────────────────────────────────────────────┘
```

### Layer Integration

```
Enforcement triggers → Trace captured → Pattern extracted → New guard created
                                                                   ↓
                                           Agent queries traces → Acts with precedent
```

---

## What Each Layer Solves

### Layer 1: Orchestration

| Problem | Solution |
|---------|----------|
| User has to prompt next action | State machine auto-selects |
| Manual agent spawning | Proactive spawning from feature-list |
| Unclear what to do next | Status-based decision (pending → in_progress → test) |

### Layer 2: Enforcement

| Problem | Solution |
|---------|----------|
| tested:true with empty data | Hook blocks write if data empty |
| Wrong tool usage (Read vs MCP) | Pre-tool hook validates choice |
| Skipped workflow steps | State transition requires prior step complete |
| Subagent bypasses rules | Subagent literally cannot write certain fields |

### Layer 3: Learning

| Problem | Solution |
|---------|----------|
| Same mistakes repeat | Query traces before acting |
| CLAUDE.md rule bloat | Traces loaded only when relevant |
| No project-specific learning | Traces scoped to project |
| Rules don't evolve | Patterns extracted → new guards created |

---

## Success Criteria

| Criteria | Metric | Verification |
|----------|--------|--------------|
| **Auto-orchestration** | User prompts reduced by 80% | Count manual interventions |
| **Enforcement works** | Zero tested:true with empty data | Audit feature-list history |
| **Learning applied** | Same mistake not repeated | Track correction recurrence |
| **Token efficient** | <1000 tokens overhead per decision | Measure context delta |
| **System evolves** | New guards created from patterns | Count auto-generated guards |

---

## Key Design Decisions

### 1. Storage: Extend Token-Efficient MCP

Don't build new infrastructure. Add 3 tools to existing MCP server:

| Tool | Purpose |
|------|---------|
| `store_trace()` | Capture correction with embedding |
| `query_traces()` | Semantic search, return top-K |
| `extract_patterns()` | Aggregate traces into patterns |

Storage: sqlite-vec embedded in MCP server (single file, git-versioned)

### 2. Enforcement: Pre-Tool Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `verify-tested-write` | Before writing tested:true | Block if data empty |
| `validate-tool-choice` | Before Read on log files | Suggest MCP instead |
| `require-prior-step` | Before state transition | Block if prior incomplete |

### 3. Orchestration: State Machine in Main Agent

```
Session Start
     │
     ├─→ Read feature-list.json
     │
     ├─→ Any status="in_progress"? → Resume coding-agent
     │
     ├─→ Any status="completed" + tested=false? → Spawn tester-agent
     │
     ├─→ Any status="pending"? → Spawn coding-agent
     │
     └─→ All tested=true? → Session complete
```

---

## Open Research Questions

| Question | Why It Matters |
|----------|----------------|
| Can hooks BLOCK actions (not just log)? | Instructions don't guarantee compliance |
| Can tested:true be gated by verification? | Prevents premature completion |
| Can skills self-activate by context? | Right knowledge at right time |
| Can traces create new guards? | System evolves from mistakes |
| Can agent introspect tool choice? | Self-correction before errors |

---

## Implementation Priority

| Priority | Component | Effort | Impact |
|----------|-----------|--------|--------|
| **P0** | State machine in main agent | Low | Auto-orchestration |
| **P0** | tested:true verification gate | Medium | Prevent premature completion |
| **P1** | store_trace() + query_traces() in MCP | Medium | Learning foundation |
| **P1** | Pre-decision trace query | Low | Apply learning |
| **P2** | Auto-capture from corrections | Medium | Zero-friction capture |
| **P2** | Pattern extraction | Medium | Rule evolution |
| **P3** | Dynamic guard creation | High | Self-improving system |

---

## Files in This Project

| File | Purpose |
|------|---------|
| `SUMMARY.md` | This file - problem and solution overview |
| `DESIGN.md` | Detailed technical design |
| `context-graph.md` | Research notes and references |

---

## Key Sources

| Article | Key Insight |
|---------|-------------|
| [Long-Running Harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Feature list prevents premature completion |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Progressive disclosure, code execution |
| [Code Execution MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) | 98.7% token savings via sandbox |
| [Context Graphs](https://foundationcapital.com/context-graphs-ais-trillion-dollar-opportunity/) | Decision traces = system of record |

---

*Last Updated: 2025-12-27*
*Status: Brainstorming Complete - Ready for Design Refinement*
