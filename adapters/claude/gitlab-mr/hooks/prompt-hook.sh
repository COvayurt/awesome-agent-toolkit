#!/bin/bash
# prompt-hook.sh — UserPromptSubmit hook for Claude Code
#
# When the user's prompt mentions GitLab merge requests, automatically fetches
# MRs and injects them into Claude's context.

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

# Check if this is a GitLab MR request
if [[ ! "$PROMPT_LOWER" =~ (gitlab.*mr|merge.*request|list.*mr|show.*mr|my.*mr|open.*mr|review|code.*review) ]]; then
    exit 0
fi

# Check for required environment variables
if [ -z "${GITLAB_HOST_URL:-}" ] || [ -z "${GITLAB_TOKEN:-}" ] || [ -z "${GITLAB_PROJECT_ID:-}" ]; then
    echo "GitLab MR plugin activated. Configure GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID in ~/.claude/settings.json (env section) or plugin .env file"
    exit 0
fi

# Determine state filter
STATE="opened"
if [[ "$PROMPT_LOWER" =~ merged ]]; then
    STATE="merged"
elif [[ "$PROMPT_LOWER" =~ closed ]]; then
    STATE="closed"
elif [[ "$PROMPT_LOWER" =~ all ]]; then
    STATE="all"
fi

# Fetch MRs
RESPONSE=$("$CORE_SCRIPTS/list-mrs.sh" "$STATE" 2>/dev/null)
FETCH_EXIT=$?

if [ $FETCH_EXIT -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "GitLab MR plugin activated but could not fetch MRs. Check your configuration and network."
    exit 0
fi

# Format and output MRs
cat << 'EOF'
## GitLab Merge Requests (Auto-fetched)

EOF

echo "$RESPONSE" | python3 -c "
import json
import sys

try:
    mrs = json.load(sys.stdin)
    if not mrs:
        print('No merge requests found.')
        sys.exit(0)

    print('| IID | Title | State | Author | Source Branch | Target |')
    print('|-----|-------|-------|--------|---------------|--------|')

    for mr in mrs[:20]:  # Limit to 20
        iid = mr.get('iid', '')
        title = mr.get('title', '')[:40]
        state = mr.get('state', '')
        author = mr.get('author', '-') or '-'
        source = mr.get('source_branch', '')[:20]
        target = mr.get('target_branch', '')[:15]
        print(f'| !{iid} | {title} | {state} | {author} | {source} | {target} |')

    total = len(mrs)
    if total > 20:
        print(f'\\n_Showing 20 of {total} MRs_')
except Exception as e:
    print(f'Error parsing MRs: {e}')
"

cat << 'EOF'

**Available Scripts:** Use bash scripts in `core/scripts/` for more operations:
- `list-mrs.sh [state]` - List merge requests
- `get-mr-details.sh <iid>` - Get MR details
- `get-mr-discussions.sh <iid>` - Get MR discussions/comments
- `post-mr-comment.sh <iid> <body>` - Add comment to MR
- `reply-to-discussion.sh <iid> <discussion_id> <body>` - Reply to discussion
- `resolve-discussion.sh <iid> <discussion_id>` - Resolve discussion
EOF
