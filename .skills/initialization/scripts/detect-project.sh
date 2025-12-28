#!/bin/bash
# Detect project type based on files present
# Output: JSON with project type and framework

detect_type() {
    local type="unknown"
    local framework=""
    local package_manager=""

    # Python
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        type="python"
        package_manager="pip"

        if [ -f "manage.py" ]; then
            framework="django"
        elif grep -q "fastapi" requirements.txt 2>/dev/null || grep -q "fastapi" pyproject.toml 2>/dev/null; then
            framework="fastapi"
        elif grep -q "flask" requirements.txt 2>/dev/null || grep -q "flask" pyproject.toml 2>/dev/null; then
            framework="flask"
        fi
    fi

    # Node.js
    if [ -f "package.json" ]; then
        type="node"

        if [ -f "yarn.lock" ]; then
            package_manager="yarn"
        elif [ -f "pnpm-lock.yaml" ]; then
            package_manager="pnpm"
        else
            package_manager="npm"
        fi

        if grep -q '"next"' package.json 2>/dev/null; then
            framework="nextjs"
        elif grep -q '"react"' package.json 2>/dev/null; then
            framework="react"
        elif grep -q '"express"' package.json 2>/dev/null; then
            framework="express"
        fi
    fi

    # TypeScript
    if [ -f "tsconfig.json" ]; then
        type="typescript"
    fi

    echo "{\"type\": \"$type\", \"framework\": \"$framework\", \"package_manager\": \"$package_manager\"}"
}

detect_type
