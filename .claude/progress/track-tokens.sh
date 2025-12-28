#!/bin/bash
# Track token usage for compression
# Usage: ./track-tokens.sh <before_tokens> <after_tokens> [label]
# Output: JSON with token stats

BEFORE=$1
AFTER=$2
LABEL=${3:-"compression"}

if [ -z "$BEFORE" ] || [ -z "$AFTER" ]; then
    echo '{"error": "Missing required args: before_tokens after_tokens"}'
    exit 1
fi

# Calculate savings
DIFF=$((BEFORE - AFTER))
if [ "$BEFORE" -gt 0 ]; then
    SAVINGS=$(awk "BEGIN {printf \"%.2f\", ($DIFF / $BEFORE) * 100}")
else
    SAVINGS="0.00"
fi

# Get timestamp
TIMESTAMP=$(date -Iseconds)

# Output JSON
cat <<EOF
{
  "label": "$LABEL",
  "timestamp": "$TIMESTAMP",
  "tokens_before": $BEFORE,
  "tokens_after": $AFTER,
  "tokens_saved": $DIFF,
  "savings_percent": $SAVINGS
}
EOF

# Log to history
HISTORY_FILE=".claude/progress/token-history.jsonl"
mkdir -p "$(dirname "$HISTORY_FILE")"

cat <<EOF >> "$HISTORY_FILE"
{"label":"$LABEL","timestamp":"$TIMESTAMP","before":$BEFORE,"after":$AFTER,"saved":$DIFF,"percent":$SAVINGS}
EOF

# Human-readable summary
echo ""
echo "📊 Token Tracking: $LABEL"
echo "   Before: $BEFORE tokens"
echo "   After:  $AFTER tokens"
echo "   Saved:  $DIFF tokens ($SAVINGS%)"
