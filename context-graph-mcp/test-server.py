#!/usr/bin/env python3
"""
Simple test script for context-graph MCP server.
Tests basic functionality without requiring full MCP client.
"""

import asyncio
import os
import sys
import tempfile
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from server import (
    get_voyage_key,
    init_database,
    get_embedding,
    handle_db_error
)


async def test_api_key():
    """Test Voyage API key retrieval."""
    print("Testing API key retrieval...")
    try:
        key = get_voyage_key()
        print(f"✓ API key found: {key[:10]}...{key[-4:]}")
        return True
    except ValueError as e:
        print(f"⚠ API key not found: {e}")
        print("  Set VOYAGE_API_KEY environment variable to enable embedding tests")
        return None  # None = skip, not fail


async def test_database_init():
    """Test database initialization."""
    print("\nTesting database initialization...")
    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = os.path.join(tmpdir, "test.db")
        try:
            conn = init_database(db_path)

            # Check tables exist
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]

            assert "traces" in tables, "traces table missing"
            assert "trace_embeddings" in tables, "trace_embeddings table missing"

            conn.close()
            print(f"✓ Database initialized at {db_path}")
            print(f"  Tables: {tables}")
            return True
        except RuntimeError as e:
            if "enable_load_extension" in str(e):
                print(f"⚠ sqlite-vec not supported (macOS/pyenv limitation)")
                print("  Server will work with full Python build or Linux")
                return None  # Skip, not fail
            print(f"✗ Database init failed: {e}")
            return False
        except Exception as e:
            print(f"✗ Database init failed: {e}")
            return False


async def test_embedding():
    """Test Voyage embedding generation."""
    print("\nTesting embedding generation...")
    try:
        key = get_voyage_key()
        embedding = await get_embedding("Test decision text", key)

        assert isinstance(embedding, list), "Embedding should be a list"
        assert len(embedding) == 1024, f"Expected 1024 dimensions, got {len(embedding)}"
        assert all(isinstance(x, float) for x in embedding), "All values should be floats"

        print(f"✓ Embedding generated: 1024 dimensions")
        print(f"  Sample values: {embedding[:3]}")
        return True
    except Exception as e:
        print(f"✗ Embedding failed: {e}")
        return False


async def main():
    """Run all tests."""
    print("=" * 50)
    print("Context Graph MCP Server - Tests")
    print("=" * 50)

    results = []
    skipped = 0

    # Run tests
    api_result = await test_api_key()
    if api_result is None:
        skipped += 1
    else:
        results.append(api_result)

    db_result = await test_database_init()
    if db_result is None:
        skipped += 1
    else:
        results.append(db_result)

    # Only test embedding if API key is available
    try:
        get_voyage_key()
        results.append(await test_embedding())
    except ValueError:
        skipped += 1
        print("\n⊘ Skipping embedding test (no API key)")

    # Summary
    print("\n" + "=" * 50)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    if skipped > 0:
        print(f"Skipped: {skipped} tests (requires VOYAGE_API_KEY or compatible sqlite3)")
    print("=" * 50)

    # Pass if all runnable tests succeed and at least one test ran
    return passed == total and total > 0


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
