#!/bin/bash
# Run unit tests based on project type
# Exit: 0 = all pass, 1 = failures

PROJECT_FILE=".claude/progress/project.json"
EVIDENCE_DIR="/tmp/test-evidence"
mkdir -p "$EVIDENCE_DIR"

echo "=== Running Unit Tests ==="

# Detect project type
if [ -f "$PROJECT_FILE" ]; then
    TYPE=$(jq -r '.type' "$PROJECT_FILE")
else
    # Auto-detect
    if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
        TYPE="python"
    elif [ -f "package.json" ]; then
        TYPE="node"
    fi
fi

RESULT=0

# Python: pytest
if [ "$TYPE" = "python" ]; then
    if command -v pytest &> /dev/null; then
        pytest --tb=short --json-report --json-report-file="$EVIDENCE_DIR/pytest.json" 2>&1 | tee "$EVIDENCE_DIR/pytest.log"
        RESULT=${PIPESTATUS[0]}
    else
        python -m pytest --tb=short 2>&1 | tee "$EVIDENCE_DIR/pytest.log"
        RESULT=${PIPESTATUS[0]}
    fi
fi

# Node: jest or npm test
if [ "$TYPE" = "node" ] || [ "$TYPE" = "typescript" ]; then
    if grep -q '"jest"' package.json 2>/dev/null; then
        npx jest --json --outputFile="$EVIDENCE_DIR/jest.json" 2>&1 | tee "$EVIDENCE_DIR/jest.log"
        RESULT=${PIPESTATUS[0]}
    elif grep -q '"test"' package.json 2>/dev/null; then
        npm test 2>&1 | tee "$EVIDENCE_DIR/npm-test.log"
        RESULT=${PIPESTATUS[0]}
    fi
fi

# Record result
echo "{\"unit_tests\": {\"passed\": $([ $RESULT -eq 0 ] && echo true || echo false), \"exit_code\": $RESULT}}" > "$EVIDENCE_DIR/unit-tests.json"

exit $RESULT
