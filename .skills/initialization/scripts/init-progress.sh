#!/bin/bash
# Initialize progress tracking directory

mkdir -p .claude/progress

# Create state.json if not exists
if [ ! -f ".claude/progress/state.json" ]; then
    echo '{
  "state": "INIT",
  "entered_at": "'$(date -Iseconds)'"
}' > .claude/progress/state.json
fi

# Detect and save project config
PROJECT_TYPE=$(dirname "$0")/detect-project.sh
if [ -x "$PROJECT_TYPE" ]; then
    $PROJECT_TYPE > .claude/progress/project.json
fi

echo "Progress tracking initialized at .claude/progress/"
ls -la .claude/progress/
