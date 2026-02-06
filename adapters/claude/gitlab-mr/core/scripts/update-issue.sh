#!/bin/bash
# Update a GitLab Issue (description, milestone, assignees, labels, etc.)
# Usage: ./update-issue.sh <issue_iid> <json_payload>
# json_payload: JSON object with fields to update

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

ISSUE_IID="${1}"
JSON_PAYLOAD="${2}"

if [ -z "$ISSUE_IID" ] || [ -z "$JSON_PAYLOAD" ]; then
    echo "Error: Issue IID and JSON payload are required"
    echo "Usage: ./update-issue.sh <issue_iid> <json_payload>"
    echo ""
    echo "Supported fields in JSON payload:"
    echo "  - description: Issue description (markdown)"
    echo "  - milestone_id: Milestone ID (number or null to remove)"
    echo "  - assignee_ids: Array of user IDs [1, 2, 3]"
    echo "  - labels: Comma-separated labels or array"
    echo "  - title: Issue title"
    echo "  - state_event: 'close' or 'reopen'"
    echo "  - due_date: Due date (YYYY-MM-DD)"
    echo "  - weight: Issue weight (number)"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues/${ISSUE_IID}"

curl -s --request PUT \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "$JSON_PAYLOAD" \
    "${API_URL}" | \
    jq '{
        iid: .iid,
        title: .title,
        description: .description,
        state: .state,
        assignees: [.assignees[].username],
        milestone: .milestone.title,
        labels: .labels,
        updated_at: .updated_at,
        status: "Issue updated successfully"
    }'
