# Agent Handoff Protocols

Explicit protocols for transferring control between agents.

## Handoff Types

| Type | Description | Complexity |
|------|-------------|------------|
| **Sequential** | A→B→C→D (linear) | Low |
| **Branching** | A→(B or C) based on condition | Medium |
| **Parallel** | A→(B, C, D) then aggregate | High |
| **Dynamic** | Handoff determined at runtime | High |

## Handoff Protocol Elements

| Element | Description | Example |
|---------|-------------|---------|
| **Precondition** | What must be complete | Code written, linted |
| **Artifacts** | What's passed along | File paths, test results |
| **Postcondition** | What next agent expects | Ready-to-test state |
| **Rollback** | How to handle failures | Return to previous state |

## Command Object Schema

```json
{
  "handoff": {
    "from": "coding-agent",
    "to": "tester-agent",
    "preconditions": {
      "files_written": ["src/feature.py"],
      "local_tests_pass": true
    },
    "artifacts": {
      "feature_files": ["src/feature.py"],
      "test_evidence": "/tmp/test-output/"
    },
    "rollback_on": "test_failure",
    "rollback_state": "coding"
  }
}
```

## Best Practices

| Practice | Implementation |
|----------|----------------|
| **Explicit context** | Pass command object, not implicit state |
| **Verification** | Next agent validates preconditions |
| **Idempotency** | Handoff safe to retry |
| **Observability** | Log every handoff with context |
| **Timeout** | Fail fast if agent unresponsive |

## Handoff Example: Coding → Testing

```
CODING AGENT completes implementation
    │
    │ Preconditions:
    │ - Code written to src/feature.py
    │ - Local tests pass
    │ - No linting errors
    │
    ▼
SUPERVISOR validates preconditions
    │
    │ Pass artifacts:
    │ - feature_files: ["src/feature.py"]
    │ - commit_hash: "abc123"
    │
    ▼
TESTER AGENT receives command
    │
    │ Validates:
    │ - Files exist
    │ - Local tests pass
    │
    ▼
TESTING EXECUTES
    │
    │ On failure: Rollback to CODING
    │ On success: Handoff to next
    │
    ▼
COMPLETE
```

## Handoff Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| **Lost context** | Next agent lacks information | Explicit command objects |
| **Ghost handoff** | Agent claims work complete, but isn't | Quality gates before handoff |
| **Handoff loop** | A→B→A repeatedly | State machine with guards |
| **Orphaned work** | Agent finishes, no one knows | Central coordinator tracks state |

## Implementation Pattern

```python
def handoff(from_agent, to_agent, context):
    """Execute handoff with validation"""

    # Verify preconditions
    if not validate_preconditions(context, to_agent):
        return rollback(from_agent, "Preconditions failed")

    # Log handoff
    log_handoff(from_agent, to_agent, context)

    # Pass command
    command = {
        "agent": to_agent,
        "task": context["task"],
        "context": context["artifacts"],
        "rollback_on": context["failure_mode"],
        "rollback_state": from_agent
    }

    return execute_agent(to_agent, command)
```

## State Machine Handoff Guards

```python
def can_handoff(from_state, to_state, context):
    """Guard conditions for state transitions"""

    guards = {
        ("coding", "testing"): lambda: implementation_complete() and local_tests_pass(),
        ("testing", "verifying"): lambda: all_tests_pass() and has_test_evidence(),
        ("testing", "coding"): lambda: tests_failed() and retry_count < 2,
    }

    return guards[(from_state, to_state)]()
```

## Communication Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Request-Response** | Agent A sends request, waits for reply | Synchronous queries |
| **Fire-and-Forget** | Agent A sends message, continues | Asynchronous updates |
| **Shared State** | Feature list, blackboard | Progress tracking |
| **Command Objects** | Explicit context passing | Handoffs |
