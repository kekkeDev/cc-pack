#!/bin/bash
# PreToolUse hook: inject grep-tips snippet into Claude's context.
# Triggered before grep / rg invocations (Bash) and before Grep tool calls.
#
# Expected stdin: JSON with tool_name / tool_input (not used here; matcher + if filter).
# Output: JSON with hookSpecificOutput.additionalContext to inject context.
set -u

SNIPPET="$HOME/.claude/snippets/grep-tips.md"

# Snippet missing → silently allow tool execution to proceed.
[ -f "$SNIPPET" ] || exit 0

CONTENT=$(cat "$SNIPPET")

jq -n --arg ctx "$CONTENT" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'

exit 0
