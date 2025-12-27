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

**Progressive Disclosure Pattern**:

> "Models are great at navigating filesystems. Presenting tools as code on a filesystem allows models to read tool definitions on-demand, rather than reading them all up-front."

**Detail Levels for search_tools**:

| Level | Content | When to Use |
|-------|---------|-------------|
| `name_only` | Just tool names | Discovery phase - what's available |
| `with_description` | Name + description | Filtering - is this relevant? |
| `full_schema` | Complete definition with schemas | Actual usage - need to call it |

**Token Impact**: 150,000 → 2,000 tokens = **98.7% savings**

**Key Insight**: "Tool definitions overload the context window" + "intermediate tool results consume additional tokens"

**Implication for Context Graph**: Apply same pattern to trace queries.

| Operation | Without Progressive Disclosure | With Progressive Disclosure |
|-----------|-------------------------------|----------------------------|
| Find similar traces | Load all 1000 traces (~50K tokens) | `query_traces(q, level="metadata")` (~500 tokens) |
| Get trace details | Load full trace | `get_trace(id, level="full")` (~2K tokens) |
| Search patterns | Load entire graph | `extract_patterns(level="summary")` (~1K tokens) |

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

### 2.4 Context Engineering

Source: [Anthropic - Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

**Definition**: The art and science of curating what goes into the limited context window from constantly evolving possible information.

**Core Principle**: Finding the **smallest possible set of high-signal tokens** that maximize desired outcomes.

> "Context, therefore, must be treated as a finite resource with diminishing marginal returns."

**Context Management Patterns**:

| Pattern | Purpose | Trade-off |
|---------|---------|-----------|
| **Just-in-time retrieval** | Load data at runtime via tools | Slower but more accurate |
| **Progressive disclosure** | Incremental discovery through exploration | Requires good tools |
| **Compaction** | Summarize + reset context window | Risk of losing subtle context |
| **Structured note-taking** | External memory, pull when needed | Minimal overhead |
| **Sub-agent architectures** | Specialized agents return distilled summaries | Coordination complexity |

**Compaction Strategy**:

| Preserve | Discard |
|----------|---------|
| Architectural decisions | Redundant tool outputs |
| Unresolved bugs | Raw results (once used) |
| Implementation details | Verbose logs |
| Recent 5 files | Historical context |

**Sub-Agent Distillation Pattern**:

> "Specialized sub-agents can handle focused tasks with clean context windows. Each subagent might explore extensively, using tens of thousands of tokens, but returns only a condensed, distilled summary (often 1,000-2,000 tokens)."

**Attention Budget**:

Every token depletes attention budget; n² pairwise relationships for n tokens creates "context rot."

**Decision Framework**:

| Use This When | Pattern |
|---------------|---------|
| Extensive back-and-forth required | Compaction |
| Iterative development with milestones | Note-taking |
| Complex research/analysis with parallel exploration | Multi-agent |

**Key Quote**:

> "As models become more capable, the challenge isn't just crafting the perfect prompt—it's thoughtfully curating what information enters the model's limited attention budget at each step."

**Implication for Context Graph**:

- Store only high-signal traces (not every interaction)
- Use progressive disclosure for retrieval (metadata → summary → full)
- Apply compaction when context approaches limits
- Sub-agents return distilled summaries, not full context

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

### 3.4 Learning Loop Patterns

Sources: [Reflexion Paper (NeurIPS 2023)](https://arxiv.org/abs/2303.11366), [Spotify Engineering](https://engineering.atspotify.com/2025/12/feedback-loops-background-coding-agents-part-3), [OODA Loop Analysis](https://tao-hpu.medium.com/agent-feedback-loops-from-ooda-to-self-reflection-92eb9dd204f6)

**Three Key Patterns**:

| Pattern | Source | Purpose |
|---------|--------|---------|
| **Reflexion** | Shinn et al., NeurIPS 2023 | Verbal reinforcement learning |
| **OODA Loop** | Military strategy → AI agents | Real-time adaptation |
| **Verification Loops** | Spotify production systems | Quality gates with veto power |

#### Reflexion Pattern (Two-Phase Reflection)

**Architecture**: Actor → Evaluator → Self-Reflection → Memory

**Key Mechanism**: Separate error analysis from solution generation (two LLM calls)

```
1. Agent generates action
2. Receive feedback (test results, errors)
3. REFLECT: "What assumption failed?" (LLM call #1)
4. GENERATE: "How to prevent this?" (LLM call #2)
5. Store reflection in episodic memory
6. Retrieve on next attempt
```

**Critical Design**: `LAST_ATTEMPT_AND_REFLEXION` context injection

**Result**: Dramatic improvement on tasks requiring multi-step reasoning

#### OODA Loop (Within-Trial Adaptation)

**Four Stages**:

| Stage | Action | Agent Context |
|-------|--------|---------------|
| **Observe** | Gather tool outputs, test results | Raw data |
| **Orient** | Apply past reflections + current context | Retrieved memories |
| **Decide** | Select action based on understanding | Planning |
| **Act** | Execute → generates new observations | Tool calls |

**Key Insight**: OODA handles within-trial adaptation; Reflexion handles across-trial learning. Layer both for complete system.

#### Spotify Verification Loops (Production Quality Gates)

**Architecture**:

- **Deterministic verifiers**: Maven/npm/build/test tools
- **LLM Judge**: Evaluates diff + prompt (prevents scope creep)
- **Stop hooks**: Run all verifiers before PR creation

**Metrics**:
- Judge vetoes ~25% of agent sessions
- 50% of vetoed sessions successfully course-correct

**Safety Principle**: Agent doesn't know what verifiers do internally—only that they can be called. Prevents prompt injection attacks.

#### Complete Learning Loop (Synthesized)

```
┌─────────────────────────────────────────────────────────────┐
│                    OUTER LOOP (Across Trials)                │
│                                                               │
│  Agent executes → Feedback → REFLEXION → Store → Validate    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    INNER LOOP (Within Trial)                 │
│                                                               │
│  OBSERVE → ORIENT → DECIDE → ACT → repeat                   │
└─────────────────────────────────────────────────────────────┘
```

#### When to Update vs Keep Existing Behavior

| KEEP Existing | UPDATE Behavior |
|---------------|-----------------|
| Predictability critical | Data distribution shifts |
| Limited labeled feedback | Performance degradation detected |
| Preventing catastrophic forgetting | New capabilities needed |
| Regulatory/safety requirements | Environment changes |
| Core features stable | Tool use optimization needed |

#### Staged Promotion (Production Pattern)

```
[EXPERIMENT] → [VALIDATE] → [PRODUCTION]
     ↓              ↓               ↓
  Test suite    Auto-rollback   Versioned memory
```

**Anti-Patterns to Avoid**:

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Reflection without action | Stored reflections never retrieved | Ensure retrieval surfaces relevant reflections |
| Over-indexing recent failures | Rapid oscillation between strategies | Balance recent with proven strategies |
| Generic reflections | "Reflect on performance" → useless | Use structured: "What assumption failed?" |
| Self-scoring without validation | Agent rates itself highly while failing | Compare self-assessment against external KPIs |
| Overthinking | Excessive planning without acting | Set max reflection iteration limits |

**Implication for Context Graph**:

- Capture corrections with structured reflection (two LLM calls)
- Use OODA for within-trial decisions
- Implement staged promotion (experiment → validate → production)
- Apply verification loops before state transitions

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

## 9. Multi-Agent Coordination Patterns Research

*Added: 2025-12-27*

### 9.1 Production Coordination Patterns

From 40+ sources including academic papers (2024-2025), engineering blogs (Anthropic, Databricks, AWS, Azure), and production systems.

| Pattern | Description | Production Example |
|---------|-------------|-------------------|
| **Supervisor/Coordinator** | Central orchestrator routes to specialist workers | Databricks, AWS, Azure, LangGraph |
| **State Machine** | Explicit states with guarded transitions | Anthropic Long-Running Harness |
| **Blackboard/Shared State** | Shared workspace for loose agent coupling | LLM Multi-Agent Systems (arXiv) |
| **Sequential Handoff** | Defined agent sequences with quality gates | LangGraph, AutoGen |
| **Event-Driven** | Message bus for distributed coordination | Confluent Event-Driven Systems |

**Key Finding**: All production systems use **explicit orchestration** rather than autonomous agent coordination.

### 9.2 State Machine Pattern (Anthropic)

Architecture from [Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

```
[INITIALIZER] ──feature_list───▶ [CODING] ──tests_pass───▶ [TESTER] ──health_check───▶ [VERIFIER]
       ▲                                                                              │
       └───────────────────────────────────────────────failure────────────────────────┘
```

**Key Mechanisms**:
- Feature list as contract (JSON, not Markdown)
- Quality gates at each transition
- Checkpoints for session resumption
- Enforcement hooks (not just rules)

### 9.3 Handoff Protocol

From [LangGraph Multi-Agent Structures](https://langchain-opentutorial.gitbook.io/langchain-opentutorial/17-langgraph/02-structures/08-langgraph-multi-agent-structures-01):

| Element | Description | Example |
|---------|-------------|---------|
| **Precondition** | What must be complete | Code written, linted |
| **Artifacts** | What's passed along | File paths, test results |
| **Postcondition** | What next agent expects | Ready-to-test state |
| **Rollback** | How to handle failures | Return to previous state |

### 9.4 Anti-Patterns to Avoid

From research across [Maxim.ai](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/), [Galileo](https://galileo.ai/blog/multi-agent-ai-failures-prevention), [Orq.ai](https://orq.ai/blog/why-do-multi-agent-llm-systems-fail):

| Anti-Pattern | Symptom | Solution |
|--------------|---------|----------|
| **No-op loops** | Agents repeat work without progress | State machine with progress counters |
| **Machine ghosting** | Agent appears to work but produces no output | Output validation before state transition |
| **Quality drift** | Standards gradually degrade | Runtime guards (hooks that block) |
| **State explosion** | Too many agents managing overlapping state | Clear state partitioning |
| **Coordination deadlock** | Agents waiting on each other indefinitely | Timeouts, clear state machine |
| **Cascading failures** | One agent's bad output breaks pipeline | Quality gates at each transition |
| **Premature completion** | Feature marked done without testing | Block tested:true without evidence |
| **Orchestration gaps** | Unclear who does what next | Auto-orchestration via state machine |

### 9.5 Core Principles (Synthesized)

| Principle | Explanation | Source |
|-----------|-------------|--------|
| **Explicit > Implicit** | State machines beat free-form coordination | Anthropic, Azure |
| **Centralized > Decentralized** | Supervisor pattern beats autonomous chaos | Databricks, AWS |
| **Enforcement > Rules** | Hooks that block beat instructions | Anthropic |
| **Verification > Trust** | Quality gates prevent cascading failures | All production systems |
| **Structured > Emergent** | Defined patterns beat agent self-organization | Academic + production |

**Key Insight**: "Coordination complexity often outweighs multi-agent benefits. Production systems use structured, explicit orchestration rather than emergent agent behavior."

### 9.6 Academic Research (2024-2025)

| Paper | Focus | Key Finding |
|-------|-------|-------------|
| [Multi-Agent Collaboration Mechanisms: A Survey of LLMs](https://arxiv.org/abs/2501.06322) | Collaboration | Extensible framework for future research |
| [Multi-Agent Coordination across Diverse Applications](https://arxiv.org/abs/2502.14743) | Coordination | 4 fundamental questions (what, when, how, who) |
| [A Survey of Multi-AI Agent Collaboration](https://dl.acm.org/doi/full/10.1145/3745238.3745531) | Multi-AI | Advanced evolution from single AI |
| [Exploring Advanced LLM Multi-Agent Systems Based on Blackboard Architecture](https://arxiv.org/html/2507.01701v1) | Blackboard | Shared state enables coordination without direct comms |

### 9.7 Communication Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Message Passing (Direct)** | Agent A sends request, waits for reply | Synchronous queries |
| **Shared State (Indirect)** | Feature list, blackboard | Progress tracking |
| **Command Objects** | Explicit context passing | Handoffs |

**Command Object Schema** (from [Multi-Agent Communication](https://www.linkedin.com/pulse/deep-dive-multi-agent-systems-communication-a2a-protocols-singh-ilnif)):
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
    "next_agent": "verifier-agent"
  }
}
```

### 9.8 Full Research Details

See: `/Users/gurusharan/Documents/remote-claude/agent-harness/coordination-patterns-research.md`

Contains:
- 5 production coordination patterns with examples
- Communication patterns and mechanisms
- Handoff best practices
- State machine patterns (FSM, HSM)
- 10 anti-patterns with solutions
- Production case studies (Anthropic, Databricks, Azure, AWS)
- Framework comparison (LangGraph, AutoGen, CrewAI, OpenAI Swarm)
- 40+ sources cited

---

## 10. Sources

| Article | Key Insight |
|---------|-------------|
| [Context Graphs](https://foundationcapital.com/context-graphs-ais-trillion-dollar-opportunity/) | Decision traces = trillion-dollar layer |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Progressive disclosure, code execution |
| [Code Execution MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) | 98.7% token savings via sandbox |
| [Long-Running Harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Feature list, session continuity, state machine |
| [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) | 4-agent sequence, enforcement hooks |
| [Databricks Supervisor Architecture](https://www.databricks.com/blog/multi-agent-supervisor-architecture-orchestrating-enterprise-ai-scale) | Supervisor pattern at scale |
| [Azure Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns) | Pattern catalog (sequential, concurrent, handoff, supervisor) |
| [Confluent Event-Driven Multi-Agent](https://www.confluent.io/blog/event-driven-multi-agent-systems/) | Event bus coordination |
| [Multi-Agent Collaboration Survey](https://arxiv.org/abs/2501.06322) | Academic survey (2025) |
| [Blackboard Architecture for LLM MAS](https://arxiv.org/html/2507.01701v1) | Shared state coordination |
| [Coordination Patterns Research](coordination-patterns-research.md) | 40+ sources synthesized |

---

*Last Updated: 2025-12-28*
*Status: Research Complete - Ready for Implementation*

**Sections Added This Session:**
- 2.4: Context Engineering (smallest high-signal token set, compaction, sub-agent distillation)
- 3.4: Learning Loop Patterns (Reflexion, OODA, Spotify verification loops)

**Previously Added:**
- Section 9: Multi-Agent coordination patterns, handoff protocols, anti-patterns
- Progressive disclosure pattern (metadata/summary/full detail levels)
- Hook research: blocking mechanisms, SubagentStop identification
