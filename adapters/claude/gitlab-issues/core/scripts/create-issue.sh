#!/bin/bash
# Create a GitLab Issue
# Usage: ./create-issue.sh <json_payload>
# json_payload: JSON object with issue fields
#
# Required fields: title
# Optional fields: description, labels, assignee_ids, milestone_id,
#                  due_date, weight, confidential, issue_type

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

JSON_PAYLOAD="${1}"

if [ -z "$JSON_PAYLOAD" ]; then
    echo "Error: JSON payload is required"
    echo "Usage: ./create-issue.sh <json_payload>"
    echo ""
    echo "Required fields in JSON payload:"
    echo "  - title: Issue title (string)"
    echo ""
    echo "Optional fields:"
    echo "  - description: Issue description (markdown)"
    echo "  - labels: Comma-separated labels or array"
    echo "  - assignee_ids: Array of user IDs [1, 2, 3]"
    echo "  - milestone_id: Milestone ID (number)"
    echo "  - due_date: Due date (YYYY-MM-DD)"
    echo "  - weight: Issue weight (number)"
    echo "  - confidential: Boolean (true/false)"
    echo "  - issue_type: 'issue', 'incident', or 'task'"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

# Validate that title is present in the payload
TITLE=$(echo "$JSON_PAYLOAD" | jq -r '.title // empty')
if [ -z "$TITLE" ]; then
    echo "Error: 'title' field is required in JSON payload"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues"

curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "$JSON_PAYLOAD" \
    "${API_URL}" | \
    jq '{
        iid: .iid,
        title: .title,
        description: .description,
        state: .state,
        author: .author.username,
        assignees: [.assignees[].username],
        milestone: .milestone.title,
        labels: .labels,
        web_url: .web_url,
        created_at: .created_at,
        status: "Issue created successfully"
    }'
