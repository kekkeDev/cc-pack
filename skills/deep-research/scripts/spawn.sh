#!/bin/bash
set -euo pipefail

# Deep Research: parallel subagent spawn helper
# Usage: spawn.sh SESSION_ID "parent objective" "subtask1" "subtask2" ...

SESSION_ID="${1:?SESSION_ID is required}"
PARENT_OBJECTIVE="${2:?Parent objective is required}"
shift 2

MAX_AGENTS="${MAX_AGENTS:-3}"
WORK_DIR="/tmp/deep-research-${SESSION_ID}"
mkdir -p "$WORK_DIR"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"

# System prompt suffix shared by all subagents
read -r -d '' SYSTEM_SUFFIX << 'PROMPT_END' || true
You are a research subagent. Follow these rules:

1. Use WebSearch and WebFetch actively to gather up-to-date information
2. Keep tool calls within ~10-15 invocations
3. Mark uncertain claims with confidence (high / medium / low)
4. Respond in the same language as the parent objective above
5. Output MUST be raw JSON in the following format (no markdown, no code fences):

{
  "subtask": "Title of your assigned subtask",
  "findings": [
    {
      "claim": "The fact or claim you discovered",
      "source_url": "URL of the source",
      "source_title": "Title of the source",
      "confidence": "high or medium or low"
    }
  ],
  "summary": "Summary of this subtask's findings (in the parent objective's language)"
}
PROMPT_END

TASK_NUM=0
PIDS=()
TASK_FILES=()

for SUBTASK_PROMPT in "$@"; do
  TASK_NUM=$((TASK_NUM + 1))
  OUTFILE="${WORK_DIR}/task-${TASK_NUM}.json"
  TASK_FILES+=("$OUTFILE")

  # Concurrency control: wait when MAX_AGENTS is reached
  while [ "${#PIDS[@]}" -ge "$MAX_AGENTS" ]; do
    NEW_PIDS=()
    for pid in "${PIDS[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        NEW_PIDS+=("$pid")
      fi
    done
    PIDS=("${NEW_PIDS[@]}")
    if [ "${#PIDS[@]}" -ge "$MAX_AGENTS" ]; then
      sleep 2
    fi
  done

  FULL_PROMPT="## Parent objective
${PARENT_OBJECTIVE}

## Your assigned subtask
${SUBTASK_PROMPT}

## Output rules
${SYSTEM_SUFFIX}"

  echo "[spawn] Subtask ${TASK_NUM} starting: ${SUBTASK_PROMPT:0:60}..." >&2

  "$CLAUDE_BIN" -p "$FULL_PROMPT" \
    --output-format json \
    --model sonnet \
    --max-turns 30 \
    > "$OUTFILE" 2>/dev/null &

  PIDS+=($!)
done

# Wait for all subagents to finish
echo "[spawn] Waiting for ${TASK_NUM} subtasks to complete..." >&2
FAILED=0
for i in "${!PIDS[@]}"; do
  if ! wait "${PIDS[$i]}" 2>/dev/null; then
    TASK_IDX=$((i + 1))
    echo "[spawn] Subtask ${TASK_IDX} failed" >&2
    echo '{"error": "Subagent execution failed", "subtask": "task-'${TASK_IDX}'"}' > "${TASK_FILES[$i]}"
    FAILED=$((FAILED + 1))
  fi
done

echo "[spawn] Done: succeeded $((TASK_NUM - FAILED))/${TASK_NUM}" >&2
echo "[spawn] Results: ${WORK_DIR}/" >&2

# Emit work dir to stdout for the caller
echo "${WORK_DIR}"
