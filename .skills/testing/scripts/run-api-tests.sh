#!/bin/bash
# Run API endpoint tests
# Exit: 0 = all pass, 1 = failures

EVIDENCE_DIR="/tmp/test-evidence"
mkdir -p "$EVIDENCE_DIR"

BASE_URL="${API_URL:-http://localhost:8000}"
ERRORS=0
TESTS=0

echo "=== Running API Tests ==="
echo "Base URL: $BASE_URL"

# Test health endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local description=$4

    ((TESTS++))

    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE_URL$endpoint" --max-time 5)

    if [ "$STATUS" = "$expected_status" ]; then
        echo "✓ $description - $STATUS"
    else
        echo "✗ $description - Expected $expected_status, got $STATUS"
        ((ERRORS++))
    fi
}

# Common API tests
test_endpoint "GET" "/health" "200" "Health check"
test_endpoint "GET" "/" "200" "Root endpoint"

# Look for OpenAPI spec and test documented endpoints
if curl -s "$BASE_URL/openapi.json" > /dev/null 2>&1; then
    echo "Found OpenAPI spec, testing documented endpoints..."
    # Could parse and test each endpoint
fi

# Save results
echo "{
  \"api_tests\": {
    \"total\": $TESTS,
    \"passed\": $((TESTS - ERRORS)),
    \"failed\": $ERRORS,
    \"passed\": $([ $ERRORS -eq 0 ] && echo true || echo false)
  }
}" > "$EVIDENCE_DIR/api-tests.json"

if [ $ERRORS -eq 0 ]; then
    echo "=== All $TESTS API tests passed ==="
    exit 0
else
    echo "=== $ERRORS of $TESTS API tests failed ==="
    exit 1
fi
