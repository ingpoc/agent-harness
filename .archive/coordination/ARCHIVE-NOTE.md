# Archived: 2025-12-28

## Reason

Replaced by single orchestrator pattern per expert consensus:

> "Actions carry implicit decisions, and conflicting decisions carry bad results" - Cognition

## What Replaced It

| Old Pattern | New Pattern |
|-------------|-------------|
| Multi-agent coordination | Single orchestrator + skills |
| Agent handoffs | State machine transitions |
| Supervisor pattern | Enforcement hooks |

## Still Relevant

Some patterns remain useful in `.skills/orchestrator/`:
- Session handoffs → `session-management.md`
- State transitions → `state-machine.md`
- Anti-patterns → integrated into enforcement hooks

## Reference

See DESIGN-v2.md for full architecture rationale.
