# Supervisor Pattern

Most widely adopted multi-agent coordination pattern in production systems.

## Definition

Central coordinator agent routes tasks to specialized worker agents and aggregates results.

## Production Examples

| System | Use Case | Source |
|--------|----------|--------|
| Databricks | Enterprise AI at scale | [Multi-Agent Supervisor Architecture](https://www.databricks.com/blog/multi-agent-supervisor-architecture-orchestrating-enterprise-ai-scale) |
| AWS Agent Squad | Complex customer support | [Supervisor Agent Documentation](https://awslabs.github.io/agent-squad/agents/built-in/supervisor-agent/) |
| Azure | Multi-agent AI systems | [AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns) |
| LangGraph | Hierarchical intelligence | [Building Supervisor Multi-Agent Systems](https://medium.com/@mnai0377/building-a-supervisor-multi-agent-system-with-langgraph-hierarchical-intelligence-in-action-3e9765af181c) |
| Kore.ai | Pattern selection guidance | [Choosing Right Orchestration Pattern](https://www.kore.ai/blog/choosing-the-right-orchestration-pattern-for-multi-agent-systems) |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  SUPERVISOR AGENT (Coordinator)                             │
│  ├── Task analysis                                          │
│  ├── Agent selection (routes to workers)                    │
│  ├── Result aggregation                                     │
│  └── Quality gate enforcement                               │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │ WORKER 1 │         │ WORKER 2 │         │ WORKER 3 │
    │ (Code)   │         │ (Test)   │         │ (Verify) │
    └──────────┘         └──────────┘         └──────────┘
```

## Key Responsibilities

| Responsibility | Implementation |
|----------------|----------------|
| Task routing | Match task to worker by capability |
| Handoff coordination | Explicit agent-to-agent control transfer |
| State management | Track progress across workers |
| Quality gates | Block invalid state transitions |
| Error recovery | Retry logic or alternative routing |

## Production Lessons

- **Supervisor maintains global context** (workers are stateless)
- **Routing logic is declarative** (config-driven, not prompt-based)
- **Quality gates prevent cascading failures**
- **Explicit handoffs eliminate ambiguity**

## Routing Logic Example

```python
def route_task(task, workers):
    """Supervisor routing logic"""
    if task.type == "implement_feature":
        return workers["coding-agent"]
    elif task.type == "validate_feature":
        return workers["tester-agent"]
    elif task.type == "verify_quality":
        return workers["verifier-agent"]
    else:
        return workers["default-agent"]
```

## Command Object for Handoff

```json
{
  "command": {
    "agent": "tester-agent",
    "task": "validate_feature",
    "context": {
      "feature_id": "PT-003",
      "files_changed": ["src/feature.py"],
      "previous_state": "coding"
    },
    "success_criteria": {
      "tests_pass": true,
      "coverage_min": 80
    },
    "next_agent": "main"
  }
}
```

## When to Use Supervisor Pattern

| Use Case | Fit |
|----------|-----|
| Centralized control needed | ✅ Ideal |
| Specialized workers | ✅ Ideal |
| Quality gates required | ✅ Ideal |
| Fully autonomous agents needed | ❌ Consider event-driven |
| Highly dynamic workflows | ❌ Consider state machine |

## Alternatives

| Pattern | Use Instead When |
|---------|-----------------|
| State Machine | Transitions are complex and branching |
| Blackboard | Agents need loose coupling |
| Event-Driven | Distributed across services |
| Sequential Handoff | Simple linear workflows |
