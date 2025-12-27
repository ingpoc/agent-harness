# Skills Maintenance Guide

Guidelines for creating and updating agent skills.

## Quick Principles

| Principle | Description |
|-----------|-------------|
| **SKILL.md is sacred** | Entry point - changes affect when agents trigger |
| **Progressive disclosure** | Metadata in SKILL.md, content in linked files |
| **Manual link updates** | Adding files requires updating SKILL.md and REFERENCE.md |
| **Always archive** | Never delete - move to `.archive/` |

---

## Skill Structure

```
.skills/
├── skill-name/
│   ├── SKILL.md          # Metadata + overview (~200 tokens)
│   ├── topic-1.md        # Actionable content (~1K-8K)
│   ├── topic-2.md
│   └── research.md       # Academic backing (optional)
```

---

## SKILL.md Guidelines

### YAML Frontmatter

```yaml
---
name: skill-name              # Lowercase, hyphens for multi-word
description: Use when [specific task]. Include [key patterns].
---
```

**Description Best Practices**:

| Do | Don't |
|-----|-------|
| "Use when designing trace storage..." | "Contains research on..." |
| "Implement quality gates..." | "Has documentation about..." |
| Focus on WHEN to use | Focus on WHAT it contains |

**Example**:
```yaml
---
name: context-graph
description: Use when designing trace storage, query mechanisms, or learning loops. Includes: progressive disclosure (98.7% savings), compaction strategy (1K-2K returns), Reflexion/OODA loops.
---
```

### SKILL.md Content

Keep SKILL.md lean (~200-500 tokens max):

| Section | Purpose | Length |
|---------|---------|--------|
| Overview | 2-3 sentence summary | ~50 tokens |
| When to Use | Bullet list of triggers | ~50 tokens |
| Additional Files | Table of linked content | ~100 tokens |
| Quick Reference | Key patterns table | ~100 tokens |

**Never put** full documentation in SKILL.md. It defeats the token-savings purpose.

---

## Content Placement Decisions

### SKILL.md vs Linked File

| Content Type | Goes In |
|--------------|---------|
| Metadata (name, description) | SKILL.md |
| Overview/summary | SKILL.md |
| File index | SKILL.md |
| Actionable patterns | Linked .md |
| Code examples | Linked .md |
| Academic citations | Linked .md (research.md) |
| Implementation details | Linked .md |

### New Skill vs Existing Skill

| Scenario | Action |
|----------|--------|
| Distinct new domain | Create new skill |
| Related to existing | Add to existing skill |
| Cross-cutting concern | Reference from both skills |

---

## Update Workflow

```
1. Identify what needs updating
   │
2. Decide: SKILL.md or linked .md?
   │
3. Make the edit
   │
4. Update SKILL.md file table (if adding/removing files)
   │
5. Update REFERENCE.md (if skill structure changed)
   │
6. Check for broken internal links
   │
7. Validate YAML frontmatter
```

---

## Adding a New File to a Skill

### Step 1: Create the file
```bash
# Example: Adding storage.md to context-graph
.skills/context-graph/storage.md
```

### Step 2: Update SKILL.md
```markdown
## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| patterns.md | Core patterns needed | ... |
| storage.md | Designing storage backend | sqlite-vec vs Postgres vs vector DBs |  # ← ADD THIS
| learning-loops.md | Implementing learning | ... |
```

### Step 3: Update REFERENCE.md
```markdown
### .skills/context-graph/

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | ... |
| storage.md | Designing storage backend | sqlite-vec vs Postgres vs vector DBs |  # ← ADD THIS
```

---

## Cross-Skill References

When one skill references another:

```markdown
## Related Skills

- `.skills/coordination/handoffs.md` - For handoff quality gates
- `.skills/context-graph/learning-loops.md` - For Spotify verification loops
```

---

## Validation Checklist

Before committing skill updates:

- [ ] SKILL.md has valid YAML frontmatter (name, description)
- [ ] Description focuses on WHEN to use, not WHAT contains
- [ ] All linked files listed in SKILL.md "Additional Files" table
- [ ] REFERENCE.md updated if adding/removing files
- [ ] No broken internal links (test: `grep -r "\.md\)" .skills/`)
- [ ] SKILL.md under ~500 tokens (metadata only)
- [ ] Linked files are actionable, not redundant

---

## Creating a New Skill

### 1. Create directory
```bash
mkdir -p .skills/new-skill
```

### 2. Create SKILL.md
```markdown
---
name: new-skill
description: Use when [specific task]. Include [key patterns].
---

# New Skill Name

Brief overview (2-3 sentences).

## When to Use This Skill

Load this skill when you need to:
- [Task 1]
- [Task 2]

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| topic-1.md | [When relevant] | [What it contains] |
```

### 3. Create linked files
```bash
.skills/new-skill/topic-1.md
```

### 4. Update REFERENCE.md
Add to `.skills/` section:
```markdown
### .skills/new-skill/

| File | When to Read | Content |
|------|--------------|---------|
| SKILL.md | Always (metadata) | Overview, when-to-use |
| topic-1.md | [When relevant] | [What it contains] |
```

### 5. Update main SKILL.md (if cross-referenced)

---

## Archiving (Never Delete)

When removing content:

```bash
# Always archive, never delete
mv .skills/old-skill .archive/
mv context-graph.md .archive/
```

---

## Token Budgets

| File | Target | Max |
|------|--------|-----|
| SKILL.md | ~200 tokens | 500 tokens |
| Linked .md | ~1K-5K tokens | 10K tokens |
| research.md | ~5K-10K tokens | 15K tokens |

**Progressive disclosure math**:
- Load all SKILL.md files: ~600 tokens (3 skills × 200)
- Load one specific topic: ~1K-5K tokens
- **Total**: ~1.6K-5.6K tokens (vs 100K+ without skills)

---

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| SKILL.md too long | Agent loads 5K+ tokens | Move content to linked .md |
| Description says "contains" | Skill triggers incorrectly | Change to "Use when..." |
| Forgotten REFERENCE.md update | Outdated navigation | Update when files change |
| Broken links | Agent can't find content | `grep -r "\.md\)"` to check |
| No YAML frontmatter | Skill doesn't trigger | Add `---` blocks |

---

## Testing Skills

### Verify Triggering
```bash
# Check metadata is valid
head -10 .skills/*/SKILL.md
```

### Check Links
```bash
# Find all markdown references
grep -r "\.md\)" .skills/ | grep -v "SKILL.md"
```

### Token Count
```bash
# Count tokens in SKILL.md (rough estimate)
wc -w .skills/*/SKILL.md
```

---

*Created: 2025-12-28*
*Purpose: Guide for maintaining .skills/ directory structure*
