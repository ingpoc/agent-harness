---
name: context-graph
description: Context engineering patterns for multi-agent systems. Use when designing trace storage, query mechanisms, or learning loops. Includes: progressive disclosure (98.7% token savings), compaction strategy (1K-2K returns), Reflexion/OODA loops, staged promotion patterns.
---

# Context Graph Skill

Context graphs are living records of decision traces across entities and time, making precedent searchable.

## When to Use This Skill

Load this skill when you need to:
- Design trace storage and retrieval systems
- Implement progressive disclosure for large context
- Apply compaction strategies to reduce token usage
- Build learning loops (Reflexion, OODA, Spotify verification)
- Design staged promotion patterns (experiment → validate → production)

## Overview

A context graph captures decision traces with:
- Inputs and policies evaluated
- Exceptions and approvals
- State changes and reasoning
- Entity-time linkage for searchable lineage

## Progressive Disclosure Pattern

Three detail levels for token efficiency:

| Level | Content | Token Cost |
|-------|---------|------------|
| Metadata | Timestamp, outcome, pattern_match | ~200 |
| Summary | What happened, key decisions (1K-2K) | ~1K-2K |
| Full Trace | All context, full reasoning | ~5K-10K |

**Result**: 98.7% token savings (150K → 2K tokens)

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| `patterns.md` | Core patterns for context engineering | Progressive disclosure, compaction, handoff protocols |
| `storage.md` | Designing storage backend | sqlite-vec vs Postgres vs vector DB comparison |
| `learning-loops.md` | Implementing learning from traces | Reflexion, OODA, Spotify verification loops |
| `research-sources.md` | Academic backing, citations | Foundation Capital, Anthropic articles, papers |

## Key Patterns

### Progressive Disclosure
```
Metadata (always) → Summary (on relevance) → Full Trace (on demand)
```

### Compaction Strategy
| Preserve | Discard |
|----------|---------|
| Architectural decisions | Redundant tool outputs |
| Unresolved bugs | Raw results (once used) |
| Recent 5 files | Historical context |

### Sub-Agent Distillation
Specialized agents return 1K-2K tokens, not full context.

## Quick Reference

| Concept | Implementation |
|---------|----------------|
| Store trace | ~50 tokens per decision event |
| Query traces | ~100 tokens for semantic search |
| Load top 3 summaries | ~600 tokens for context |
| **Total per decision** | ~750 tokens = 12x ROI vs rework |

## Sources

- Foundation Capital: Context Graphs as trillion-dollar layer
- Anthropic: Agent Skills, Code Execution MCP, Context Engineering
- NeurIPS 2023: Reflexion pattern for verbal reinforcement learning
- Spotify Engineering: Verification loops with veto power
