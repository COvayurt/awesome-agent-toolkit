#!/bin/bash
# session-start-hook.sh — SessionStart hook for gitlab-issues
#
# Auto-loads assigned issues at session start so Claude
# already knows the user's current work context.

set -euo pipefail

# Check required environment variables
if [ -z "${GITLAB_HOST_URL:-}" ] || [ -z "${GITLAB_TOKEN:-}" ] || [ -z "${GITLAB_PROJECT_ID:-}" ]; then
    exit 0
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')

# Get current user
CURRENT_USER=$(curl -s --max-time 5 --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_HOST_URL}/api/v4/user" 2>/dev/null | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('username',''))" 2>/dev/null || echo "")

if [ -z "$CURRENT_USER" ]; then
    exit 0
fi

# Fetch open issues assigned to current user
ISSUES=$(curl -s --max-time 5 --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues?state=opened&assignee_username=${CURRENT_USER}&per_page=10&order_by=updated_at&sort=desc" 2>/dev/null || echo "")

if [ -z "$ISSUES" ] || [ "$ISSUES" = "[]" ]; then
    exit 0
fi

python3 -c "
import json, sys

try:
    issues = json.loads('''$ISSUES''')
    if not issues:
        sys.exit(0)

    print('## Your Assigned Issues (Auto-loaded)')
    print('')
    print('| IID | Title | Labels | Milestone |')
    print('|-----|-------|--------|-----------|')

    for issue in issues[:10]:
        iid = issue.get('iid', '')
        title = issue.get('title', '')[:60]
        labels = ', '.join(issue.get('labels', []))[:25] or '-'
        ms = (issue.get('milestone') or {}).get('title', '-') or '-'
        print(f'| #{iid} | {title} | {labels} | {ms} |')

    total = len(issues)
    if total > 10:
        print(f'\n_Showing 10 of {total} assigned issues_')
except Exception:
    pass
" 2>/dev/null
