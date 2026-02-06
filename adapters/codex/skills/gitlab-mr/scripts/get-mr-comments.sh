#!/bin/bash
# Get GitLab Merge Request comments/notes
# Usage: ./get-mr-comments.sh <mr_iid> [per_page]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"
PER_PAGE="${2:-50}"

if [ -z "$MR_IID" ]; then
    echo "Error: MR IID is required"
    echo "Usage: ./get-mr-comments.sh <mr_iid> [per_page]"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/notes"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?per_page=${PER_PAGE}&sort=asc" | \
    jq '[.[] | {
        id: .id,
        body: .body,
        author: .author.username,
        created_at: .created_at,
        updated_at: .updated_at,
        system: .system,
        resolvable: .resolvable,
        resolved: .resolved,
        resolved_by: .resolved_by.username,
        type: .type,
        noteable_type: "MergeRequest"
    }]'
