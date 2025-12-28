# Context Compression Patterns

## When to Compress

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Context capacity | > 80% | Immediate compression |
| Tool output | > 5K tokens | Summarize before adding |
| State transition | After TEST | Clear test artifacts |
| Session duration | > 30 min active | Proactive compression |

## Compression Strategy

From [Cognition AI](https://cognition.ai/blog/dont-build-multi-agents):

> "Introduce a specialized compression model that distills conversation history into key details, events, and decisions."

### What to Preserve

| Category | Examples | Priority |
|----------|----------|----------|
| **Decisions** | Architecture choices, API design | Critical |
| **Current state** | Active feature, test status | Critical |
| **Recent files** | Last 5 files modified | High |
| **Unresolved issues** | Bugs, blockers, TODOs | High |
| **User preferences** | Stated requirements | Medium |

### What to Discard

| Category | Examples | When |
|----------|----------|------|
| **Raw tool output** | Full file contents | After processed |
| **Verbose logs** | Build output, stack traces | After analyzed |
| **Historical context** | Old conversations | After summarized |
| **Redundant reads** | Same file read multiple times | Keep latest |
| **Failed attempts** | Code that didn't work | After lesson extracted |

## Compression Prompt

```markdown
Compress the conversation to essential context:

## Required Output (target: 2000 tokens)

### Current State
- State: [INIT/IMPLEMENT/TEST/COMPLETE]
- Feature: [ID and description]
- Progress: [What's done, what remains]

### Key Decisions Made
1. [Decision 1 with rationale]
2. [Decision 2 with rationale]

### Files Recently Modified
- [file1.py] - [what was changed]
- [file2.py] - [what was changed]

### Unresolved Issues
- [ ] [Issue 1]
- [ ] [Issue 2]

### Next Action
[Specific next step]

## Discard
- Raw file contents (reference by path instead)
- Build/test output (keep only summary)
- Superseded attempts
- Verbose explanations
```

## Progressive Compression

```
Level 1 (80% capacity): Remove raw tool outputs
Level 2 (85% capacity): Summarize historical context
Level 3 (90% capacity): Full compression to 2K tokens
Level 4 (95% capacity): Emergency - preserve only current state
```

## Implementation

```python
def should_compress(context_usage: float) -> str:
    if context_usage > 0.95:
        return "emergency"
    elif context_usage > 0.90:
        return "full"
    elif context_usage > 0.85:
        return "summarize"
    elif context_usage > 0.80:
        return "remove_raw"
    return None

def compress_context(level: str) -> str:
    if level == "remove_raw":
        # Remove raw tool outputs, keep summaries
        return remove_raw_outputs(context)

    elif level == "summarize":
        # Summarize old conversations
        return summarize_history(context, keep_recent=5)

    elif level == "full":
        # Full compression to 2K tokens
        return llm_compress(context, target_tokens=2000)

    elif level == "emergency":
        # Preserve only current state
        return extract_current_state(context)
```

## Compression Verification

After compression, verify essential context preserved:

```python
def verify_compression(compressed: str) -> bool:
    required = [
        "Current State",
        "Feature",
        "Next Action"
    ]
    return all(r in compressed for r in required)
```

## State-Specific Compression

| State | Preserve | Discard |
|-------|----------|---------|
| INIT | Feature list, project structure | Setup logs |
| IMPLEMENT | Current feature, file changes | Previous features |
| TEST | Test results, failures | Passing test output |
| COMPLETE | Summary, blockers | All intermediate |

## Token Budget Allocation

```
Total Context: 100K tokens

Reserved:
- System prompt: 5K
- Orchestrator: 2K
- Current skill: 2K
- Tools: 5K (with defer_loading)
- Safety buffer: 10K

Available for work: 76K tokens
Compression trigger: 60K tokens (80% of available)
```
