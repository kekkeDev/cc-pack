# grep-tips

A [Claude Code](https://claude.ai/code) **PreToolUse hook** that injects grep blind-spot guidance before `grep` / `rg` / `Grep` invocations.

Reminds Claude (and yourself) that **"not found by grep" is not proof of "doesn't exist"**. Text-based search misses:

- Catch-all re-exports / autoloads / dynamic imports
- Generated / transpiled / minified code
- Files outside the search scope (binaries, `.gitignore`'d paths, other packages)
- Notation variations (case, encoding, path layout)

## Files

- `grep-tips-inject.sh` — the hook script (~20 lines of bash)
- `grep-tips.md` — the snippet content injected as `additionalContext`

The snippet is intentionally separated from the script so the guidance can be edited without touching hook code.

## Installation

1. Copy the hook script and snippet:

   ```bash
   mkdir -p ~/.claude/hooks ~/.claude/snippets
   cp grep-tips-inject.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/grep-tips-inject.sh
   cp grep-tips.md ~/.claude/snippets/
   ```

2. Register the hook in `~/.claude/settings.json` (merge into the existing `hooks.PreToolUse` array):

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "if": "Bash(grep *)",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             },
             {
               "type": "command",
               "if": "Bash(rg *)",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             }
           ]
         },
         {
           "matcher": "Grep",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             }
           ]
         }
       ]
     }
   }
   ```

3. Restart Claude Code.

## How it works

Claude Code fires PreToolUse hooks before tool invocations matching the registered matcher / condition. The hook script reads the snippet file and emits JSON like:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "<snippet content>"
  }
}
```

Claude receives `additionalContext` and uses it when deciding how to execute (or whether to refine) the tool call.

If the snippet file is missing, the hook exits with status 0 and produces no output, so tool execution proceeds normally — graceful degradation.

## Customizing the snippet

Edit `~/.claude/snippets/grep-tips.md` directly. No need to touch the hook script — the snippet is read on every invocation.

## Why this pattern matters

Hooks live in the **interface layer** between prompt engineering and fine-tuning. You don't change the model; you change what context the model sees right before risky actions. Small, focused, version-controlled.

This particular hook targets one specific blind spot. The same pattern can be used to inject guidance before any tool invocation that has known failure modes.

## Author

kekkeDev — https://x.com/kekke_dev
