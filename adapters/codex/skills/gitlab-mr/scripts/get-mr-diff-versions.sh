#!/bin/bash
# Get MR diff versions to obtain SHA values needed for line-level comments
# Usage: ./get-mr-diff-versions.sh <mr_iid>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"

if [ -z "$MR_IID" ]; then
    echo "Error: MR IID is required"
    echo "Usage: ./get-mr-diff-versions.sh <mr_iid>"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/versions"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${API_URL}" | \
    jq '[.[] | {
        id: .id,
        base_commit_sha: .base_commit_sha,
        head_commit_sha: .head_commit_sha,
        start_commit_sha: .start_commit_sha,
        created_at: .created_at
    }]'
