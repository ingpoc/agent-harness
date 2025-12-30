#!/bin/bash
# setup-project-hooks.sh
#
# Main setup script for project-specific Claude Code hooks.
# Prompts for config, creates .claude/config/project.json, installs hooks.

set -euo pipefail

# Paths
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
CONFIG_DIR="$PROJECT_ROOT/.claude/config"
CONFIG_FILE="$CONFIG_DIR/project.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up project-specific Claude Code hooks..."
echo ""

# Create directories
mkdir -p "$HOOKS_DIR"
mkdir -p "$CONFIG_DIR"

# Create or update config
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Found existing config: $CONFIG_FILE"
    echo "Current config:"
    cat "$CONFIG_FILE"
    echo ""
    read -p "Update config? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing config"
    else
        "$SCRIPT_DIR/prompt-project-config.sh"
    fi
else
    echo "Creating new project config..."
    "$SCRIPT_DIR/prompt-project-config.sh"
fi

# Install hooks
echo ""
echo "Installing project hooks..."
"$SCRIPT_DIR/install-hooks.sh"

# Verify
echo ""
echo "Verifying installation..."
"$SCRIPT_DIR/verify-project-hooks.sh"

echo ""
echo "✅ Project hooks setup complete!"
echo ""
echo "Config: $CONFIG_FILE"
echo "Hooks: $HOOKS_DIR"
