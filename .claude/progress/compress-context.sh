#!/bin/bash
# Compress conversation context with token tracking
# Usage: ./compress-context.sh <level> <context_tokens>
# Levels: remove_raw | summarize | full | emergency

LEVEL=$1
CONTEXT_TOKENS=$2
PROGRESS_DIR=".claude/progress"
TOKENS_FILE="$PROGRESS_DIR/tokens.json"
SUMMARY_FILE="$PROGRESS_DIR/summary.md"

mkdir -p "$PROGRESS_DIR"

# Record tokens before compression
echo "$CONTEXT_TOKENS" > "$TOKENS_FILE.before"

# Compression level strategies
case $LEVEL in
    remove_raw)
        # Remove raw tool outputs, keep summaries
        TARGET=$((CONTEXT_TOKENS * 85 / 100))
        STRATEGY="Remove raw tool outputs"
        ;;
    summarize)
        # Summarize old conversations
        TARGET=$((CONTEXT_TOKENS * 70 / 100))
        STRATEGY="Summarize historical context (keep recent 5)"
        ;;
    full)
        # Full compression to 2K tokens
        TARGET=2000
        STRATEGY="Full LLM compression to 2K tokens"
        ;;
    emergency)
        # Preserve only current state
        TARGET=1000
        STRATEGY="Emergency: preserve only current state"
        ;;
    *)
        echo '{"error": "Invalid level. Use: remove_raw, summarize, full, or emergency"}'
        exit 1
        ;;
esac

echo "🗜️  Compressing context (Level: $LEVEL)"
echo "   Strategy: $STRATEGY"
echo "   Target: ~$TARGET tokens"
echo ""
echo "➤ To compress, Claude should:"
echo "   1. Extract: Current State, Key Decisions, Files Modified, Next Action"
echo "   2. Discard: Raw outputs, verbose logs, redundant reads"
echo "   3. Preserve: Last 5 files touched, unresolved issues"
echo ""
echo "Compression prompt template:"
echo "---"
cat <<'EOF'
Compress the conversation to essential context (target: 2000 tokens):

## Current State
- State: [INIT/IMPLEMENT/TEST/COMPLETE]
- Feature: [ID and description]
- Progress: [What's done, what remains]

## Key Decisions Made
1. [Decision 1 with rationale]
2. [Decision 2 with rationale]

## Files Recently Modified (Last 5)
- [file1.ext] - [what was changed]
- [file2.ext] - [what was changed]

## Unresolved Issues
- [ ] [Issue 1]
- [ ] [Issue 2]

## Next Action
[Specific next step]

---
Discard: Raw file contents, build output, superseded attempts
EOF
echo "---"
echo ""
echo "After compression, run:"
echo "  ./track-tokens.sh $CONTEXT_TOKENS <new_tokens> $LEVEL"
