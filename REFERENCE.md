# Agent Harness - Reference Guide

## Project Overview

**Project-agnostic multi-agent orchestration system** that learns from decisions, enforces rules, and tracks progress token-efficiently.

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Enforcement > Rules** | Hooks that block vs prompts that suggest |
| **Orchestrate > Prompt** | State machine vs user-driven |
| **Learn > Repeat** | Context graph vs re-discovering |
| **Token Efficient** | On-demand loading vs bloated context |
| **Project Agnostic** | Universal patterns vs specific implementations |

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: ORCHESTRATION                                     │
│  Auto-spawning agents based on state, no user prompting     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: ENFORCEMENT                                       │
│  Runtime guards that BLOCK invalid transitions              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: LEARNING                                          │
│  Context graph that feeds back into enforcement             │
└─────────────────────────────────────────────────────────────┘
```

---

## File Guide

### SUMMARY.md

**Purpose**: High-level problem statement and solution overview

**Contains**:
- Current problems with multi-agent systems
- Proposed three-layer solution
- Key design decisions
- Implementation priorities

**When to read**: First - understand what we're building and why

**Key sections**:
- Problem: Rules vs Enforcement
- Solution: Orchestration → Enforcement → Learning
- Roadmap: P0 → P3 implementation phases

---

### DESIGN.md

**Purpose**: Evolving technical architecture and implementation details

**Contains**:
- Three-layer architecture specification
- Enforcement hook implementations (with code)
- Simplified agent specifications
- Research questions (resolved and open)
- Implementation priority tracker

**When to read**: Second - understand how the system works

**Key sections**:
- Layer 1: Orchestration (state machine)
- Layer 2: Enforcement (hooks with exit code 2, JSON decisions)
- Layer 3: Learning (context graph feedback loop)

**Status**: Active design document - updated as research progresses

---

### context-graph.md

**Purpose**: Research notes from articles, papers, and production systems

**Contains**:
| Source | Key Insights |
|--------|--------------|
| Foundation Capital (Context Graphs) | Decision traces as searchable precedent |
| Anthropic Agent Skills | Progressive disclosure, code execution |
| Anthropic Code Execution MCP | 98.7% token savings via sandbox |
| Anthropic Long-Running Harness | Feature list, session continuity |
| Memory Systems Survey | Factual, experiential, working memory |
| Production systems (Cursor, Mem0, etc.) | 3-tier memory architecture |

**When to read**: For deep understanding of research backing the design

**Key sections**:
- Foundation concepts (rules vs traces)
- Anthropic engineering patterns
- Memory system taxonomy
- Storage options comparison
- Resolved research questions

**Status**: Research archive - updated when new sources found

---

### REFERENCE.md (this file)

**Purpose**: Guide to understanding each document's role

**When to read**: When you're confused about which file to read

---

## Skills Directory (.skills/)

**Purpose**: Modular skills with progressive disclosure - load only relevant context

**Token savings**: ~95% (load ~200 tokens metadata vs 10K+ full documents)

### .skills/context-graph/

Context engineering patterns for multi-agent systems.

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Overview, when-to-use, file index |
| patterns.md | Core patterns needed | Progressive disclosure, compaction, handoffs |
| storage.md | Designing storage backend | sqlite-vec vs Postgres vs vector DBs |
| learning-loops.md | Implementing learning | Reflexion, OODA, Spotify verification |
| research-sources.md | Academic backing needed | Citations, papers, articles |

### .skills/coordination/

Multi-agent coordination patterns from production systems.

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Overview, patterns catalog |
| supervisor-pattern.md | Designing centralized coordination | Databricks-style supervisor |
| handoffs.md | Implementing agent-to-agent control | Command objects, state transitions |
| anti-patterns.md | Avoiding common failures | 10 anti-patterns with solutions |
| production-systems.md | Learning from real deployments | Anthropic, Databricks, AWS, Azure |

### .skills/enforcement/

Hook patterns for runtime action validation.

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Overview, blocking mechanisms |
| blocking-hooks.md | Implementing hooks | PreToolUse, SubagentStop, exit code 2 |
| quality-gates.md | Designing verification loops | Spotify pattern, tested:true gates |
| hook-templates.md | Writing hook code | Python hook examples |

### .skills/token-efficient/

Token-efficient MCP tools for data processing and code execution.

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Overview, token savings, tool catalog |
| patterns.md | Deciding which tool to use | Decision tree, when to use each tool |
| examples.md | Need code examples | Concrete usage patterns with code |

**Tools available**:
- `execute_code` - Python/Bash/Node in sandbox (98%+ savings)
- `process_csv` - Filter/aggregate CSV files (99% savings)
- `process_logs` - Pattern match logs (95% savings)
- `search_tools` - Find tools by keyword (95% savings)
- `batch_process_csv` - Multiple CSV files (80% savings)

### .skills/browser-testing/

Web application testing using Claude Code's Chrome integration.

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Prerequisites, capabilities, tool catalog |
| patterns.md | Designing test scenarios | Test patterns, debugging strategies |
| examples.md | Need concrete examples | 15+ real-world test cases with prompts |

**Prerequisites**: Chrome extension 1.0.36+, Claude Code 2.0.73+, paid plan

**Key capabilities**:
- Live debugging - Read console errors and fix code
- Local testing - Test localhost URLs during development
- Console reading - Filter logs by pattern (ERROR, WARN)
- Form automation - Fill and submit forms
- Authenticated apps - Uses browser login (Gmail, Notion, Docs)
- GIF recording - Record interactions for demos
- Data extraction - Pull structured info from web pages

**How skills work**:
1. Agent loads SKILL.md metadata (name + description)
2. When relevant, agent reads specific .md file for details
3. Research-sources loaded only when academic backing needed

---

## Reading Order

### For Newcomers
```
1. THIS FILE (REFERENCE.md)    ← Understand the doc structure
2. SUMMARY.md                   ← What problem, what solution
3. DESIGN.md                    ← How it will work
4. .skills/{name}/SKILL.md      ← Patterns on demand (as needed)
```

### For Implementation
```
1. .skills/enforcement/SKILL.md          ← Hook patterns overview
2. .skills/enforcement/hook-templates.md ← Ready-to-use hooks
3. .skills/coordination/handoffs.md      ← Handoff protocols
4. DESIGN.md - Implementation Priority   ← What to build first
```

### For Research
```
1. .skills/context-graph/research-sources.md ← Academic backing
2. .skills/coordination/production-systems.md ← Real-world patterns
3. DESIGN.md - Research Questions             ← Open items
```

---

## Quick Reference

| I want to... | Read this |
|--------------|-----------|
| Understand the project | SUMMARY.md |
| See the architecture | DESIGN.md (Layer 1-3) |
| Implement a hook | .skills/enforcement/hook-templates.md |
| Test web applications | .skills/browser-testing/SKILL.md |
| Learn coordination patterns | .skills/coordination/SKILL.md |
| Design learning system | .skills/context-graph/learning-loops.md |
| Process data efficiently | .skills/token-efficient/SKILL.md |
| Avoid common pitfalls | .skills/coordination/anti-patterns.md |
| Understand research backing | .skills/context-graph/research-sources.md |
| Know what to build first | DESIGN.md (Implementation Priority) |

---

## System Characteristics

| Attribute | Description |
|-----------|-------------|
| **Scope** | Project-agnostic multi-agent orchestrator |
| **Goal** | Systems that build other systems/apps |
| **Token Strategy** | On-demand loading, progressive disclosure |
| **Learning** | Context graph from enforcement triggers |
| **Evolution** | Self-improving via pattern extraction |
| **Robustness** | Runtime enforcement, not just rules |

---

*Created: 2025-12-28*
*Status: Reference guide for agent-harness project*
