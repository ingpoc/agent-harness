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
# Summary
# ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Project Initialized ==="
echo ""
cat .claude/config/project.json
echo ""
echo "Next steps:"
echo "  1. Edit .claude/config/project.json if needed"
echo "  2. Run session-entry.sh to start"
