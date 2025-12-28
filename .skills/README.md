# Skills Library

Official Anthropic Skills pattern. Single orchestrator + skills architecture per DESIGN-v2.md.

## Skills Index

| Skill | State | Purpose |
|-------|-------|---------|
| **orchestrator/** | All | State machine, compression, session management |
| **initialization/** | INIT | Feature breakdown, project detection |
| **implementation/** | IMPLEMENT | Coding patterns, MCP usage, health checks |
| **testing/** | TEST | Unit, API, browser, database testing |
| **determinism/** | All | Code verification, prompt versioning |
| **enforcement/** | All | Blocking hooks, quality gates |
| **context-graph/** | COMPLETE | Learning loops, trace storage |

## State Machine

```
START → INIT → IMPLEMENT → TEST → COMPLETE
         ↑_________|         |
                   ↑_________|
```

## Official Skill Structure

```
skill-name/
├── SKILL.md              # Required: YAML frontmatter + instructions
├── scripts/              # Executable code (runs WITHOUT loading into context)
│   └── verify.sh
├── references/           # Documentation (loaded on-demand)
│   └── patterns.md
└── assets/               # Templates, images for output
    └── template.json
```

## Progressive Disclosure (3 Levels)

| Level | Loaded When | Size |
|-------|-------------|------|
| 1. Metadata (name + description) | Always in context | ~100 words |
| 2. SKILL.md body | When skill triggers | <5K words |
| 3. Bundled resources | On-demand by Claude | Unlimited |

**Key insight**: Description in frontmatter is the PRIMARY trigger mechanism. "When to use" info MUST be in description, not body.

## Scripts Pattern

Scripts execute WITHOUT loading into context = **0 tokens**.

```bash
# Good: Run script, get boolean result
scripts/health-check.sh && echo "PASS"

# Bad: Load script content to judge it
cat scripts/health-check.sh  # Wastes tokens
```

## Token Efficiency

| Pattern | Tokens |
|---------|--------|
| Load all SKILL.md metadata | ~700 (7 skills × 100) |
| Load one SKILL.md body | ~200-500 |
| Run script (no load) | 0 |
| Load reference | ~1K-5K (on-demand) |

**Total for typical session**: ~1K-2K tokens (vs 100K+ without skills)

---

# Maintenance Guide

## YAML Frontmatter (Required)

```yaml
---
name: skill-name
description: "Use when [specific trigger]. Load for [scenario]. [What it does]."
keywords: keyword1, keyword2, keyword3
---
```

**Description best practices**:
- Start with "Use when..."
- Include all trigger scenarios
- Body is only loaded AFTER triggering

## Adding Scripts

Scripts in `scripts/` directory:
- Are executable (Python, Bash, etc.)
- Run WITHOUT loading into context
- Return exit codes (0 = pass, 1 = fail)
- Used for deterministic verification

```bash
# Example: scripts/verify-feature.sh
#!/bin/bash
[ -f "src/feature.py" ] && exit 0 || exit 1
```

## Adding References

References in `references/` directory:
- Are documentation loaded on-demand
- Claude reads only when needed
- Contain detailed patterns and examples

## Archived

| Skill | Reason | Replacement |
|-------|--------|-------------|
| coordination/ | Multi-agent replaced | orchestrator/ + enforcement/ |
| browser-testing/ | Merged into testing/ | testing/references/browser-testing.md |

See `.archive/` for archived skills with notes.

---

*Updated: 2025-12-28*
*Pattern: Official Anthropic Skills (github.com/anthropics/skills)*
