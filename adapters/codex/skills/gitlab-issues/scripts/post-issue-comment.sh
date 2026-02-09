#!/bin/bash
# Post a comment to a GitLab Issue
# Usage: ./post-issue-comment.sh <issue_iid> <comment_body>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

ISSUE_IID="${1}"
COMMENT_BODY="${2}"

if [ -z "$ISSUE_IID" ] || [ -z "$COMMENT_BODY" ]; then
    echo "Error: Issue IID and comment body are required"
    echo "Usage: ./post-issue-comment.sh <issue_iid> <comment_body>"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues/${ISSUE_IID}/notes"

curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{\"body\": $(echo "$COMMENT_BODY" | jq -Rs .)}" \
    "${API_URL}" | \
    jq '{
        id: .id,
        body: .body,
        author: .author.username,
        created_at: .created_at,
        status: "Comment posted successfully"
    }'
