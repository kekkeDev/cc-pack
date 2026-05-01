# UI Repro — High-Fidelity UI Reproduction from Screenshots

A workflow skill for Claude Code that reproduces UI from screenshots with high fidelity.
Uses a "verbalization-first" approach: **Image → Verbalize → Implement → Capture → Compare screenshots side-by-side to verbalize diffs → Fix → Repeat**.
The verbalization text is the sole input for implementation — never code directly from images.

## Why Verbalization?

LLMs (including Claude) struggle to implement UI directly from screenshots. When you say "make it look like this screenshot," the rough structure matches but colors, spacing, and font sizes drift.

The root cause: visual information is lost when converting directly from image to code in a single step.

This skill forces an intermediate verbalization step — converting the image into precise numeric specs (exact px values, hex color codes). Implementation uses only this text. Diffs are extracted by comparing the target and current screenshots side by side and verbalizing the differences. This ensures:

- Ambiguous visual judgment is eliminated
- Diffs are structured and actionable
- Accuracy improves with each iteration

## How to Use

In Claude Code, say something like:

```
"Reproduce this UI from the screenshot"
"Match this design exactly"
"Pixel-match this mockup"
```

The skill will ask for:
1. Reference screenshot (file path or image)
2. Target URL
3. Whether the dev server is running

## Phases

1. **Phase 1** — Verbalize the target screenshot with exact numeric values
2. **Phase 1.5** — Pixel-sample colors from the image to confirm VLM-ambiguous values
3. **Phase 2** — Implement from verbalization text only (image is forbidden)
4. **Phase 3** — Capture current implementation screenshot with Playwright
5. **Phase 4** — Compare target vs current screenshots side-by-side, verbalize diffs
6. **Phase 5** — Fix diffs starting from HIGH priority → return to Phase 3

## Requirements

- **Playwright** — used for screenshot capture. Installation is guided if missing
- **sharp** — used for pixel color sampling in Phase 1.5
- **Web UI target** — uses Playwright browser screenshots, so Web UI is the primary target. For native apps, the verbalization workflow itself is applicable if you substitute the screenshot method (e.g., `screencapture` command, Appium)
- **5-loop limit** — pauses after 5 iterations to consult the user

## Installation

Copy `SKILL.md` (or `SKILL.ja.md` for Japanese) to your Claude Code skills directory:

```bash
# Personal (global) skill
mkdir -p ~/.claude/skills/ui-repro
cp SKILL.md ~/.claude/skills/ui-repro/SKILL.md

# Project skill
mkdir -p .claude/skills/ui-repro
cp SKILL.md .claude/skills/ui-repro/SKILL.md
```

Restart Claude Code after installation.

## Languages

- `SKILL.md` — English
- `SKILL.ja.md` — Japanese (日本語)

## Author

kekkeDev — https://x.com/kekke_dev
