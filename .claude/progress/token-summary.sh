#!/bin/bash
# Show token usage summary from history
# Usage: ./token-summary.sh

HISTORY_FILE=".claude/progress/token-history.jsonl"

if [ ! -f "$HISTORY_FILE" ]; then
    echo "No token history found. Run track-tokens.sh first."
    exit 0
fi

# Count entries
ENTRIES=$(wc -l < "$HISTORY_FILE")

# Calculate totals
TOTAL_BEFORE=$(awk -F',' '{print $4}' "$HISTORY_FILE" | sed 's/before://' | awk '{s+=$1} END {print s}')
TOTAL_AFTER=$(awk -F',' '{print $5}' "$HISTORY_FILE" | sed 's/after://' | awk '{s+=$1} END {print s}')
TOTAL_SAVED=$(awk -F',' '{print $6}' "$HISTORY_FILE" | sed 's/saved://' | awk '{s+=$1} END {print s}')

# Calculate average savings
AVG_SAVINGS=$(awk -F',' '{print $7}' "$HISTORY_FILE" | sed 's/percent://' | awk '{s+=$1; n++} END {printf "%.2f", s/n}')

echo "📊 Token Usage Summary"
echo "====================="
echo ""
echo "Compression Events: $ENTRIES"
echo ""
echo "Total Tokens:"
echo "  Before: $(printf "%'d" $TOTAL_BEFORE)"
echo "  After:  $(printf "%'d" $TOTAL_AFTER)"
echo "  Saved:  $(printf "%'d" $TOTAL_SAVED) ($AVG_SAVINGS%)"
echo ""
echo "Recent History:"
echo "----------------"

# Show last 5 entries in reverse order
tail -5 "$HISTORY_FILE" | while read -r line; do
    LABEL=$(echo "$line" | jq -r '.label')
    BEFORE=$(echo "$line" | jq '.before')
    AFTER=$(echo "$line" | jq '.after')
    SAVED=$(echo "$line" | jq '.saved')
    PERCENT=$(echo "$line" | jq -r '.percent')
    echo "  $LABEL: $BEFORE → $AFTER (-$SAVED, $PERCENT%)"
done

echo ""
echo "💡 Tip: 90% cache discount available via prompt caching (anthropic-beta: prompt-caching-2024-07-31)"
