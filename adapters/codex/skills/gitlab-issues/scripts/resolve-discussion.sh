#!/bin/bash
# Resolve or unresolve a discussion thread on a GitLab Merge Request
# Usage: ./resolve-discussion.sh <mr_iid> <discussion_id> [resolve]
# resolve: true or false (default: true)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"
DISCUSSION_ID="${2}"
RESOLVE="${3:-true}"

if [ -z "$MR_IID" ] || [ -z "$DISCUSSION_ID" ]; then
    echo "Error: MR IID and discussion ID are required"
    echo "Usage: ./resolve-discussion.sh <mr_iid> <discussion_id> [resolve]"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/discussions/${DISCUSSION_ID}"

curl -s --request PUT \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{\"resolved\": ${RESOLVE}}" \
    "${API_URL}" | \
    jq '{
        id: .id,
        resolved: (if .notes[0].resolved then "resolved" else "unresolved" end),
        notes_count: (.notes | length)
    }'
