#!/bin/bash
# prompt-hook.sh — UserPromptSubmit hook for Claude Code
#
# When the user's prompt mentions sonar issues, automatically fetches
# open issues from SonarQube API and injects them into Claude's context.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_SCRIPTS="$SCRIPT_DIR/../core/scripts"

# Load environment from .env if it exists
if [ -f "$SCRIPT_DIR/../.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
fi

# Read the user's prompt from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "")

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

if [[ ! "$PROMPT_LOWER" =~ (sonar|fix.*issue|code.*smell|bug.*scan|quality.*gate) ]]; then
    exit 0
fi

# Determine severity filter
SEVERITY="HIGH,MEDIUM"
if [[ "$PROMPT_LOWER" =~ blocker ]]; then
    SEVERITY="BLOCKER"
elif [[ "$PROMPT_LOWER" =~ (high|critical) ]]; then
    SEVERITY="HIGH"
elif [[ "$PROMPT_LOWER" =~ medium ]]; then
    SEVERITY="MEDIUM"
elif [[ "$PROMPT_LOWER" =~ low ]]; then
    SEVERITY="LOW"
elif [[ "$PROMPT_LOWER" =~ info ]]; then
    SEVERITY="INFO"
fi

FETCH_ARGS=(--severity "$SEVERITY")

if [[ "$PROMPT_LOWER" =~ (new.code|new.code.period|new.code.only) ]]; then
    FETCH_ARGS+=(--new-code)
    export SONAR_NEW_CODE="true"
else
    export SONAR_NEW_CODE="false"
fi

# Fetch issues
RESPONSE=$("$CORE_SCRIPTS/fetch-issues.sh" "${FETCH_ARGS[@]}" 2>/dev/null)
FETCH_EXIT=$?

if [ $FETCH_EXIT -ne 0 ]; then
    echo "Warning: Could not fetch SonarQube issues. Is the server running?" >&2
    exit 0
fi

# Format and output issues
export SONAR_SEVERITY="$SEVERITY"
echo "$RESPONSE" | python3 "$CORE_SCRIPTS/format-issues.py"
