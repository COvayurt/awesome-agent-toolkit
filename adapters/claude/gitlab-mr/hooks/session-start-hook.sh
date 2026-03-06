#!/bin/bash
# session-start-hook.sh — SessionStart hook for gitlab-mr
#
# Auto-loads open MRs authored by or assigned to the current user
# at session start so Claude already knows the MR context.

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

API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests"

# Fetch MRs authored by current user
AUTHORED=$(curl -s --max-time 5 --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?state=opened&author_username=${CURRENT_USER}&per_page=10&order_by=updated_at&sort=desc" 2>/dev/null || echo "[]")

# Fetch MRs where current user is reviewer
REVIEWING=$(curl -s --max-time 5 --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?state=opened&reviewer_username=${CURRENT_USER}&per_page=10&order_by=updated_at&sort=desc" 2>/dev/null || echo "[]")

python3 -c "
import json, sys

def print_table(mrs, label):
    if not mrs:
        return False
    print(f'### {label}')
    print('')
    print('| IID | Title | Source → Target | Draft | Conflicts |')
    print('|-----|-------|-----------------|-------|-----------|')
    for mr in mrs[:10]:
        iid = mr.get('iid', '')
        title = mr.get('title', '')[:50]
        source = mr.get('source_branch', '')
        target = mr.get('target_branch', '')
        draft = 'Yes' if mr.get('draft') else 'No'
        conflicts = 'Yes' if mr.get('has_conflicts') else 'No'
        print(f'| !{iid} | {title} | {source} → {target} | {draft} | {conflicts} |')
    print('')
    return True

try:
    authored = json.loads('''$AUTHORED''') if '''$AUTHORED''' != '[]' else []
    reviewing = json.loads('''$REVIEWING''') if '''$REVIEWING''' != '[]' else []

    if not authored and not reviewing:
        sys.exit(0)

    print('## Your Open Merge Requests (Auto-loaded)')
    print('')
    print_table(authored, 'Authored by you')
    print_table(reviewing, 'Awaiting your review')
except Exception:
    pass
" 2>/dev/null
