#!/bin/bash
# Post an inline diff comment on a GitLab Merge Request
# Usage: ./post-mr-diff-comment.sh <mr_iid> <json_payload>
# json_payload: JSON object with body and position fields
#
# Required fields: body, position.base_sha, position.head_sha,
#                  position.start_sha, position.new_path
# Optional fields: position.old_path, position.new_line, position.old_line

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"
JSON_PAYLOAD="${2}"

if [ -z "$MR_IID" ] || [ -z "$JSON_PAYLOAD" ]; then
    echo "Error: MR IID and JSON payload are required"
    echo "Usage: ./post-mr-diff-comment.sh <mr_iid> <json_payload>"
    echo ""
    echo "JSON payload fields:"
    echo "  - body: Comment text (required)"
    echo "  - position.base_sha: Base commit SHA (required)"
    echo "  - position.head_sha: Head commit SHA (required)"
    echo "  - position.start_sha: Start commit SHA (required)"
    echo "  - position.new_path: File path on new side (required)"
    echo "  - position.old_path: File path on old side (optional, defaults to new_path)"
    echo "  - position.new_line: Line number on new side (optional)"
    echo "  - position.old_line: Line number on old side (optional)"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/discussions"

curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "$JSON_PAYLOAD" \
    "${API_URL}" | \
    jq '{
        discussion_id: .id,
        note_id: .notes[0].id,
        body: .notes[0].body,
        author: .notes[0].author.username,
        created_at: .notes[0].created_at,
        position: {
            file: .notes[0].position.new_path,
            new_line: .notes[0].position.new_line,
            old_line: .notes[0].position.old_line
        },
        status: "Inline comment posted successfully"
    }'
