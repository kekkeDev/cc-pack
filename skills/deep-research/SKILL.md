---
name: deep-research
description: Reproduces Anthropic's multi-agent research pattern. Decomposes complex queries into parallel subagent investigations and produces a Markdown report with citations. Triggers on natural-language phrases like "research X", "deep dive on Y", "compare A vs B", "investigate Z in detail".
allowed-tools: Bash(claude:*), Bash(jq:*), Bash(date:*), Bash(mkdir:*), Bash(cat:*), Bash(echo:*), Write, Read, WebSearch, WebFetch
---

# Deep Research Skill

Reproduces Anthropic's [multi-agent research pattern](https://www.anthropic.com/engineering/multi-agent-research-system) (Lead Researcher + parallel Subagents) by spawning `claude -p` subprocesses.

## Workflow (6 phases)

### Phase 1: Scope

Analyze the user's query and decide:

- The objective and expected output format
- Scope boundaries (what's in, what's out)
- Estimated number of subtasks (3–5)
- Output file slug (English kebab-case, e.g. `ai-coding-agents-comparison`)

### Phase 2: Plan

Decompose the query into 3–5 independent subtasks (MECE-ish). For each:

- Subtask number and title
- The specific question(s) to investigate
- Scope boundary (avoid overlap with sibling subtasks)
- Expected deliverable

Present the decomposition to the user and get approval before proceeding.

### Phase 3: Retrieve

Invoke `~/.claude/skills/deep-research/scripts/spawn.sh` to spawn subagents in parallel.

```bash
bash ~/.claude/skills/deep-research/scripts/spawn.sh \
  "SESSION_ID" \
  "Parent objective shared with all subagents" \
  "Subtask 1 prompt" \
  "Subtask 2 prompt" \
  "Subtask 3 prompt"
```

- Arg 1: Session ID (use `date +%Y%m%d-%H%M%S`)
- Arg 2: Parent objective (shared with all subagents)
- Args 3+: Per-subtask prompts

**Concurrency**: controlled by `MAX_AGENTS` env var (default: 3)

Each subagent automatically receives:
- The parent objective
- Its assigned subtopic and scope boundary
- Output format (raw JSON: `findings` array, each with `claim`, `source_url`, `confidence`)
- Instruction to use WebSearch/WebFetch actively
- Tool-call budget (~10–15 calls)
- Confidence marking (`high`/`medium`/`low`)

After spawn.sh completes, results land in `/tmp/deep-research-SESSION_ID/`.

### Phase 4: Triangulate

Read each subtask's result JSON and consolidate:

```bash
for f in /tmp/deep-research-SESSION_ID/task-*.json; do
  jq -r '.result // empty' "$f"
done
```

Consolidation criteria:
- Claims backed by multiple sources → raise confidence
- Conflicting claims → flag both, present as competing views
- Single-source claims → lower confidence
- Merge duplicate findings
- Source-tier weighting (official docs > news > blogs > social)

### Phase 5: Synthesize

Lead (you) integrates all findings into a structured Markdown report.

Report structure:
```markdown
# [Title]

> Researched: YYYY-MM-DD | Subtasks: N | Sources: N

## Executive Summary
(3–5 sentences, conclusion-first)

## 1. [Section title]
...

## 2. [Section title]
...

## Conflicts & Open Questions
(Conflicts surfaced in Triangulate, plus areas needing further research)

## Sources
1. [Title](URL) — confidence: high/medium/low
2. ...
```

### Phase 6: Package

1. Create the output directory:
```bash
mkdir -p ./docs/research
```

2. Save the report:
```bash
# Filename: YYYYMMDD-HHMMSS-slug.md
```

3. Report the file path back to the user and prompt for review.

## Failure handling

- **Subagent failure**: skip and record `[Subtask N: failed — reason]` in the final report. Don't halt the whole run.
- **Timeout** (no response for 5+ min): other subagents continue; the unfinished one is excluded from the report.
- **All subagents fail**: report to user and propose a single-agent fallback investigation.

## Notes

- Subagents are spawned with `--model sonnet` (cost-optimized)
- Lead (you) is expected to run on Opus
- Cost: multi-agent research uses roughly 15× the tokens of a single chat — be cost-aware
- Output language matches the parent objective's language (the spawn.sh subagent prompt enforces this)
