#!/usr/bin/env bash
# kosmo-ralph loop — adapted from https://github.com/snarktank/ralph (ralph.sh)
# Skill id kosmo-ralph (not "ralph") to avoid clashing with upstream snarktank skill.
# Workspace: _/kosmo-ralph/
#
# Usage:
#   ./scripts/kosmo-ralph.sh [--tool claude|codex|grok|amp|host] [max_iterations]
#   RALPH_DIR=_/kosmo-ralph ./scripts/kosmo-ralph.sh --tool claude 15
#
set -euo pipefail

TOOL="claude"
MAX_ITERATIONS=10
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
RALPH_DIR="${RALPH_DIR:-$PROJECT_ROOT/_/kosmo-ralph}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"; shift 2 ;;
    --tool=*)
      TOOL="${1#*=}"; shift ;;
    --dir)
      RALPH_DIR="$2"; shift 2 ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then MAX_ITERATIONS="$1"; fi
      shift ;;
  esac
done

mkdir -p "$RALPH_DIR"
PRD_FILE="$RALPH_DIR/prd.json"
PROGRESS_FILE="$RALPH_DIR/progress.txt"
PROMPT_FILE="$RALPH_DIR/prompt.md"
ARCHIVE_DIR="$RALPH_DIR/archive"
LAST_BRANCH_FILE="$RALPH_DIR/.last-branch"

# Seed prompt from plugin template if missing
if [[ ! -f "$PROMPT_FILE" && -f "$PLUGIN_ROOT/templates/kosmo-ralph-prompt.md" ]]; then
  cp "$PLUGIN_ROOT/templates/kosmo-ralph-prompt.md" "$PROMPT_FILE"
fi

if [[ ! -f "$PRD_FILE" ]]; then
  echo "Error: $PRD_FILE not found. Convert a PRD first (kosmo-ralph skill Job A)."
  exit 1
fi

# Archive previous run if branch changed (snarktank behavior)
if [[ -f "$PRD_FILE" && -f "$LAST_BRANCH_FILE" ]] && command -v jq >/dev/null 2>&1; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  if [[ -n "$CURRENT_BRANCH" && -n "$LAST_BRANCH" && "$CURRENT_BRANCH" != "$LAST_BRANCH" ]]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    echo "Archiving previous run: $LAST_BRANCH -> $ARCHIVE_FOLDER"
    mkdir -p "$ARCHIVE_FOLDER"
    cp "$PRD_FILE" "$ARCHIVE_FOLDER/" 2>/dev/null || true
    [[ -f "$PROGRESS_FILE" ]] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

if command -v jq >/dev/null 2>&1; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  [[ -n "$CURRENT_BRANCH" ]] && echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
fi

if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: $PROMPT_FILE missing"
  exit 1
fi

echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "Ralph dir: $RALPH_DIR"

run_iteration() {
  case "$TOOL" in
    amp)
      cat "$PROMPT_FILE" | amp --dangerously-allow-all 2>&1 || true
      ;;
    claude)
      claude --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 || true
      ;;
    codex)
      codex exec "$(cat "$PROMPT_FILE")" 2>&1 || true
      ;;
    grok)
      grok -p "$(cat "$PROMPT_FILE")" 2>&1 || true
      ;;
    host)
      echo "TOOL=host: run one iteration in your current agent with skills/kosmo-ralph Job B."
      echo "Then re-run this script or continue manually."
      exit 0
      ;;
    *)
      echo "Error: Invalid tool '$TOOL'. Use amp|claude|codex|grok|host"
      exit 1
      ;;
  esac
}

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "==============================================================="
  echo "  kosmo-ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  OUTPUT=$(run_iteration | tee /dev/stderr) || true

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "kosmo-ralph completed all tasks at iteration $i"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "kosmo-ralph reached max iterations ($MAX_ITERATIONS)."
echo "Check $PROGRESS_FILE and $PRD_FILE for status."
exit 1
