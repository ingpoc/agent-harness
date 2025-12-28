---
name: coordination
description: Multi-agent coordination patterns from production systems (Databricks, AWS, Azure). Use when designing agent handoffs, state machines, or supervision. Includes: supervisor pattern, explicit orchestration, quality gates, anti-patterns.
---

# Multi-Agent Coordination Skill

Production-tested patterns for coordinating multiple AI agents.

## When to Use This Skill

Load this skill when you need to:
- Design multi-agent system architecture
- Implement agent handoff protocols
- Create state machine orchestration
- Avoid common coordination anti-patterns
- Choose between coordination patterns (supervisor, blackboard, event-driven)

## Key Finding

> **Explicit orchestration beats autonomous agent interaction.**

All production systems use structured coordination mechanisms rather than letting agents coordinate freely.

## Core Patterns

| Pattern | Best For | Production Example |
|---------|----------|-------------------|
| **Supervisor** | Centralized routing to specialists | Databricks, AWS, Azure |
| **State Machine** | Explicit transitions with guards | Anthropic Long-Running Harness |
| **Sequential Handoff** | Defined agent sequences | LangGraph, AutoGen |
| **Blackboard** | Loose coupling via shared state | LLM Multi-Agent Systems |
| **Event-Driven** | Distributed systems | Confluent Kafka systems |

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| `supervisor-pattern.md` | Designing centralized coordination | Databricks-style supervisor architecture |
| `handoffs.md` | Implementing agent-to-agent control transfer | Command objects, state transitions |
| `anti-patterns.md` | Avoiding common failures | 10 anti-patterns with solutions |
| `production-systems.md` | Learning from real deployments | Databricks, AWS, Azure, Anthropic case studies |

## Core Principles

| Principle | Explanation |
|-----------|-------------|
| **Explicit > Implicit** | State machines beat free-form coordination |
| **Centralized > Decentralized** | Supervisor pattern beats autonomous chaos |
| **Enforcement > Rules** | Hooks that block beat instructions |
| **Verification > Trust** | Quality gates prevent cascading failures |

## Quick Reference: Supervisor Pattern

```
┌─────────────────────────────────────────┐
│  SUPERVISOR (Coordinator)               │
│  ├── Task analysis                      │
│  ├── Agent selection (routes to workers)│
│  ├── Result aggregation                 │
│  └── Quality gate enforcement           │
└─────────────────────────────────────────┘
           │              │              │
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ WORKER 1 │   │ WORKER 2 │   │ WORKER 3 │
    │ (Code)   │   │ (Test)   │   │ (Verify) │
    └──────────┘   └──────────┘   └──────────┘
```

## Sources

- 40+ sources: Academic papers (2024-2025), engineering blogs
- Production systems: Databricks, AWS, Azure, Anthropic, LangGraph, AutoGen
- Anti-pattern research: Maxim.ai, Galileo, Orq.ai
