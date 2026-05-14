# cc-pack

A pack of customizations for [Claude Code](https://claude.ai/code).

## Skills

| Skill | Description |
|---|---|
| [ui-repro](./skills/ui-repro/) | Reproduce UI from screenshots with high fidelity using a verbalization-first workflow |
| [deep-research](./skills/deep-research/) | Multi-agent research orchestrator that decomposes a query into parallel subagent investigations and produces a cited Markdown report |

## Hooks

| Hook | Description |
|---|---|
| [grep-tips](./hooks/grep-tips/) | PreToolUse hook that injects grep blind-spot guidance before `grep` / `rg` / `Grep` invocations |

## Rules

| Pack | Description |
|---|---|
| [claude-rules](./claude-rules/) | A curated set of universal behavioral rules for `~/.claude/CLAUDE.md` (assumption explicitness, tradeoff transparency, mechanism-first diagnosis, scoped-config safety, etc.) |

## Installation

See each subdirectory's README for installation instructions.

Japanese versions are available as `README.ja.md` (and `SKILL.ja.md` for skills).

## Author

kekkeDev — https://x.com/kekke_dev
