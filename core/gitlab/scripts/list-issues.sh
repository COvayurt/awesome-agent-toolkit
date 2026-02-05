#!/bin/bash
# List GitLab Issues
# Usage: ./list-issues.sh [state] [milestone] [per_page]
# state: opened, closed, all (default: opened)
# milestone: milestone title or "none" or "any" (optional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

STATE="${1:-opened}"
MILESTONE="${2:-}"
PER_PAGE="${3:-20}"

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues"

# Build query params
PARAMS="state=${STATE}&per_page=${PER_PAGE}&order_by=updated_at&sort=desc"

if [ -n "$MILESTONE" ]; then
    ENCODED_MILESTONE=$(echo "$MILESTONE" | jq -sRr @uri)
    PARAMS="${PARAMS}&milestone=${ENCODED_MILESTONE}"
fi

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?${PARAMS}" | \
    jq '[.[] | {
        iid: .iid,
        title: .title,
        state: .state,
        author: .author.username,
        assignees: [.assignees[].username],
        labels: .labels,
        milestone: .milestone.title,
        created_at: .created_at,
        updated_at: .updated_at,
        web_url: .web_url,
        has_tasks: .has_tasks,
        task_status: .task_status
    }]'
