---
name: context-graph
description: "Use when storing decision traces, querying past precedents, or implementing learning loops. Load in COMPLETE state or when needing to learn from history. Covers progressive disclosure (98.7% savings), trace storage (sqlite-vec/Postgres), Reflexion/OODA learning loops, and compaction strategies."
keywords: traces, learning, memory, precedent, reflexion, compaction, progressive-disclosure
---

# Context Graph

Living records of decision traces for searchable precedent.

## Instructions

1. Store trace after decisions: `scripts/store-trace.sh`
2. Query similar precedents: `scripts/query-traces.sh`
3. Apply learning loop (Reflexion): `scripts/apply-learning.sh`
4. Compact old traces: `scripts/compact-traces.sh`

## Progressive Disclosure (3 Levels)

| Level | Content | Tokens |
|-------|---------|--------|
| Metadata | timestamp, outcome, pattern | ~200 |
| Summary | what happened, key decisions | ~1-2K |
| Full Trace | all context, full reasoning | ~5-10K |

**Result**: 98.7% savings (150K → 2K tokens)

## Quick Commands

```bash
# Store a decision trace
scripts/store-trace.sh "Chose FastAPI over Flask for async support"

# Find similar past decisions
scripts/query-traces.sh "framework selection"

# Get learning from past session
scripts/apply-learning.sh SESSION_ID
```

## References

| File | Load When |
|------|-----------|
| references/patterns.md | Designing trace schemas |
| references/storage.md | Choosing storage backend |
| references/learning-loops.md | Implementing Reflexion/OODA |
| references/research-sources.md | Academic citations needed |
