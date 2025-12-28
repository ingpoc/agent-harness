---
name: initialization
description: "Use when starting a new session without feature-list.json, setting up project structure, or breaking down requirements into atomic features. Load in INIT state. Detects project type (Python/Node/Django/FastAPI), creates feature-list.json with priorities, initializes .claude/progress/ tracking."
keywords: init, setup, features, breakdown, project-detection, requirements
---

# Initialization

Project setup and feature breakdown for INIT state.

## Instructions

1. **Check MCP servers**: `check-dependencies.sh` runs mcp-setup verification first
2. Detect project type: `scripts/detect-project.sh`
3. Create init script: `scripts/create-init-script.sh`
4. Check dependencies: `scripts/check-dependencies.sh`
5. Analyze user requirements
6. Break down into atomic features (INVEST criteria)
7. Create feature-list.json: `scripts/create-feature-list.sh`
8. Initialize progress tracking: `scripts/init-progress.sh`

## Exit Criteria (Code Verified)

```bash
# All must pass
[ -f ".claude/progress/feature-list.json" ]
[ -f ".claude/config/project.json" ]
scripts/check-dependencies.sh --quiet
jq '.features | length > 0' .claude/progress/feature-list.json
jq '.features[0] | has("id", "description", "priority", "status")' .claude/progress/feature-list.json
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/detect-project.sh` | Detect Python/Node/Django/etc |
| `scripts/create-init-script.sh` | Generate init.sh for dev server |
| `scripts/check-dependencies.sh` | Verify env vars, services, ports |
| `scripts/create-feature-list.sh` | Generate feature-list.json |
| `scripts/init-progress.sh` | Initialize .claude/progress/ |

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
