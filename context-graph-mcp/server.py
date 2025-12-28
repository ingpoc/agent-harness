#!/usr/bin/env python3
"""
Context Graph MCP Server

Stores decision traces with semantic search using Voyage AI embeddings
and ChromaDB for vector storage. Enables finding similar past decisions
by meaning, not keywords.

Usage:
    export VOYAGE_API_KEY="your_key"
    python server.py
"""

import asyncio
import json
import os
import hashlib
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional, List, Dict, Any

import httpx
import chromadb
from chromadb.config import Settings
from pydantic import BaseModel, Field, field_validator, ConfigDict
from mcp.server.fastmcp import FastMCP, Context

# ─────────────────────────────────────────────────────────────────
# Server Configuration
# ─────────────────────────────────────────────────────────────────

mcp = FastMCP("context_graph_mcp")

EMBEDDING_MODEL = "voyage-3"  # or voyage-3-lite for faster/cheaper
EMBEDDING_DIM = 1024
CHARACTER_LIMIT = 25000
VOYAGE_API_URL = "https://api.voyageai.com/v1/embeddings"

# ─────────────────────────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────────────────────────

class ResponseFormat(str, Enum):
    """Output format for tool responses."""
    MARKDOWN = "markdown"
    JSON = "json"

class TraceOutcome(str, Enum):
    """Possible outcomes for a trace."""
    PENDING = "pending"
    SUCCESS = "success"
    FAILURE = "failure"

# ─────────────────────────────────────────────────────────────────
# Pydantic Models for Input Validation
# ─────────────────────────────────────────────────────────────────

class StoreTraceInput(BaseModel):
    """Input model for storing a decision trace."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra='forbid'
    )

    decision: str = Field(
        ...,
        description="The decision text to store (e.g., 'Chose FastAPI over Flask for async support')",
        min_length=10,
        max_length=5000
    )
    category: str = Field(
        default="general",
        description="Category for grouping (framework, architecture, api, error, testing, deployment)",
        min_length=1,
        max_length=50
    )
    outcome: TraceOutcome = Field(
        default=TraceOutcome.PENDING,
        description="Initial outcome status"
    )
    feature_id: Optional[str] = Field(
        default=None,
        description="Related feature ID if applicable"
    )
    project_dir: Optional[str] = Field(
        default=None,
        description="Project directory (auto-detected if not provided)"
    )

class QueryTracesInput(BaseModel):
    """Input model for querying traces by semantic similarity."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra='forbid'
    )

    query: str = Field(
        ...,
        description="Search query to find similar decisions (e.g., 'web framework selection')",
        min_length=3,
        max_length=500
    )
    limit: int = Field(
        default=5,
        description="Maximum number of results to return",
        ge=1,
        le=50
    )
    category: Optional[str] = Field(
        default=None,
        description="Filter by category (optional)"
    )
    outcome: Optional[TraceOutcome] = Field(
        default=None,
        description="Filter by outcome (optional)"
    )
    response_format: ResponseFormat = Field(
        default=ResponseFormat.MARKDOWN,
        description="Output format: markdown for human-readable, json for machine-readable"
    )

class GetTraceInput(BaseModel):
    """Input model for retrieving a specific trace."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra='forbid'
    )

    trace_id: str = Field(
        ...,
        description="The unique trace identifier (e.g., 'trace_abc123...')"
    )
    response_format: ResponseFormat = Field(
        default=ResponseFormat.MARKDOWN,
        description="Output format"
    )

class UpdateOutcomeInput(BaseModel):
    """Input model for updating trace outcome."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra='forbid'
    )

    trace_id: str = Field(
        ...,
        description="The unique trace identifier"
    )
    outcome: TraceOutcome = Field(
        ...,
        description="New outcome status"
    )

