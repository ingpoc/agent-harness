#!/bin/bash
# Get current state from state.json
# Output: JSON with current state or default START

STATE_FILE=".claude/progress/state.json"

if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
else
    echo '{"state": "START", "entered_at": "'$(date -Iseconds)'"}'
fi
