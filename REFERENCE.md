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

## Reading Order

### For Newcomers
```
1. THIS FILE (REFERENCE.md)    ← Understand the doc structure
2. SUMMARY.md                   ← What problem, what solution
3. DESIGN.md                    ← How it will work
4. context-graph.md             ← Research backing (optional/deep)
```

### For Implementation
```
1. DESIGN.md - Layer 2 (Enforcement)    ← Hook implementations
2. DESIGN.md - Implementation Priority   ← What to build first
3. DESIGN.md - Simplified Agent Specs   ← New agent prompts
```

### For Research
```
1. context-graph.md - Section 6 (Research Questions)  ← What we learned
2. DESIGN.md - Research Questions                    ← Open items
```

---

## Quick Reference

| I want to... | Read this |
|--------------|-----------|
| Understand the project | SUMMARY.md |
| See the architecture | DESIGN.md (Layer 1-3) |
| Implement a hook | DESIGN.md (Layer 2: Enforcement) |
| Understand research decisions | context-graph.md |
| Know what to build first | DESIGN.md (Implementation Priority) |
| Check what's resolved | DESIGN.md or context-graph.md (Section 6) |

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
