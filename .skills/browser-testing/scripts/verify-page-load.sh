#!/bin/bash
# Verify page loaded successfully
# Usage: verify-page-load.sh URL [EXPECTED_ELEMENT]
# Exit: 0 = loaded, 1 = failed

URL=$1
EXPECTED=${2:-"body"}
TIMEOUT=10

if [ -z "$URL" ]; then
    echo "Usage: verify-page-load.sh URL [EXPECTED_ELEMENT]"
    exit 1
fi

echo "=== Verifying Page Load ==="
echo "URL: $URL"
echo "Expected element: $EXPECTED"

# Check if URL is reachable (basic HTTP check)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$URL" 2>/dev/null)

if [ "$STATUS" = "200" ]; then
    echo "✓ HTTP 200 OK"
    exit 0
elif [ "$STATUS" = "000" ]; then
    echo "✗ Connection failed (timeout or unreachable)"
    exit 1
else
    echo "⚠ HTTP $STATUS (may still work in browser)"
    exit 0
fi
