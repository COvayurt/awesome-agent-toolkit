#!/bin/bash
# Reply to a discussion thread on a GitLab Merge Request
# Usage: ./reply-to-discussion.sh <mr_iid> <discussion_id> <comment_body>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"
DISCUSSION_ID="${2}"
COMMENT_BODY="${3}"

if [ -z "$MR_IID" ] || [ -z "$DISCUSSION_ID" ] || [ -z "$COMMENT_BODY" ]; then
    echo "Error: MR IID, discussion ID, and comment body are required"
    echo "Usage: ./reply-to-discussion.sh <mr_iid> <discussion_id> <comment_body>"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/discussions/${DISCUSSION_ID}/notes"

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
        status: "Reply posted successfully"
    }'
