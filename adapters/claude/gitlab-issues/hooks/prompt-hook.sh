#!/bin/bash
# prompt-hook.sh — UserPromptSubmit hook for Claude Code
#
# When the user's prompt mentions GitLab issues, automatically fetches
# issues and injects them into Claude's context.

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

# Check if this is a GitLab issues request
if [[ ! "$PROMPT_LOWER" =~ (gitlab.*issue|issue.*gitlab|list.*issue|show.*issue|fetch.*issue|my.*issue|open.*issue|milestone|create.*issue|new.*issue|add.*issue|sub.?issue|child.*issue) ]]; then
    exit 0
fi

# Check for required environment variables
if [ -z "${GITLAB_HOST_URL:-}" ] || [ -z "${GITLAB_TOKEN:-}" ] || [ -z "${GITLAB_PROJECT_ID:-}" ]; then
    echo "GitLab Issues plugin activated. Configure GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID in ~/.claude/settings.json (env section) or plugin .env file"
    exit 0
fi

# Determine state filter
STATE="opened"
if [[ "$PROMPT_LOWER" =~ closed ]]; then
    STATE="closed"
elif [[ "$PROMPT_LOWER" =~ all ]]; then
    STATE="all"
fi

# Extract milestone if mentioned (simple pattern)
MILESTONE=""
if [[ "$PROMPT_LOWER" =~ milestone[[:space:]]+([^\s]+) ]]; then
    MILESTONE="${BASH_REMATCH[1]}"
fi

# Fetch issues
RESPONSE=$("$CORE_SCRIPTS/list-issues.sh" "$STATE" "$MILESTONE" 2>/dev/null)
FETCH_EXIT=$?

if [ $FETCH_EXIT -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "GitLab Issues plugin activated but could not fetch issues. Check your configuration and network."
    exit 0
fi

# Format and output issues
cat << 'EOF'
## GitLab Issues (Auto-fetched)

EOF

echo "$RESPONSE" | python3 -c "
import json
import sys

try:
    issues = json.load(sys.stdin)
    if not issues:
        print('No issues found.')
        sys.exit(0)

    print('| IID | Title | State | Assignees | Labels | Milestone |')
    print('|-----|-------|-------|-----------|--------|-----------|')

    for issue in issues[:20]:  # Limit to 20
        iid = issue.get('iid', '')
        title = issue.get('title', '')[:50]
        state = issue.get('state', '')
        assignees = ', '.join(issue.get('assignees', []))[:20] or '-'
        labels = ', '.join(issue.get('labels', []))[:20] or '-'
        milestone = issue.get('milestone', '-') or '-'
        print(f'| #{iid} | {title} | {state} | {assignees} | {labels} | {milestone} |')

    total = len(issues)
    if total > 20:
        print(f'\\n_Showing 20 of {total} issues_')
except Exception as e:
    print(f'Error parsing issues: {e}')
"

cat << 'EOF'

**Available Scripts:** Use bash scripts in `core/scripts/` for more operations:
- `create-issue.sh <json_payload>` - Create new issue
- `create-sub-issue.sh <parent_iid> <json_payload>` - Create sub-issue linked to parent
- `list-issues.sh [state] [milestone]` - List issues
- `get-issue-details.sh <iid>` - Get issue details
- `post-issue-comment.sh <iid> <body>` - Add comment
- `update-issue.sh <iid> [options]` - Update issue
EOF
