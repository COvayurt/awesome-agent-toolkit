#!/bin/bash
# prompt-hook.sh — UserPromptSubmit hook for android-code-review skill
#
# When the user asks for a code review, shows the current branch context
# and changed files to help the agent get started.

set -euo pipefail

# Read the user's prompt from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "")

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

if [[ ! "$PROMPT_LOWER" =~ (review.*code|review.*change|review.*branch|review.*mr|code.*review|review.*my|android.*review) ]]; then
    exit 0
fi

# Get current branch info
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
    exit 0
fi

# Detect default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Get changed files
CHANGED_FILES=$(git diff --name-only "$DEFAULT_BRANCH"..."$BRANCH" 2>/dev/null || echo "")
FILE_COUNT=$(echo "$CHANGED_FILES" | grep -c '.' 2>/dev/null || echo "0")

cat << EOF
## Code Review Context (Auto-fetched)

**Branch:** \`$BRANCH\` → \`$DEFAULT_BRANCH\`
**Changed files:** $FILE_COUNT

\`\`\`
$CHANGED_FILES
\`\`\`

**Reminder:** Use \`git diff $DEFAULT_BRANCH...HEAD\` to read the full diff, then post inline comments via the gitlab-mr scripts. Do NOT modify any code.
EOF
