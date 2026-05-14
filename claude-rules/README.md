# claude-rules

A curated set of behavioral rules for [Claude Code](https://claude.ai/code), distilled from real-world use. Covers communication discipline (assumption explicitness, tradeoff transparency, mechanism-first diagnosis) and safety (irreversible operations, scoped config).

Inspired in part by [Andrej Karpathy's observations on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876) and [Forrest Chang's distillation](https://github.com/forrestchang/andrej-karpathy-skills), but pruned to items not already covered by Claude Code's built-in system prompt.

## Installation

Copy `CLAUDE.md` (or `CLAUDE.ja.md` for Japanese) to your global Claude Code config directory:

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
```

If you already have rules there, merge manually rather than overwriting.

Restart Claude Code after installation.

## Tip: Concretize for your environment

These rules are written in abstract, universal terms so they apply across environments. **LLMs follow concrete instructions more reliably than abstract ones**, so when adopting these rules for your own use, consider replacing abstractions with names from your specific stack.

Examples:
- "Don't modify user-wide or system-wide config" → "Don't run `git config --global`, don't edit `~/.zshrc`, don't `export` env vars persistently"
- "Persisting requires separate confirmation" → "Updating `memory/`, `CLAUDE.md`, or saved `notes/` files requires separate confirmation"

The abstract version is the published baseline; concrete substitution is what makes it actually shape behavior.

## Languages

- `CLAUDE.md` — English
- `CLAUDE.ja.md` — Japanese (日本語)

## Author

kekkeDev — https://x.com/kekke_dev
