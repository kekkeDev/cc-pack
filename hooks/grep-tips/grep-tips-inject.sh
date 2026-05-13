#!/bin/bash
# PreToolUse hook: inject grep-tips snippet into Claude's context.
# Triggered before grep / rg invocations (Bash) and before Grep tool calls.
#
# This script does its own subcommand-prefix matching on stdin's tool_input,
# so the snippet is injected only when a subcommand actually starts with
# `grep` or `rg` — not when those words merely appear as arguments
# (e.g. in a commit message). This provides defense-in-depth against
# settings.json `if:` matcher edge cases.
set -u

SNIPPET="$HOME/.claude/snippets/grep-tips.md"
[ -f "$SNIPPET" ] || exit 0

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')

should_fire=false

if [ "$TOOL_NAME" = "Grep" ]; then
  should_fire=true
elif [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
  # Flatten newlines so the regex sees one line.
  CMD_FLAT=$(printf '%s' "$CMD" | tr '\n' ' ')
  # Match `grep` or `rg` only when it appears as a subcommand head:
  #   - at the very start of the pipeline, or
  #   - immediately after a subcommand separator (&&, ||, ;, |, |&),
  # optionally preceded by VAR=val environment assignments.
  if printf '%s' "$CMD_FLAT" | grep -qE '(^|(&&|\|\||;|\|&|\|))[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(grep|rg)([[:space:]]|$)'; then
    should_fire=true
  fi
fi

$should_fire || exit 0

CONTENT=$(cat "$SNIPPET")
jq -n --arg ctx "$CONTENT" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'

exit 0
