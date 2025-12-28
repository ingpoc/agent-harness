---
name: initialization
description: "Use when starting a new session without feature-list.json, setting up project structure, or breaking down requirements into atomic features. Load in INIT state. Detects project type (Python/Node/Django/FastAPI), creates feature-list.json with priorities, initializes .claude/progress/ tracking."
keywords: init, setup, features, breakdown, project-detection, requirements
---

# Initialization

Project setup and feature breakdown for INIT state.

## Instructions

1. Detect project type: `scripts/detect-project.sh`
2. Analyze user requirements
3. Break down into atomic features (INVEST criteria)
4. Create feature-list.json: `scripts/create-feature-list.sh`
5. Initialize progress tracking: `scripts/init-progress.sh`

## Exit Criteria (Code Verified)

```bash
# All must pass
[ -f ".claude/progress/feature-list.json" ]
jq '.features | length > 0' .claude/progress/feature-list.json
jq '.features[0] | has("id", "description", "priority", "status")' .claude/progress/feature-list.json
```

## References

| File | Load When |
|------|-----------|
| references/feature-breakdown.md | Breaking down requirements |
| references/project-detection.md | Detecting project type |
| references/mvp-feature-breakdown.md | MVP-first tiered feature generation (10/30/200) |

## Assets

| File | Purpose |
|------|---------|
| assets/feature-list.template.json | Template for new feature lists |
