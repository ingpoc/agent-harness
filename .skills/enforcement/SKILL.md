---
name: enforcement
description: Hook patterns for runtime action validation. Use when implementing quality gates, blocking invalid actions, or enforcing agent behavior. Includes: exit code 2 blocking, JSON permission denial, Spotify verification loops.
---

# Enforcement Skill

Runtime mechanisms that block invalid actions rather than just warning about them.

## When to Use This Skill

Load this skill when you need to:
- Implement hooks that BLOCK invalid actions
- Create quality gates for state transitions
- Enforce tested:true verification
- Prevent agents from ignoring rules
- Design verification loops (Spotify pattern)

## Key Insight

> **Rules are instructions, not enforcements. Systems need verification gates, not more documentation.**

Hooks CAN block actions through:
- Exit code 2 + stderr
- JSON `"permissionDecision": "deny"`
- `updatedInput` parameter modification

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| `blocking-hooks.md` | Implementing hook mechanisms | PreToolUse, SubagentStop, exit code 2, JSON deny |
| `quality-gates.md` | Designing verification loops | Spotify pattern, tested:true gates |
| `hook-templates.md` | Writing hook code | Python hook examples for common patterns |

## Hook Timing Points

| Event | Can Block? | Use Case |
|-------|------------|----------|
| **PreToolUse** | ✅ Yes | Block writes, validate state changes |
| **PermissionRequest** | ✅ Yes | Custom approval logic |
| **Stop/SubagentStop** | ✅ Yes | Force continuation until quality gates pass |
| **PostToolUse** | ❌ No | Feedback only (tool already ran) |

## Blocking Mechanisms

| Mechanism | How | Effect |
|-----------|-----|--------|
| **Exit code 2** | `exit 2` + stderr message | Blocks action, feeds stderr to Claude |
| **JSON decision** | `"permissionDecision": "deny"` | Structured blocking with reason |
| **Parameter modification** | `updatedInput` field (v2.0.10+) | Modify tool params before execution |
| **Stop blocking** | `"decision": "block"` on Stop hook | Forces agent to continue working |

## Quick Example: Block tested:true Without Evidence

```python
#!/usr/bin/env python3
# .claude/hooks/block-tested-true.py

import json
import sys
import os

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
content = tool_input.get("content", "")

# Check if marking tested:true
if '"tested": true' in content:
    evidence_dir = "/tmp/test-evidence"
    has_evidence = os.path.exists(evidence_dir) and os.listdir(evidence_dir)

    if not has_evidence:
        print("BLOCKED: Cannot mark tested without evidence", file=sys.stderr)
        sys.exit(2)  # Exit 2 = blocking error

sys.exit(0)
```

## Common Enforcement Hooks

| Hook | Event | Trigger | Action |
|------|-------|---------|--------|
| `block-tested-true.py` | PreToolUse | Write with tested:true | Verify evidence exists |
| `force-tester-completion.py` | SubagentStop | tester tries to stop | Block until tests pass |
| `enforce-mcp-logs.py` | PreToolUse | Read() on large log file | Deny, suggest MCP |
| `block-direct-edit.py` | PreToolUse | Opus edits src/ directly | Deny, suggest coding-agent |

## Sources

- Claude Code hooks documentation
- Anthropic: Multi-Agent Research System (enforcement hooks)
- Spotify Engineering: Verification loops with veto power
