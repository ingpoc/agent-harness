# Context Graph MCP Server

MCP server for storing and querying decision traces with semantic search using Voyage AI embeddings and ChromaDB.

## Features

- **Semantic Search**: Find decisions by meaning, not keywords
- **Vector Embeddings**: 1024-dim embeddings via Voyage AI
- **Local Storage**: ChromaDB for cross-platform vector database
- **Outcome Tracking**: Mark decisions as success/failure after validation
- **Category Filtering**: Group by framework, architecture, api, error, testing, deployment

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Set Voyage AI API key
export VOYAGE_API_KEY="your_key_here"
```

## Usage

```bash
# Run server (stdio transport)
python server.py
```

## MCP Configuration

Add to `~/.config/claude/mcp.json` or `.claude/mcp.json`:

```json
{
  "mcpServers": {
    "context-graph": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/context-graph-mcp",
        "run",
        "python",
        "server.py"
      ],
      "env": {
        "VOYAGE_API_KEY": "your_key_here"
      }
    }
  }
}
```

## Tools

| Tool | Purpose |
|------|---------|
| `context_store_trace` | Store decision with embedding |
| `context_query_traces` | Semantic vector search |
| `context_get_trace` | Get specific trace by ID |
| `context_update_outcome` | Update outcome status |
| `context_list_traces` | List with pagination |
| `context_list_categories` | Category counts |

## Trace Schema

```
{
  "id": "trace_abc123...",
  "timestamp": "2025-01-15T10:30:00",
  "category": "framework",
  "decision": "Chose FastAPI over Flask for async support",
  "outcome": "pending|success|failure",
  "state": "IMPLEMENT",
  "feature_id": "feat-001"
}
```

## Categories

- `framework` - Tech stack choices
- `architecture` - Design patterns, structure
- `api` - Endpoint design, contracts
- `error` - Failure modes, fixes
- `testing` - Test strategies
- `deployment` - Infra decisions
