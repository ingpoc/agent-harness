# Context Graph Research Notes

## 1. Foundation: Context Graphs

Source: [Foundation Capital](https://foundationcapital.com/context-graphs-ais-trillion-dollar-opportunity/)

| Concept | Description |
|---------|-------------|
| Core idea | Living record of decision traces across entities + time, making precedent searchable |
| Rules vs Traces | Rules = general behavior; Traces = specific instances with approvals, exceptions, reasoning |
| Why it matters | Agents encounter same ambiguity humans resolve - need organizational precedent to learn from |

### Technical Architecture

| Component | Function |
|-----------|----------|
| Decision event emission | Capture inputs, policies evaluated, exceptions, approvals, state changes |
| Entity-time linkage | Connect business entities with temporal sequences for searchable lineage |
| Cross-system synthesis | Orchestration layer sees full context before decisions |

**Key Advantage**: Systems that sit "in the orchestration path" capture at decision time vs after-the-fact ETL.

### Implementation Approaches

1. Replace at scale - Rebuild systems as agentic-native with event-sourced state
2. Module replacement - Target exception-heavy subworkflows
3. New system of record - Start as orchestration, persist decision lineage until graph becomes authoritative

**Compounding Effect**: Captured traces → searchable precedent → similar cases automate → decision library grows.

---

## 2. Anthropic Engineering Articles

### 2.1 Agent Skills

Source: [Anthropic - Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)

| Pattern | Description |
|---------|-------------|
| Progressive Disclosure | 3-tier: metadata (always) → SKILL.md (when relevant) → references (on demand) |
| Code Execution | Skills can include scripts for deterministic operations |
| Metadata-Driven Triggering | Name + description determines when skill activates |
| Unbounded Context | Skills can reference unlimited files, loaded only as needed |

**Key Insight**: "Like a well-organized manual that starts with a table of contents, then specific chapters, and finally a detailed appendix."

**Implication for Context Graph**: Traces could follow same pattern - metadata always visible, full trace loaded on relevance match.

### 2.2 Code Execution with MCP

Source: [Anthropic - Code Execution](https://www.anthropic.com/engineering/code-execution-with-mcp)

| Pattern | Token Savings |
|---------|---------------|
| On-demand tool loading | 98.7% (150K → 2K tokens) |
| Data filtering in sandbox | Process 10K rows, return 5 |
| search_tools with detail levels | name_only → with_description → full_schema |
| State persistence in workspace | Resume across executions |

**Key Insight**: "Tool definitions overload the context window" + "intermediate tool results consume additional tokens"

**Implication for Context Graph**: Query traces in MCP sandbox, return only summaries. Never load raw traces into context.

### 2.3 Long-Running Harness

Source: [Anthropic - Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

| Pattern | Purpose |
|---------|---------|
| Two-agent architecture | Initializer (once) + Coding (repeated) |
| Feature list as contract | JSON with passes:false, prevents premature completion |
| Progress files | claude-progress.txt + git + init.sh bridge sessions |
| Incremental work | One feature per session, explicit verification |

**Key Insight**: "JSON is preferred over Markdown because the model is less likely to inappropriately change or overwrite JSON files."

**Preventing Premature Completion**:
- Strongly-worded instructions: "It is unacceptable to remove or edit tests"
- Feature list establishes objective completion criteria
- Only update passes after careful testing

**Session Startup Ritual**:
1. Run pwd to verify directory
2. Read git logs and progress files
3. Read feature list, select incomplete item
4. Execute init.sh, run basic tests
5. Fix existing bugs before new features

---

## 3. Memory Systems Research

### 3.1 Memory Taxonomy

Source: [arXiv - Memory in the Age of AI Agents](https://arxiv.org/abs/2512.13564)

| Memory Type | Description |
|-------------|-------------|
| Factual | Storing explicit knowledge and information |
| Experiential | Retaining past interactions and experiences |
| Working | Managing current task context and intermediate states |

**Design Dimensions**: Formation → Evolution → Retrieval

### 3.2 Production Memory Patterns

| System | Approach |
|--------|----------|
| Cursor/Windsurf | Static index + vector embeddings + dependency graph |
| ByteRover/Cipher | System 1 (knowledge) + System 2 (reasoning) + Workspace |
| Mem0 | Vector store + LLM extraction (90% lower tokens) |
| Claude-mem | SQLite + Chroma, auto-capture + summarization |
| Strands Agents | STM + LTM strategies (summary, preference, semantic) |

**Key Pattern**: 3-tier architecture
- Tier 1: Hot context (in-window, ~10K tokens)
- Tier 2: Warm memory (vector search, on-demand)
- Tier 3: Cold storage (full traces, never direct load)

### 3.3 Storage Options Evaluated

| Option | Semantic Search | Setup | MCP Native |
|--------|-----------------|-------|------------|
| Qdrant Local | Best | Medium | Official |
| sqlite-vec | Good | Low | Community (Memento) |
| Cipher | Good | Medium | Yes |
| File-based | Text only | Zero | N/A |

**Recommendation**: Qdrant Local or sqlite-vec embedded in token-efficient MCP server.

---

## 4. Key Problems Identified

### 4.1 Rules vs Enforcement

| Current State | Problem |
|---------------|---------|
| 500+ lines of MUST/NEVER/CRITICAL | Claude can ignore instructions |
| "Never mark tested:true if empty" | No runtime verification |
| "Use MCP for logs" | No detection of violation |

**Core Issue**: Rules are instructions, not enforcements.

### 4.2 Manual Triggering

| Current State | Problem |
|---------------|---------|
| User says "test this" | Reactive, not proactive |
| User says "continue" | Orchestrator doesn't auto-select |
| User forces tool usage | Agent doesn't self-introspect |

**Core Issue**: User has to drive the system.

### 4.3 Premature Completion

| Symptom | Root Cause |
|---------|------------|
| tested:true with empty data | No verification gate |
| Feature "complete" without testing | Subagent can write any status |
| Skipped steps | No enforcement of workflow |

**Core Issue**: State transitions are not verified.

### 4.4 No Learning Loop

| Current State | Problem |
|---------------|---------|
| Mistakes repeat across sessions | No persistence of corrections |
| CLAUDE.md rules grow unbounded | No relevance filtering |
| Same errors in similar contexts | No pattern matching |

**Core Issue**: No feedback loop from corrections to behavior.

---

## 5. Proposed Three-Layer Architecture

```
LAYER 1: ORCHESTRATION
├── Main agent auto-selects next action
├── State machine: init → code → test → next
├── No user prompting needed
└── Proactive spawning based on context

LAYER 2: ENFORCEMENT
├── Hooks that BLOCK invalid transitions
├── tested:true requires verification gate
├── Tool usage validated (MCP for logs)
└── Subagents cannot bypass guards

LAYER 3: LEARNING (Context Graph)
├── Capture when enforcement triggers
├── Store corrections with embeddings
├── Query before decisions
├── Extract patterns from violations
└── Feed back into prompts + guards
```

### Layer Integration

```
Enforcement triggers → Trace captured → Pattern extracted → New guard created
                                                                    ↓
                                            Agent queries traces → Acts with precedent
```

---

## 6. Research Questions

### 6.1 Runtime Guards ✅ RESOLVED

**Question**: Can hooks BLOCK actions, not just log?

**Answer**: YES - Two mechanisms:

| Mechanism | How | Effect |
|-----------|-----|--------|
| Exit code 2 | `exit 2` + stderr | Blocks action, stderr fed to Claude |
| JSON decision | `"permissionDecision": "deny"` | Structured blocking with reason |
| Parameter mod | `updatedInput` (v2.0.10+) | Modify tool params before execution |

**Blocking events**: PreToolUse ✅, PermissionRequest ✅, Stop ✅, SubagentStop ✅, PostToolUse ❌

### 6.2 Auto-Orchestration

**Question**: Can main agent auto-detect next action?

| Trigger | Auto-Action |
|---------|-------------|
| Implementation complete | Spawn tester |
| Test failed | Resume coding with context |
| Session start | Detect state, spawn appropriate agent |

**Approach**: State machine in orchestrator prompt + feature-list status.

### 6.3 Verified Completion ✅ RESOLVED

**Question**: Can tested:true be gated?

**Answer**: YES - PreToolUse hook blocks Write/Edit with tested:true without evidence.

| Implementation | Mechanism |
|----------------|-----------|
| `block-tested-true.py` | PreToolUse hook checks for evidence in /tmp/test-evidence/ |
| Exit code 2 | Blocks write, feeds error to Claude |
| Evidence required | Test logs, screenshots, or API responses |

**Implementation pattern**:
```python
if '"tested": true' in content and not evidence_exists():
    print("BLOCKED: Cannot mark feature as tested without evidence", file=sys.stderr)
    sys.exit(2)
```

### 6.4 Subagent Identification ✅ RESOLVED

**Question**: Can hooks identify which agent is stopping?

**Answer**: NO direct field in SubagentStop input. Must use state file handshake.

| SubagentStop Input Fields | Missing |
|---------------------------|---------|
| session_id, transcript_path, permission_mode, stop_hook_active | agent_id, agent_name, agent_type |

**Workaround: State file handshake**
```python
# Agent writes on start: /tmp/active-agent.json = {"agent": "tester-agent", ...}
# Hook reads: Only enforce if agent == "tester-agent"
```

**Agent prompt requirement**:
```markdown
On Start: echo '{"agent": "tester-agent"}' > /tmp/active-agent.json
```

### 6.5 Dynamic Skill Loading

**Question**: Can skills self-activate by context?

| Current | Needed |
|---------|--------|
| skills: [list] in config | Detect task → load skill |
| All skills available | Progressive discovery |

**Approach**: Skill metadata triggers like agent descriptions.

### 6.6 Learning → Enforcement

**Question**: Can traces create new guards?

| Flow | Example |
|------|---------|
| Trace: "ignored empty-data rule 3x" | → Pattern: "agent ignores this rule" |
| Pattern extracted | → Guard: hook blocks tested:true if empty |

**Approach**: Pattern extraction → hook generation → auto-deployment.

### 6.7 Agent Introspection

**Question**: Can agent ask "am I using right tool?"

| Scenario | Introspection |
|----------|---------------|
| About to Read(log.txt) | "Should I use MCP instead?" |
| About to mark tested:true | "Did I verify non-empty data?" |

**Approach**: Pre-action checklist in agent prompt + query traces for similar mistakes.

---

## 7. Correction Detection Signals

| User Behavior | Signal | Action |
|---------------|--------|--------|
| "Yes, looks good" | Approval | Reinforce pattern (optional) |
| "No, do X instead" | Correction | Store as trace |
| User edits code directly | Implicit correction | Diff = trace |
| Abandons, restarts | Rejection | Store as anti-pattern |
| Asks same question twice | Confusion | Context gap signal |

---

## 8. Token Economics

| Operation | Cost | ROI |
|-----------|------|-----|
| Store trace | ~50 tokens | Foundation |
| Query traces | ~100 tokens | Prevention |
| Load summaries (top 3) | ~600 tokens | Context |
| **Total per decision** | ~700 tokens | - |
| **Rework cycle saved** | ~9,000 tokens | 12x ROI |

---

## 9. Sources

| Article | Key Insight |
|---------|-------------|
| [Context Graphs](https://foundationcapital.com/context-graphs-ais-trillion-dollar-opportunity/) | Decision traces = trillion-dollar layer |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Progressive disclosure, code execution |
| [Code Execution MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) | 98.7% token savings via sandbox |
| [Long-Running Harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Feature list, session continuity |
| [Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Smallest high-signal token set |
| [Memory Survey](https://arxiv.org/abs/2512.13564) | Factual, experiential, working memory |
| [ByteRover Cipher](https://github.com/campfirein/cipher) | System 1/2 memory for coding agents |
| [Qdrant MCP](https://github.com/qdrant/mcp-server-qdrant) | Official semantic memory server |

---

*Last Updated: 2025-12-28*
*Status: Hook Research Complete - Ready for Implementation*
*Resolved: Runtime guards (6.1), Verified completion (6.3), Subagent ID (6.4)*
