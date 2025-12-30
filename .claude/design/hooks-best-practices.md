# Hooks Best Practices - DESIGN-v2

## Sources

- Claude Code Hooks Guide (official documentation)
- Claude Cookbooks (examples and patterns)
- DESIGN-v2.md (requirements)

---

## 1. When to Use Hooks vs Other Approaches

| Use Case | Hook Type | Why Not Skills/CLAUDE.md? |
|----------|-----------|---------------------------|
| **Block invalid actions** | PreToolUse (exit 2) | Skills can't block - they're instructions only |
| **Enforce quality gates** | Stop/SubagentStop | Documentation can be ignored |
| **Validate before execution** | PreToolUse | Skills are post-hoc, hooks are pre-action |
| **React to results** | PostToolUse | Skills have no access to tool results |
| **Session initialization** | SessionStart | CLAUDE.md is static only |

**Key principle:** Rules (CLAUDE.md, skills) = instructions. Hooks = enforcement.

---

## 2. Hook Types (Claude Code)

| Event | Blocks? | Use Case | Output Format |
|-------|---------|----------|---------------|
| **PreToolUse** | Yes (exit 2) | Validate before action | `{permissionDecision: deny\|ask\|allow}` |
| **PostToolUse** | No | Logging, feedback | stdout shown, stderr to Claude |
| **Stop** | Yes (decision:block) | Force continuation before stop | `{decision: "block", reason: "..."}` |
| **SubagentStop** | Yes | Agent-specific quality gates | `{decision: "block", reason: "..."}` |
| **UserPromptSubmit** | No | Add context to prompts | systemMessage |
| **SessionStart** | No | Load context, set env vars | Persist via `$CLAUDE_ENV_FILE` |
| **SessionEnd** | No | Cleanup, checkpoint | - |

**For DESIGN-v2:**
- PreToolUse for state transitions, test verification
- SessionStart for entry protocol (if supported)
- SessionEnd for checkpoint commits

---

## 3. Creating Blocking Hooks

### Method 1: Exit Code 2 (Standard for PreToolUse)

```bash
#!/bin/bash
set -euo pipefail
input=$(cat)

# Parse input
file_path=$(echo "$input" | jq -r '.tool_input.file_path')

# Check condition
if [[ "$file_path" == "/etc/"* ]]; then
  echo '{"permissionDecision": "deny", "reason": "System writes blocked"}' >&2
  exit 2  # BLOCKING
fi

exit 0  # Allow
```

### Method 2: JSON Decision (for Prompt Hooks)

```json
{
  "type": "prompt",
  "prompt": "Check if $TOOL_INPUT.file_path contains sensitive patterns. Return {permissionDecision: 'deny', reason: '...'} or {permissionDecision: 'allow'}"
}
```

### Method 3: Stop Decision (for Stop hooks)

```python
output = {
    "decision": "block",
    "reason": "Tests not run yet"
}
print(json.dumps(output))
```

---

## 4. DESIGN-v2 Hook Requirements

Based on DESIGN-v2.md enforcement needs:

| Hook | Event | Blocks? | Verification |
|------|-------|---------|--------------|
| `verify-state-transition.py` | PreToolUse (Write state.json) | Yes | VALID_TRANSITIONS check |
| `verify-tests.py` | PreToolUse (Write feature-list) | Yes | pytest exit code |
| `verify-files-exist.py` | PreToolUse (mark completed) | Yes | File existence check |
| `verify-health.py` | PreToolUse (mark tested) | Yes | curl health endpoint |
| `require-commit-before-tested.py` | PreToolUse (Write feature-list) | Yes | git status check |
| `require-dependencies.py` | PreToolUse (Write to src/) | Yes | Env vars, services |
| `session-entry.sh` | SessionStart | No | Safety + state + context |
| `session-end.sh` | SessionEnd | No | Checkpoint commit |

---

## 5. Common Patterns (from Cookbooks)

### Pattern 1: Path Matching with jq

```bash
file_path=$(echo "$input" | jq -r '.tool_input.file_path')
if [[ "$file_path" == *".."* ]]; then
  echo '{"permissionDecision": "deny", "reason": "Path traversal"}' >&2
  exit 2
fi
```

### Pattern 2: Content Checking

```python
content = input_data.get("tool_input", {}).get("content", "")

if '"tested": true' in content:
    # Run verification
    result = subprocess.run(["pytest", "--tb=short"], capture_output=True)
    if result.returncode != 0:
        print("BLOCKED: Tests failed", file=sys.stderr)
        sys.exit(2)
```

### Pattern 3: Matcher Configuration (settings.json)

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-write.sh"
        }
      ]
    }
  ]
}
```

---

## 6. What Hooks Should NOT Do

| Don't | Why | Alternative |
|-------|-----|-------------|
| **Modify global state unpredictably** | Breaks reproducibility | Use temp files with `$$` |
| **Rely on execution order** | Hooks run **in parallel** | Make hooks independent |
| **Block without clear reason** | User confusion | Always provide stderr message |
| **Log sensitive data** | Security risk | Hash/redact inputs |
| **Create long-running operations** | Timeout (default 60s) | Cache results |
| **Use hardcoded paths** | Not portable | Use `${CLAUDE_PROJECT_ROOT}` |
| **Forget input validation** | Injection risk | Quote variables, validate with jq |

---

## 7. Configuration Format

### Project hooks (`.claude/settings.json`)

```json
{
  "PreToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": ".claude/hooks/verify-write.sh"
        }
      ]
    }
  ],
  "SessionStart": [
    {
      "type": "command",
      "command": ".claude/hooks/session-entry.sh"
    }
  ]
}
```

### Global hooks (`~/.claude/settings.json`)

Same format, applies to all projects unless overridden.

---

## 8. Hook Input Format (stdin)

All PreToolUse hooks receive JSON via stdin:

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": ".claude/progress/state.json",
    "content": "{\"state\": \"IMPLEMENT\"}"
  },
  "request_id": "...",
  "timestamp": "..."
}
```

Parse with:
```bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path')
content=$(echo "$input" | jq -r '.tool_input.content')
```

---

## 9. Learning Layer Hooks (Context-Graph)

Based on learning-hooks.md design:

| Hook | Event | Blocks? | Purpose |
|------|-------|---------|---------|
| `require-outcome-update.py` | PreToolUse (Write feature-list) | Yes | Force outcome when marking tested |
| `remind-decision-trace.sh` | PreToolUse (Write src/) | No | Reminder to log decisions |
| `link-feature-to-trace.py` | PreToolUse (Write feature-list) | No | Auto-link feature to trace |

---

## 10. Implementation Checklist

For each hook:

- [ ] Receive stdin JSON input
- [ ] Parse with `jq` or Python `json.load()`
- [ ] Check condition (exit 0 if pass, exit 2 if fail)
- [ ] Write reason to stderr (for blocking)
- [ ] Make executable (`chmod +x`)
- [ ] Add to settings.json with matcher
- [ ] Test with valid and invalid inputs

---

*Version: 1.0*
*Based on: Claude Code Guide + Cookbooks + DESIGN-v2*
*Status: Design, not implemented*
