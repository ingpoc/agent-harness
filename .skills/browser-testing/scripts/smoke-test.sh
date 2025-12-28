#!/bin/bash
# Run basic smoke test on URL
# Usage: smoke-test.sh URL
# Exit: 0 = pass, 1 = fail

URL=$1
EVIDENCE_DIR="/tmp/test-evidence"

if [ -z "$URL" ]; then
    echo "Usage: smoke-test.sh URL"
    exit 1
fi

mkdir -p "$EVIDENCE_DIR"

echo "=== Smoke Test: $URL ==="
ERRORS=0

# 1. Check HTTP reachability
echo "1. Checking HTTP..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null)
if [ "$STATUS" = "200" ]; then
    echo "   ✓ HTTP 200"
else
    echo "   ✗ HTTP $STATUS"
    ((ERRORS++))
fi

# 2. Check response time
echo "2. Checking response time..."
TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$URL" 2>/dev/null)
if (( $(echo "$TIME < 3.0" | bc -l) )); then
    echo "   ✓ Response time: ${TIME}s"
else
    echo "   ⚠ Slow response: ${TIME}s"
fi

# 3. Check for basic HTML
echo "3. Checking content..."
CONTENT=$(curl -s --max-time 10 "$URL" 2>/dev/null | head -c 1000)
if echo "$CONTENT" | grep -q "<html\|<!DOCTYPE"; then
    echo "   ✓ Valid HTML response"
else
    echo "   ⚠ Non-HTML or empty response"
fi

# Save results
cat > "$EVIDENCE_DIR/smoke-test.json" << EOF
{
  "url": "$URL",
  "http_status": "$STATUS",
  "response_time": "$TIME",
  "passed": $([ $ERRORS -eq 0 ] && echo true || echo false),
  "timestamp": "$(date -Iseconds)"
}
EOF

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "=== Smoke Test PASSED ==="
    exit 0
else
    echo "=== Smoke Test FAILED ==="
    exit 1
fi
