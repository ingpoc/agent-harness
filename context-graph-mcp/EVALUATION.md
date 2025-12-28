# Context Graph MCP Server - Evaluation Questions

## Overview

These evaluation questions test the LLM's effectiveness with the context-graph MCP server. Questions are designed to be:
- **Independent**: Each can be answered without relying on previous answers
- **Read-only**: No modifying data (store operations are hypothetical)
- **Complex**: Require understanding embeddings, semantic search, and filters
- **Realistic**: Based on actual usage patterns for decision tracking
- **Verifiable**: Answers can be checked against actual data
- **Stable**: Will work consistently as data grows

---

## Evaluation Questions

### 1. Semantic Search for Framework Decisions

**Question**: Search for all traces related to web framework selection decisions. Return the top 3 most similar results in JSON format.

**Expected Answer**:
```json
{
  "query": "web framework selection",
  "total": 3,
  "results": [
    {"rank": 1, "similarity": <number>, "category": "framework", "decision": <string>, "outcome": <string>},
    {"rank": 2, "similarity": <number>, "category": "framework", "decision": <string>, "outcome": <string>},
    {"rank": 3, "similarity": <number>, "category": "framework", "decision": <string>, "outcome": <string>}
  ]
}
```

**Tool Used**: `context_query_traces`

---

### 2. Filter by Successful Outcomes Only

**Question**: Query traces about "database" but only return those marked as successful outcomes. Limit to 5 results.

**Expected Answer**: Markdown or JSON containing only traces where `outcome === "success"`

**Tool Used**: `context_query_traces` with `outcome="success"`

---

### 3. Get Full Details of Specific Trace

**Question**: Retrieve the full decision text, timestamp, category, and all metadata for trace ID "trace_abc123def456" (or first available trace ID if not found).

**Expected Answer**: Complete trace record including: id, timestamp, category, decision (full text), outcome, session_id, feature_id, state, project_dir, created_at

**Tool Used**: `context_get_trace`

---

### 4. List All Traces with Pagination

**Question**: List all traces in the "architecture" category, showing the first 10 entries. Include pagination info and indicate if more results are available.

**Expected Answer**: Response with `total`, `count`, `offset`, `has_more`, `next_offset` fields, plus array of traces

**Tool Used**: `context_list_traces` with `category="architecture"`, `limit=10`

---

### 5. Category Breakdown by Outcome

**Question**: Show all categories with their trace counts broken down by outcome status (pending/success/failure).

**Expected Answer**: Markdown listing each category with total count and breakdown by outcome

**Tool Used**: `context_list_categories`

---

### 6. Cross-Category Semantic Search

**Question**: Find traces semantically similar to "authentication and authorization" regardless of category. Return results in markdown format with similarity percentages.

**Expected Answer**: Markdown with sections showing rank, decision preview, similarity %, category, outcome

**Tool Used**: `context_query_traces` with markdown response_format

---

### 7. Combined Filters (Category + Outcome)

**Question**: Query for "error handling" traces in the "api" category that have failed outcomes. Return up to 3 results.

**Expected Answer**: Results matching all three filters: semantic similarity to "error handling", category="api", outcome="failure"

**Tool Used**: `context_query_traces` with both category and outcome filters

---

### 8. Pagination Navigation

**Question**: Get the second page of traces (offset 20, limit 10) for the "testing" category. In your answer, report whether there are more pages available.

**Expected Answer**: Array of traces with pagination metadata showing `has_more: true/false`

**Tool Used**: `context_list_traces` with `offset=20`, `limit=10`, `category="testing"`

---

### 9. Empty Results Handling

**Question**: Search for traces matching "quantum computing algorithm design" (a topic unlikely to exist). Report how the server handles no-results scenarios.

**Expected Answer**: Message explaining no traces found, suggesting to store traces first

**Tool Used**: `context_query_traces` with unlikely query

---

### 10. Semantic vs Keyword Search Demonstration

**Question**: Query for traces about "async" (short keyword). Explain whether the results include semantically related terms like "asynchronous", "concurrency", "parallel", or only exact matches.

**Expected Answer**: Results showing semantic matches (e.g., traces about "asynchronous processing" even without the exact word "async")

**Tool Used**: `context_query_traces` demonstrating semantic search behavior

---

## Evaluation Criteria

For each question, verify:
1. **Correct Tool**: Agent selects appropriate tool for the task
2. **Parameters**: All required and optional parameters used correctly
3. **Format**: Response matches requested format (markdown/JSON)
4. **Filters**: Category, outcome, pagination filters applied correctly
5. **Error Handling**: Agent handles edge cases (empty results, invalid IDs)
6. **Semantic Understanding**: For query_traces, results show semantic similarity not just keyword matching

## Success Metric

90%+ of questions should be answered correctly with proper tool selection and parameter usage.