class ListTracesInput(BaseModel):
    """Input model for listing traces."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra='forbid'
    )

    category: Optional[str] = Field(
        default=None,
        description="Filter by category"
    )
    outcome: Optional[TraceOutcome] = Field(
        default=None,
        description="Filter by outcome"
    )
    limit: int = Field(
        default=20,
        description="Maximum results to return",
        ge=1,
        le=100
    )
    offset: int = Field(
        default=0,
        description="Number of results to skip for pagination",
        ge=0
    )
    response_format: ResponseFormat = Field(
        default=ResponseFormat.MARKDOWN,
        description="Output format"
    )

# ─────────────────────────────────────────────────────────────────
# ChromaDB Client
# ─────────────────────────────────────────────────────────────────

_collection_cache = {}

def get_chroma_client(project_dir: Optional[str] = None):
    """Get or create ChromaDB client for a project."""
    cache_key = project_dir or "default"

    if cache_key in _collection_cache:
        return _collection_cache[cache_key]

    # Determine database path
    if project_dir:
        db_dir = Path(project_dir) / ".claude" / "chroma"
    else:
        db_dir = Path(".claude/chroma")

    db_dir.mkdir(parents=True, exist_ok=True)

    # Create ChromaDB client with persistent storage
    client = chromadb.PersistentClient(path=str(db_dir))

    # Get or create collection
    collection = client.get_or_create_collection(
        name="traces",
        metadata={"description": "Decision traces with semantic search"}
    )

    _collection_cache[cache_key] = collection
    return collection

def get_voyage_key() -> str:
    """Get Voyage AI API key from environment."""
    key = os.environ.get("VOYAGE_API_KEY")
    if not key:
        raise ValueError(
            "VOYAGE_API_KEY not found. Set via: export VOYAGE_API_KEY='your_key'"
        )
    return key

async def get_embedding(text: str, api_key: str) -> List[float]:
    """Get embedding from Voyage AI."""
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            VOYAGE_API_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            },
            json={
                "input": [text],
                "model": EMBEDDING_MODEL
            }
        )
        response.raise_for_status()
        data = response.json()
        return data["data"][0]["embedding"]

# ─────────────────────────────────────────────────────────────────
# Tool Definitions
# ─────────────────────────────────────────────────────────────────

@mcp.tool(name="context_store_trace")
async def context_store_trace(
    decision: str,
    category: str = "general",
    outcome: str = "pending",
    feature_id: Optional[str] = None,
    project_dir: Optional[str] = None,
    ctx: Optional[Context] = None
) -> str:
    """Store a decision trace with semantic embedding for future retrieval.

    This tool stores technical decisions with their embeddings, enabling
    semantic search later. Unlike keyword search, this finds decisions
    by meaning and context.

    Args:
        decision: The decision text to store (e.g., 'Chose FastAPI over Flask for async support')
        category: Category for grouping (framework, architecture, api, error, testing, deployment)
        outcome: Initial outcome status (pending/success/failure)
        feature_id: Related feature ID if applicable
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: JSON with trace_id and metadata

    Examples:
        - Store a framework decision: context_store_trace(decision="Chose FastAPI for async", category="framework")
        - Store with outcome: context_store_trace(decision="Used Redis for caching", category="architecture", outcome="success")
        - Link to feature: context_store_trace(decision="Implemented OAuth flow", category="api", feature_id="feat-001")

    Error Handling:
        - Returns "Error: VOYAGE_API_KEY not found" if key not set
        - Returns "Error: Embedding API failed" if Voyage API call fails
    """
    try:
        api_key = get_voyage_key()
        collection = get_chroma_client(project_dir)

        # Generate trace ID
        timestamp = datetime.now().isoformat()
        trace_id = f"trace_{hashlib.sha256(f'{timestamp}{decision}'.encode()).hexdigest()[:12]}"

        # Get embedding
        if ctx:
            await ctx.report_progress(0.5, "Generating embedding...")

        embedding = await get_embedding(decision, api_key)

        if ctx:
            await ctx.report_progress(0.8, "Storing trace...")

        # Store in ChromaDB
        metadata = {
            "trace_id": trace_id,
            "timestamp": timestamp,
            "category": category,
            "outcome": outcome,
            "feature_id": feature_id or "",
            "state": "",
            "project_dir": project_dir or os.getcwd(),
            "session_id": ""
        }

        collection.add(
            ids=[trace_id],
            embeddings=[embedding],
            documents=[decision],
            metadatas=[metadata]
        )

        if ctx:
            await ctx.report_progress(1.0, "Trace stored successfully")

        result = {
            "trace_id": trace_id,
            "timestamp": timestamp,
            "category": category,
            "decision": decision[:200] + "..." if len(decision) > 200 else decision,
            "outcome": outcome
        }

        return json.dumps(result, indent=2)

    except ValueError as e:
        return f"Error: {str(e)}"
    except Exception as e:
        return f"Error: Failed to store trace - {type(e).__name__}: {str(e)}"


@mcp.tool(name="context_query_traces")
async def context_query_traces(
    query: str,
    limit: int = 5,
    category: Optional[str] = None,
    outcome: Optional[str] = None,
    response_format: str = "markdown",
    project_dir: Optional[str] = None,
    ctx: Optional[Context] = None
) -> str:
    """Query traces by semantic similarity to find relevant past decisions.

    Uses vector embeddings to find traces similar to your query by meaning,
    not just keywords. This helps when facing similar situations and wanting
    to know what decisions were made before.

    Args:
        query: Search query to find similar decisions (e.g., 'web framework selection')
        limit: Maximum results to return (1-50, default 5)
        category: Filter by category (optional)
        outcome: Filter by outcome (optional)
        response_format: Output format (markdown/json)
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: Formatted results with similarity scores

    Examples:
        - Find framework decisions: context_query_traces(query="web framework choice")
        - Find in category: context_query_traces(query="database", category="architecture")
        - More results: context_query_traces(query="error handling", limit=10)
        - JSON output: context_query_traces(query="api design", response_format="json")

    Error Handling:
        - Returns "Error: No traces found" if database is empty
        - Returns "Error: VOYAGE_API_KEY not found" if key not set
    """
    try:
        api_key = get_voyage_key()
        collection = get_chroma_client(project_dir)

        # Check if collection has any data
        count = collection.count()
        if count == 0:
            return f"# No traces found\n\nStore decisions first to enable semantic search."

        if ctx:
            await ctx.report_progress(0.3, "Generating query embedding...")

        # Get query embedding
        query_embedding = await get_embedding(query, api_key)

        if ctx:
            await ctx.report_progress(0.7, "Searching traces...")

        # Build where clause for filters
        where = {}
        if category:
            where["category"] = category
        if outcome:
            where["outcome"] = outcome

        # Query ChromaDB
        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=limit,
            where=where if where else None
        )

        if not results or not results['ids'][0]:
            return f"# No similar traces found\n\nQuery: '{query}'\n\nNo traces match your search."

        # Format results
        if response_format == ResponseFormat.JSON:
            output = []
            for i, trace_id in enumerate(results['ids'][0], 1):
                metadata = results['metadatas'][0][i-1]
                document = results['documents'][0][i-1]
                distance = results['distances'][0][i-1] if results['distances'] else None

                # Convert distance to similarity (ChromaDB uses L2 distance)
                similarity = 1 / (1 + distance) if distance is not None else None

                output.append({
                    "rank": i,
                    "similarity": round(similarity, 3) if similarity else None,
                    "id": trace_id,
                    "category": metadata.get("category"),
                    "decision": document,
                    "outcome": metadata.get("outcome"),
                    "state": metadata.get("state"),
                    "feature_id": metadata.get("feature_id"),
                    "timestamp": metadata.get("timestamp")
                })

            return json.dumps({
                "query": query,
                "total": len(output),
                "results": output
            }, indent=2)

        else:
            # Markdown format
            lines = [
                f"# Similar Traces for: \"{query[:100]}\"",
                "",
                f"Found {len(results['ids'][0])} similar trace(s)",
                ""
            ]

            for i, trace_id in enumerate(results['ids'][0], 1):
                metadata = results['metadatas'][0][i-1]
                document = results['documents'][0][i-1]
                distance = results['distances'][0][i-1] if results['distances'] else None

                # Convert distance to similarity percentage
                similarity = 1 / (1 + distance) if distance is not None else None
                similarity_pct = f"{similarity * 100:.0f}%" if similarity else "N/A"

                short_decision = document[:100] + "..." if len(document) > 100 else document

                lines.append(f"## {i}. {short_decision} ({similarity_pct} similar)")
                lines.append(f"- **ID**: `{trace_id}`")
                lines.append(f"- **Category**: {metadata.get('category')}")
                lines.append(f"- **Outcome**: {metadata.get('outcome')}")
                if metadata.get('state'):
                    lines.append(f"- **State**: {metadata.get('state')}")
                if metadata.get('feature_id'):
                    lines.append(f"- **Feature**: {metadata.get('feature_id')}")
                lines.append("")

            return "\n".join(lines)

    except ValueError as e:
        return f"Error: {str(e)}"
    except Exception as e:
        return f"Error: Query failed - {type(e).__name__}: {str(e)}"


@mcp.tool(name="context_get_trace")
async def context_get_trace(
    trace_id: str,
    response_format: str = "markdown",
    project_dir: Optional[str] = None
) -> str:
    """Retrieve full details of a specific trace by ID.

    Args:
        trace_id: The unique trace identifier (e.g., 'trace_abc123...')
        response_format: Output format (markdown/json)
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: Full trace details

    Examples:
        - Get trace details: context_get_trace(trace_id="trace_abc123...")
    """
    try:
        collection = get_chroma_client(project_dir)

        # Get the trace
        results = collection.get(
            ids=[trace_id],
            include=["embeddings", "documents", "metadatas"]
        )

        if not results or not results['ids']:
            return f"Error: Trace '{trace_id}' not found."

        metadata = results['metadatas'][0]
        document = results['documents'][0]

        if response_format == ResponseFormat.JSON:
            return json.dumps({
                "id": trace_id,
                "timestamp": metadata.get("timestamp"),
                "category": metadata.get("category"),
                "decision": document,
                "outcome": metadata.get("outcome"),
                "session_id": metadata.get("session_id"),
                "feature_id": metadata.get("feature_id"),
                "state": metadata.get("state"),
                "project_dir": metadata.get("project_dir")
            }, indent=2)

        else:
            lines = [
                f"# Trace: {trace_id}",
                "",
                f"**Decision**: {document}",
                f"**Category**: {metadata.get('category')}",
                f"**Outcome**: {metadata.get('outcome')}",
                f"**Timestamp**: {metadata.get('timestamp')}",
                ""
            ]

            if metadata.get('session_id'):
                lines.append(f"**Session**: {metadata.get('session_id')}")
            if metadata.get('feature_id'):
                lines.append(f"**Feature**: {metadata.get('feature_id')}")
            if metadata.get('state'):
                lines.append(f"**State**: {metadata.get('state')}")
            if metadata.get('project_dir'):
                lines.append(f"**Project**: {metadata.get('project_dir')}")
            lines.append("")

            return "\n".join(lines)

    except Exception as e:
        return f"Error: Failed to get trace - {type(e).__name__}: {str(e)}"


@mcp.tool(name="context_update_outcome")
async def context_update_outcome(
    trace_id: str,
    outcome: str,
    project_dir: Optional[str] = None
) -> str:
    """Update the outcome status of a stored trace.

    After implementing a decision, update its outcome to track whether
    the decision was successful or if it caused problems.

    Args:
        trace_id: The unique trace identifier
        outcome: New outcome status (pending/success/failure)
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: Confirmation with updated trace details

    Examples:
        - Mark as successful: context_update_outcome(trace_id="trace_abc123...", outcome="success")
        - Mark as failed: context_update_outcome(trace_id="trace_abc123...", outcome="failure")

    Error Handling:
        - Returns "Error: Trace '{trace_id}' not found" if invalid ID
    """
    try:
        collection = get_chroma_client(project_dir)

        # Get current trace
        results = collection.get(
            ids=[trace_id],
            include=["metadatas", "documents", "embeddings"]
        )

        if not results or not results['ids']:
            return f"Error: Trace '{trace_id}' not found."

        # Update metadata
        metadata = results['metadatas'][0].copy()
        metadata['outcome'] = outcome

        # Update in ChromaDB (delete and re-add since ChromaDB doesn't have update)
        collection.delete(ids=[trace_id])
        collection.add(
            ids=[trace_id],
            embeddings=[results['embeddings'][0]],
            documents=[results['documents'][0]],
            metadatas=[metadata]
        )

        result = {
            "trace_id": trace_id,
            "outcome": outcome,
            "updated": True
        }

        return json.dumps(result, indent=2)

    except Exception as e:
        return f"Error: Failed to update outcome - {type(e).__name__}: {str(e)}"


@mcp.tool(name="context_list_traces")
async def context_list_traces(
    category: Optional[str] = None,
    outcome: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    response_format: str = "markdown",
    project_dir: Optional[str] = None
) -> str:
    """List all stored traces with optional filtering and pagination.

    Args:
        category: Filter by category (optional)
        outcome: Filter by outcome (optional)
        limit: Maximum results to return (1-100, default 20)
        offset: Number of results to skip (default 0)
        response_format: Output format (markdown/json)
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: Formatted list of traces with pagination info

    Examples:
        - List all traces: context_list_traces()
        - Filter by category: context_list_traces(category="framework")
        - Get more results: context_list_traces(limit=50)
        - Paginate: context_list_traces(offset=20)

    Error Handling:
        - Returns "Error: No traces database found" if not initialized
    """
    try:
        collection = get_chroma_client(project_dir)

        # Get all traces
        results = collection.get(
            include=["documents", "metadatas"]
        )

        if not results or not results['ids']:
            return "Error: No traces found. Store a trace first."

        # Filter and format
        traces = []
        for i, trace_id in enumerate(results['ids']):
            metadata = results['metadatas'][i]
            document = results['documents'][i]

            # Apply filters
            if category and metadata.get('category') != category:
                continue
            if outcome and metadata.get('outcome') != outcome:
                continue

            traces.append({
                'id': trace_id,
                'timestamp': metadata.get('timestamp'),
                'category': metadata.get('category'),
                'decision': document,
                'outcome': metadata.get('outcome'),
                'feature_id': metadata.get('feature_id'),
                'state': metadata.get('state')
            })

        # Sort by timestamp (newest first)
        traces.sort(key=lambda x: x['timestamp'], reverse=True)

        # Apply pagination
        total = len(traces)
        paginated = traces[offset:offset + limit]

        if response_format == ResponseFormat.JSON:
            results_data = []
            for t in paginated:
                results_data.append({
                    "id": t['id'],
                    "timestamp": t['timestamp'],
                    "category": t['category'],
                    "decision": t['decision'][:100] + "..." if len(t['decision']) > 100 else t['decision'],
                    "outcome": t['outcome'],
                    "feature_id": t['feature_id'],
                    "state": t['state']
                })

            return json.dumps({
                "total": total,
                "count": len(results_data),
                "offset": offset,
                "has_more": offset + len(results_data) < total,
                "next_offset": offset + len(results_data) if offset + len(results_data) < total else None,
                "traces": results_data
            }, indent=2)

        else:
            lines = [
                f"# Decision Traces",
                "",
                f"**Total**: {total} | **Showing**: {len(paginated)} (offset {offset})",
                ""
            ]

            if category:
                lines.append(f"**Filter**: category='{category}'")
            if outcome:
                lines.append(f"**Filter**: outcome='{outcome}'")
            lines.append("")

            for t in paginated:
                short_decision = t['decision'][:80] + "..." if len(t['decision']) > 80 else t['decision']

                lines.append(f"## {short_decision}")
                lines.append(f"- **ID**: `{t['id']}`")
                lines.append(f"- **Category**: {t['category']} | **Outcome**: {t['outcome']}")
                lines.append(f"- **When**: {t['timestamp']}")
                lines.append("")

            if offset + len(paginated) < total:
                lines.append(f"*More traces available (use offset={offset + len(paginated)})*")

            return "\n".join(lines)

    except Exception as e:
        return f"Error: Failed to list traces - {type(e).__name__}: {str(e)}"


@mcp.tool(name="context_list_categories")
async def context_list_categories(project_dir: Optional[str] = None) -> str:
    """List all categories and their trace counts.

    Args:
        project_dir: Project directory (defaults to current working directory)

    Returns:
        str: Category counts

    Examples:
        - List all categories: context_list_categories()
    """
    try:
        collection = get_chroma_client(project_dir)

        # Get all traces
        results = collection.get(
            include=["metadatas"]
        )

        if not results or not results['ids']:
            return "# No categories found\n\nStore traces to populate categories."

        # Count by category and outcome
        categories = {}
        for metadata in results['metadatas']:
            cat = metadata.get('category', 'general')
            outcome = metadata.get('outcome', 'pending')

            if cat not in categories:
                categories[cat] = {}
            if outcome not in categories[cat]:
                categories[cat][outcome] = 0
            categories[cat][outcome] += 1

        if not categories:
            return "# No categories found\n\nStore traces to populate categories."

        # Format output
        lines = ["# Trace Categories", ""]

        for category in sorted(categories.keys()):
            lines.append(f"## {category}")
            total = sum(categories[category].values())
            lines.append(f"**Total**: {total}")

            for outcome, count in sorted(categories[category].items()):
                lines.append(f"- {outcome}: {count}")
            lines.append("")

        return "\n".join(lines)

    except Exception as e:
        return f"Error: Failed to list categories - {type(e).__name__}: {str(e)}"


# ─────────────────────────────────────────────────────────────────
# Main Entry Point
# ─────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    mcp.run()
