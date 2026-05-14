# Deep Research Skill

Reproduces Anthropic's [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) pattern for [Claude Code](https://claude.ai/code).

## Design

- **Lead Researcher (Opus)** analyzes and decomposes the query, then orchestrates the run
- **Subagents (Sonnet)** are spawned as `claude -p` subprocesses and investigate in parallel
- **Lead** then triangulates and synthesizes a Markdown report with citations

## How to Use

In Claude Code, just ask in natural language:

```
"Research the AI coding agent landscape in 2026 in depth"
"Compare React vs Svelte vs Solid"
"Investigate LLM fine-tuning techniques"
```

Trigger phrases (English): "research X", "deep dive on Y", "compare A vs B", "investigate X in detail"
Trigger phrases (Japanese): 「詳しく調べて」「リサーチして」「比較検証して」「深掘りして」「調査して」

## Output language

Subagents respond in the same language as the parent objective (enforced by spawn.sh's system prompt). Pass an English objective → English output. Pass a Japanese objective → Japanese output.

## 6 Phases

1. **Scope** — Determine direction and boundaries
2. **Plan** — Decompose into 3–5 subtasks (user approval)
3. **Retrieve** — Spawn subagents in parallel
4. **Triangulate** — Reconcile conflicts, weight sources, deduplicate
5. **Synthesize** — Generate the integrated report
6. **Package** — Save to `./docs/research/`

## Output

Reports are saved to `./docs/research/YYYYMMDD-HHMMSS-slug.md`.

## Configuration

### Environment variables

| Var | Default | Description |
|------|-----------|------|
| `MAX_AGENTS` | 3 | Max parallel subagents |
| `CLAUDE_BIN` | claude | Path to the `claude` binary |

### Required permissions (settings.json)

```json
"Bash(claude:*)"
```

The other permissions (`jq`, `mkdir`, `date`, etc.) are usually already in your default config.

## Installation

Copy the entire `deep-research/` directory (including `scripts/`) into your Claude Code skills directory:

```bash
# Personal (global) skill
mkdir -p ~/.claude/skills/deep-research
cp SKILL.md ~/.claude/skills/deep-research/SKILL.md
cp -r scripts ~/.claude/skills/deep-research/scripts
chmod +x ~/.claude/skills/deep-research/scripts/spawn.sh

# Project skill
mkdir -p .claude/skills/deep-research
cp SKILL.md .claude/skills/deep-research/SKILL.md
cp -r scripts .claude/skills/deep-research/scripts
chmod +x .claude/skills/deep-research/scripts/spawn.sh
```

For the Japanese version, use `SKILL.ja.md` instead of `SKILL.md`.

If you install to a project-local path, edit the spawn.sh path inside SKILL.md accordingly (default assumes `~/.claude/skills/`).

Restart Claude Code after installation.

## File layout

```
deep-research/
├── SKILL.md          — Skill (English)
├── SKILL.ja.md       — Skill (Japanese)
├── README.md         — This file
├── README.ja.md      — Japanese version
└── scripts/
    └── spawn.sh      — Parallel-spawn helper
```

## Cost

- Multi-agent research uses roughly **15× the tokens** of a single chat
- Subagents on Sonnet (cheaper), Lead on Opus (higher quality) — already optimized
- Rough estimate: 3 subtasks × 10–15 tool calls ≈ $1–3 per investigation

## References

- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)

## Author

kekkeDev — https://x.com/kekke_dev
