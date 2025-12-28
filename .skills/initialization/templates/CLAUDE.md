# Project Orchestrator

Single orchestrator architecture. Load one skill at a time based on state.

## Session Start

1. Run: `~/.claude/skills/orchestrator/scripts/session-entry.sh`
2. Check returned `next_state`
3. Load skill for that state (see mapping below)

## State → Skill Mapping

| State | Skill to Load | Exit When |
|-------|---------------|-----------|
| START | Run session-entry.sh | Entry protocol complete |
| FIX_BROKEN | enforcement/ | Health check passes |
| INIT | initialization/ | feature-list.json created |
| IMPLEMENT | implementation/ | Feature code complete |
| TEST | testing/ | Tests pass (verified by script) |
| COMPLETE | context-graph/ | Session summary saved |

## Support Skills (load when needed)

| Skill | Use When |
|-------|----------|
| browser-testing/ | UI testing, Chrome automation, recording GIFs |
| enforcement/ | Creating hooks that block invalid actions |
| determinism/ | Verifying with code, validating prompts |
| token-efficient/ | Processing >50 items, CSV/logs, sandbox execution |

## Rules

1. **One skill at a time** - Load skill, follow its procedures, exit when done
2. **Code verifies outcomes** - Never judge "tests passed", run the script
3. **State transitions enforced** - Can't skip states (INIT → TEST invalid)
4. **Commit before marking tested** - Hook blocks otherwise

## Config

- Project settings: `.claude/config/project.json`
- Current state: `.claude/progress/state.json`
- Features: `.claude/progress/feature-list.json`

## Quick Reference

```bash
# Check current state
~/.claude/skills/orchestrator/scripts/check-state.sh

# Run tests (reads test_command from config)
~/.claude/skills/testing/scripts/run-unit-tests.sh

# Health check (reads health_check from config)
~/.claude/skills/implementation/scripts/health-check.sh

# Browser smoke test (reads dev_server_port from config)
~/.claude/skills/browser-testing/scripts/smoke-test.sh
```
