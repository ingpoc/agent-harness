#!/bin/bash
# Initialize .claude/ structure for a new project
# Usage: init-project.sh [project-dir]
# Creates: .claude/config/project.json, .claude/progress/

set -e

PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR"

echo "=== Initializing Project: $PROJECT_DIR ==="

# ─────────────────────────────────────────────────────────────────
# Create directory structure
# ─────────────────────────────────────────────────────────────────
mkdir -p .claude/config
mkdir -p .claude/progress

# ─────────────────────────────────────────────────────────────────
# Auto-detect project type
# ─────────────────────────────────────────────────────────────────
detect_project() {
    if [ -f "Cargo.toml" ]; then
        if grep -q "anchor" Cargo.toml 2>/dev/null; then
            echo "solana"
        else
            echo "rust"
        fi
    elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if grep -q "fastapi" pyproject.toml requirements.txt 2>/dev/null; then
            echo "fastapi"
        elif grep -q "django" pyproject.toml requirements.txt 2>/dev/null; then
            echo "django"
        elif grep -q "flask" pyproject.toml requirements.txt 2>/dev/null; then
            echo "flask"
        else
            echo "python"
        fi
    elif [ -f "package.json" ]; then
        if grep -q '"next"' package.json 2>/dev/null; then
            echo "nextjs"
        elif grep -q '"express"' package.json 2>/dev/null; then
            echo "express"
        else
            echo "node"
        fi
    elif [ -f "go.mod" ]; then
        echo "go"
    else
        echo "unknown"
    fi
}

PROJECT_TYPE=$(detect_project)
echo "Detected: $PROJECT_TYPE"

# ─────────────────────────────────────────────────────────────────
# Set defaults based on project type
# ─────────────────────────────────────────────────────────────────
case "$PROJECT_TYPE" in
    fastapi)
        PORT=8000
        TEST_CMD="pytest -q --tb=short"
        HEALTH_CHECK="curl -sf http://localhost:8000/health"
        ;;
    django)
        PORT=8000
        TEST_CMD="python manage.py test"
        HEALTH_CHECK="curl -sf http://localhost:8000/"
        ;;
    flask)
        PORT=5000
        TEST_CMD="pytest -q --tb=short"
        HEALTH_CHECK="curl -sf http://localhost:5000/"
        ;;
    nextjs)
        PORT=3000
        TEST_CMD="npm test"
        HEALTH_CHECK="curl -sf http://localhost:3000/"
        ;;
    express|node)
        PORT=3000
        TEST_CMD="npm test"
        HEALTH_CHECK="curl -sf http://localhost:3000/health"
        ;;
    rust)
        PORT=8080
        TEST_CMD="cargo test"
        HEALTH_CHECK="curl -sf http://localhost:8080/health"
        ;;
    solana)
        PORT=8899
        TEST_CMD="anchor test"
        HEALTH_CHECK=""
        ;;
    go)
        PORT=8080
        TEST_CMD="go test ./..."
        HEALTH_CHECK="curl -sf http://localhost:8080/health"
        ;;
    python)
        PORT=8000
        TEST_CMD="pytest -q --tb=short"
        HEALTH_CHECK=""
        ;;
    *)
        PORT=3000
        TEST_CMD="echo 'No test command configured'"
        HEALTH_CHECK=""
        ;;
esac

# ─────────────────────────────────────────────────────────────────
# Create project.json
# ─────────────────────────────────────────────────────────────────
if [ ! -f ".claude/config/project.json" ]; then
    cat > .claude/config/project.json << EOF
{
  "project_type": "$PROJECT_TYPE",
  "dev_server_port": $PORT,
  "test_command": "$TEST_CMD",
  "health_check": "$HEALTH_CHECK",
  "init_script": "./scripts/init.sh",
  "required_env": [],
  "required_services": []
}
EOF
    echo "Created: .claude/config/project.json"
else
    echo "Exists: .claude/config/project.json"
fi

# ─────────────────────────────────────────────────────────────────
# Create state.json
# ─────────────────────────────────────────────────────────────────
if [ ! -f ".claude/progress/state.json" ]; then
    cat > .claude/progress/state.json << EOF
{
  "state": "START",
  "entered_at": "$(date -Iseconds)",
  "health_status": "UNKNOWN",
  "history": []
}
EOF
    echo "Created: .claude/progress/state.json"
else
    echo "Exists: .claude/progress/state.json"
fi

# ─────────────────────────────────────────────────────────────────
# Create CLAUDE.md (orchestrator instructions)
# ─────────────────────────────────────────────────────────────────
if [ ! -f ".claude/CLAUDE.md" ]; then
    cat > .claude/CLAUDE.md << 'EOF'
# Project Orchestrator

Single orchestrator architecture. Load one skill at a time based on state.

## Session Start

1. Run: `~/.claude/skills/orchestrator/scripts/session-entry.sh`
2. Check returned `next_state`
3. Load skill for that state (see mapping below)

## State → Skill Mapping

| State | Skill to Load | Exit When |
|-------|---------------|-----------|
| START | Run session-entry.sh | Entry protocol complete |
| FIX_BROKEN | enforcement/ | Health check passes |
| INIT | initialization/ | feature-list.json created |
| IMPLEMENT | implementation/ | Feature code complete |
| TEST | testing/ | Tests pass (verified by script) |
| COMPLETE | context-graph/ | Session summary saved |

## Support Skills (load when needed)

| Skill | Use When |
|-------|----------|
| browser-testing/ | UI testing, Chrome automation, recording GIFs |
| enforcement/ | Creating hooks that block invalid actions |
| determinism/ | Verifying with code, validating prompts |
| token-efficient/ | Processing >50 items, CSV/logs, sandbox execution |

## Rules

1. **One skill at a time** - Load skill, follow its procedures, exit when done
2. **Code verifies outcomes** - Never judge "tests passed", run the script
3. **State transitions enforced** - Can't skip states (INIT → TEST invalid)
4. **Commit before marking tested** - Hook blocks otherwise

## Config

- Project settings: `.claude/config/project.json`
- Current state: `.claude/progress/state.json`
- Features: `.claude/progress/feature-list.json`

## Quick Reference

```bash
# Check current state
~/.claude/skills/orchestrator/scripts/check-state.sh

# Run tests (reads test_command from config)
~/.claude/skills/testing/scripts/run-unit-tests.sh

# Health check (reads health_check from config)
~/.claude/skills/implementation/scripts/health-check.sh

# Browser smoke test (reads dev_server_port from config)
~/.claude/skills/browser-testing/scripts/smoke-test.sh
```
EOF
    echo "Created: .claude/CLAUDE.md"
else
    echo "Exists: .claude/CLAUDE.md"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Project Initialized ==="
echo ""
echo "Created:"
echo "  .claude/CLAUDE.md           - Orchestrator instructions"
echo "  .claude/config/project.json - Project settings"
echo "  .claude/progress/state.json - Current state"
echo ""
echo "Next: Start working, Claude will follow .claude/CLAUDE.md"
