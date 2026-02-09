#!/bin/bash
# Create a GitLab Sub-Issue (child issue linked to a parent)
# Usage: ./create-sub-issue.sh <parent_issue_iid> <json_payload>
#
# Creates a new issue and links it as a child of the parent issue.
# Uses GitLab issue links API with link_type.
#
# Required: parent_issue_iid, json_payload with title
# Optional fields in payload: description, labels, assignee_ids,
#                              milestone_id, due_date, weight, confidential

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

PARENT_ISSUE_IID="${1}"
JSON_PAYLOAD="${2}"

if [ -z "$PARENT_ISSUE_IID" ] || [ -z "$JSON_PAYLOAD" ]; then
    echo "Error: Parent issue IID and JSON payload are required"
    echo "Usage: ./create-sub-issue.sh <parent_issue_iid> <json_payload>"
    echo ""
    echo "Required fields in JSON payload:"
    echo "  - title: Sub-issue title (string)"
    echo ""
    echo "Optional fields:"
    echo "  - description: Issue description (markdown)"
    echo "  - labels: Comma-separated labels or array"
    echo "  - assignee_ids: Array of user IDs [1, 2, 3]"
    echo "  - milestone_id: Milestone ID (number)"
    echo "  - due_date: Due date (YYYY-MM-DD)"
    echo "  - weight: Issue weight (number)"
    echo "  - confidential: Boolean (true/false)"
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

# Step 1: Create the child issue
ISSUES_API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues"

CREATE_RESPONSE=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "$JSON_PAYLOAD" \
    "${ISSUES_API_URL}")

CHILD_IID=$(echo "$CREATE_RESPONSE" | jq -r '.iid // empty')
CHILD_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id // empty')

if [ -z "$CHILD_IID" ] || [ "$CHILD_IID" = "null" ]; then
    echo "Error: Failed to create child issue"
    echo "$CREATE_RESPONSE" | jq '.' 2>/dev/null || echo "$CREATE_RESPONSE"
    exit 1
fi

# Step 2: Link child issue to parent using issue links API
# Try is_child_of first (GitLab 16.0+ Premium), fall back to relates_to
LINKS_API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues/${PARENT_ISSUE_IID}/links"

LINK_RESPONSE=$(curl -s -w "\n%{http_code}" --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{\"target_project_id\": \"${GITLAB_PROJECT_ID}\", \"target_issue_iid\": \"${CHILD_IID}\", \"link_type\": \"is_parent_of\"}" \
    "${LINKS_API_URL}")

HTTP_CODE=$(echo "$LINK_RESPONSE" | tail -1)
LINK_BODY=$(echo "$LINK_RESPONSE" | sed '$d')

LINK_TYPE="is_parent_of"

# If is_parent_of not supported (older GitLab or non-Premium), try relates_to
if [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "200" ]; then
    LINK_RESPONSE=$(curl -s -w "\n%{http_code}" --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"target_project_id\": \"${GITLAB_PROJECT_ID}\", \"target_issue_iid\": \"${CHILD_IID}\", \"link_type\": \"relates_to\"}" \
        "${LINKS_API_URL}")

    HTTP_CODE=$(echo "$LINK_RESPONSE" | tail -1)
    LINK_BODY=$(echo "$LINK_RESPONSE" | sed '$d')
    LINK_TYPE="relates_to (is_parent_of not available - requires GitLab Premium 16.0+)"
fi

# Output the result
echo "$CREATE_RESPONSE" | jq --arg link_type "$LINK_TYPE" --arg parent_iid "$PARENT_ISSUE_IID" '{
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
    parent_issue_iid: ($parent_iid | tonumber),
    link_type: $link_type,
    status: "Sub-issue created and linked successfully"
}'
