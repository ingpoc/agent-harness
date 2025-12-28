# Multi-Agent Coordination Anti-Patterns

Common failure modes and their solutions.

## Top 10 Anti-Patterns

| Anti-Pattern | Description | Why It Fails | Solution |
|--------------|-------------|--------------|----------|
| **No-op Loops** | Agents repeat work without progress | No progress tracking | State machine with progress counters |
| **Machine Ghosting** | Agent appears to work but produces no output | Lack of verification | Output validation before state transition |
| **Quality Drift** | Standards gradually degrade | No enforcement, only rules | Runtime guards (hooks that block) |
| **State Explosion** | Too many agents managing overlapping state | Unclear ownership | Clear state partitioning |
| **Coordination Deadlock** | Agents waiting on each other indefinitely | Circular dependencies | Timeouts, clear state machine |
| **Cascading Failures** | One agent's bad output breaks pipeline | No quality gates | Guards at each transition |
| **Lost Context** | Handoffs lack information | Implicit state transfer | Explicit command objects |
| **Premature Completion** | Feature marked done without testing | No verification gate | Block tested:true without evidence |
| **Orchestration Gaps** | Unclear who does what next | Manual prompting | Auto-orchestration via state machine |
| **Autonomous Chaos** | Agents coordinate freely without structure | Emergent behavior is fragile | Explicit orchestration (supervisor) |

---

## Detailed Analysis

### 1. No-Op Loops

**Symptom**: Agents repeat the same actions without making progress.

**Root Cause**: No progress tracking or loop detection.

**Solution**:
```python
# Add progress counter to state
state = {
    "agent": "coding-agent",
    "feature": "PT-003",
    "attempts": 0,
    "last_files_written": []
}

# Detect no-op: same files, no progress
if state["last_files_written"] == current_files:
    state["attempts"] += 1
    if state["attempts"] > 3:
        escalate_to_human("No progress detected")
```

### 2. Machine Ghosting

**Symptom**: Agent appears active but produces no output.

**Root Cause**: Lack of output verification before state transition.

**Solution**:
```python
def verify_output_before_transition(agent, state):
    """Require non-empty output before state change"""
    if state == "complete" and not has_artifacts():
        raise ValueError("Cannot complete without artifacts")
    return True
```

### 3. Quality Drift

**Symptom**: Standards gradually degrade over time.

**Root Cause**: Rules are instructions, not enforcements.

**Solution**: Runtime guards that block invalid actions.
```python
# Hook that blocks degradation
if coverage < previous_coverage - 10:
    sys.exit(2)  # Block action
```

### 4. State Explosion

**Symptom**: Too many agents managing overlapping state.

**Root Cause**: Unclear state ownership.

**Solution**: Partition state by domain, clear ownership.
```python
# Clear state ownership
state_ownership = {
    "feature_list": "supervisor",
    "test_results": "tester-agent",
    "code_artifacts": "coding-agent"
}
```

### 5. Coordination Deadlock

**Symptom**: Agents waiting on each other indefinitely.

**Root Cause**: Circular dependencies without timeouts.

**Solution**:
```python
# Add timeouts to all agent calls
result = run_agent_with_timeout(
    agent="tester-agent",
    timeout=300,  # 5 minutes
    on_timeout="escalate"
)
```

### 6. Cascading Failures

**Symptom**: One agent's bad output breaks the pipeline.

**Root Cause**: No quality gates between transitions.

**Solution**: Guards at each transition.
```python
def can_transition(from_state, to_state):
    guards = {
        ("coding", "testing"): lambda: tests_pass(),
        ("testing", "production"): lambda: coverage_min(80)
    }
    return guards[(from_state, to_state)]()
```

### 7. Lost Context

**Symptom**: Next agent lacks information from previous.

**Root Cause**: Implicit state transfer.

**Solution**: Explicit command objects.
```json
{
  "command": {
    "context": {
      "feature_id": "PT-003",
      "files_changed": ["src/feature.py"],
      "previous_state": "coding"
    }
  }
}
```

### 8. Premature Completion

**Symptom**: Feature marked done without testing.

**Root Cause**: No verification gate for tested:true.

**Solution**: Block tested:true without evidence.
```python
if '"tested": true' in content and not evidence_exists():
    print("BLOCKED: Cannot mark tested without evidence", file=sys.stderr)
    sys.exit(2)
```

### 9. Orchestration Gaps

**Symptom**: Unclear who does what next.

**Root Cause**: Manual prompting required.

**Solution**: Auto-orchestration via state machine.
```python
state_transitions = {
    "coding_complete": "spawn_tester",
    "tests_pass": "next_feature",
    "tests_fail": "resume_coding"
}
```

### 10. Autonomous Chaos

**Symptom**: Agents coordinate freely, behavior is unpredictable.

**Root Cause**: No explicit orchestration structure.

**Solution**: Supervisor pattern with explicit routing.
```python
def supervisor_route(task):
    if task.type == "code":
        return "coding-agent"
    elif task.type == "test":
        return "tester-agent"
```

---

## Key Principle

> **Coordination complexity often outweighs multi-agent benefits.**

Production systems use structured, explicit orchestration rather than emergent agent behavior.

## Prevention Checklist

- [ ] Progress tracking (prevent no-op loops)
- [ ] Output verification (prevent ghosting)
- [ ] Runtime guards (prevent quality drift)
- [ ] Clear state ownership (prevent state explosion)
- [ ] Timeouts (prevent deadlocks)
- [ ] Quality gates (prevent cascading failures)
- [ ] Explicit context (prevent lost context)
- [ ] Verification gates (prevent premature completion)
- [ ] Auto-orchestration (prevent orchestration gaps)
- [ ] Explicit coordination (prevent autonomous chaos)

## Sources

- [Maxim.ai](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/)
- [Galileo](https://galileo.ai/blog/multi-agent-ai-failures-prevention)
- [Tactical Edge AI](https://www.tacticaledgeai.com/blog/why-multi-agent-systems-fail-before-production)
- [Orq.ai](https://orq.ai/blog/why-do-multi-agent-llm-systems-fail)
