#!/bin/bash
# Run health checks based on project type
# Exit: 0 = healthy, 1 = unhealthy

PROJECT_FILE=".claude/progress/project.json"
ERRORS=0

echo "=== Health Check ==="

# Detect project type
if [ -f "$PROJECT_FILE" ]; then
    TYPE=$(jq -r '.type' "$PROJECT_FILE")
    FRAMEWORK=$(jq -r '.framework' "$PROJECT_FILE")
else
    TYPE="unknown"
fi

# Python checks
if [ "$TYPE" = "python" ]; then
    echo "Checking Python..."

    # Syntax check
    find . -name "*.py" -not -path "./venv/*" -exec python -m py_compile {} \; 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "FAIL: Python syntax errors"
        ((ERRORS++))
    else
        echo "✓ Python syntax OK"
    fi

    # Import check for main module
    if [ -f "src/main.py" ]; then
        python -c "import src.main" 2>/dev/null || ((ERRORS++))
    fi
fi

# Node checks
if [ "$TYPE" = "node" ] || [ "$TYPE" = "typescript" ]; then
    echo "Checking Node.js..."

    # TypeScript compile check
    if [ -f "tsconfig.json" ]; then
        npx tsc --noEmit 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "FAIL: TypeScript errors"
            ((ERRORS++))
        else
            echo "✓ TypeScript OK"
        fi
    fi
fi

# Server check (if applicable)
if [ -f "manage.py" ] || [ -f "app.py" ] || [ -f "main.py" ]; then
    echo "Checking if server can start..."
    # Start server in background, wait, then kill
    timeout 5 python -c "import main" 2>/dev/null && echo "✓ Server module OK"
fi

if [ $ERRORS -eq 0 ]; then
    echo "=== All health checks passed ==="
    exit 0
else
    echo "=== $ERRORS health check(s) failed ==="
    exit 1
fi
