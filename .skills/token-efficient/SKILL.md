---
name: token-efficient
description: Use when processing >50 items, analyzing CSV/log files, executing code, or searching for tools. Includes: progressive disclosure (98.7% savings), in-sandbox processing (99% savings), pagination, heredoc support.
---

# Token-Efficient MCP Skill

Token-efficient tools for processing data, executing code, and finding tools - all designed to minimize token usage through on-demand loading and in-sandbox processing.

## When to Use This Skill

Load this skill when you need to:
- Process CSV files with filtering/aggregation
- Analyze log files with pattern matching
- Execute code (Python/Bash/Node) in sandbox
- Search for available tools by keyword
- Process multiple files efficiently
- Use heredoc syntax for multi-line bash scripts

## Server Info

**Version**: 1.2.0
**Heredoc Support**: Enabled (`<<EOF`, `<<'EOF'`, `<<EOT`)

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| patterns.md | Deciding which tool to use | Decision tree for tool selection |
| examples.md | Need code examples | Concrete usage patterns |

## Token Savings

| Tool | Typical Savings |
|------|-----------------|
| `execute_code` | 98%+ (code executed in sandbox) |
| `process_csv` | 99% (10K rows → 100 results) |
| `process_logs` | 95% (100K lines → 500 matches) |
| `search_tools` | 95% (vs loading all definitions) |
| `batch_process_csv` | 80% (multiple files) |

## Quick Reference

| Task | Tool | Key Feature |
|------|------|-------------|
| Filter CSV | `process_csv` | filter_expr, aggregation |
| Search logs | `process_logs` | pattern matching with offset |
| Run code | `execute_code` | Python/Bash/Node with heredocs |
| Find tools | `search_tools` | Progressive disclosure |
| Multiple CSVs | `batch_process_csv` | One call, consistent filter |

## Core Principles

1. **Progressive Disclosure** - Load tool definitions on-demand
2. **Data Filtering** - Process in sandbox, return only results
3. **Summarization** - Return summaries, not raw data
4. **Heredoc Support** - Multi-line bash scripts via `<<EOF`
5. **Caching** - Repeated calls get 90% savings
6. **Pagination** - Use offset for large files
7. **Batch Processing** - Multiple files in one call

## Response Formats

| Format | Use For |
|--------|---------|
| `summary` | Human consumption (default) |
| `json` | Programmatic processing |
| `markdown` | Formatted output |

## Sources

- Anthropic: Code Execution with MCP (progressive disclosure pattern)
- Token-efficient MCP server v1.2.0
