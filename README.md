# cc-skills

Custom skills for [Claude Code](https://claude.ai/code).

## Skills

| Skill | Description |
|---|---|
| [ui-repro](./ui-repro/) | Reproduce UI from screenshots with high fidelity using a verbalization-first workflow |

## Installation

Copy the `SKILL.md` file into your Claude Code skills directory:

```bash
# Personal (global) skill — available across all projects
mkdir -p ~/.claude/skills/<skill-name>
cp <skill-name>/SKILL.md ~/.claude/skills/<skill-name>/SKILL.md

# Project skill — available only in a specific project
mkdir -p .claude/skills/<skill-name>
cp <skill-name>/SKILL.md .claude/skills/<skill-name>/SKILL.md
```

Japanese versions are available as `SKILL.ja.md`.

Restart Claude Code after installation.

## Author

kekkeDev — https://x.com/kekke_dev
