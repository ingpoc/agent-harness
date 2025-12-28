#!/bin/bash
# Install skills to ~/.claude/skills/
# Usage: ./install-skills.sh

set -e

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)/.skills"
TARGET_DIR="$HOME/.claude/skills"

echo "=== Installing Skills ==="
echo "From: $SOURCE_DIR"
echo "To:   $TARGET_DIR"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy each skill folder (exclude README.md)
for skill_dir in "$SOURCE_DIR"/*/; do
    skill_name=$(basename "$skill_dir")

    echo "Installing: $skill_name"

    # Remove existing skill folder
    rm -rf "$TARGET_DIR/$skill_name"

    # Copy skill folder
    cp -r "$skill_dir" "$TARGET_DIR/$skill_name"

    # Remove README.md if exists
    rm -f "$TARGET_DIR/$skill_name/README.md"
done

# Don't copy root README.md
rm -f "$TARGET_DIR/README.md"

# Make all scripts executable
find "$TARGET_DIR" -name "*.sh" -exec chmod +x {} \;
find "$TARGET_DIR" -name "*.py" -exec chmod +x {} \;

echo ""
echo "=== Installed Skills ==="
ls -1 "$TARGET_DIR"
echo ""
echo "Total: $(ls -1 "$TARGET_DIR" | wc -l | tr -d ' ') skills"
