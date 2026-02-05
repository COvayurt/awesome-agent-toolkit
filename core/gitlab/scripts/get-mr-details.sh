#!/bin/bash
# Get GitLab Merge Request details
# Usage: ./get-mr-details.sh <mr_iid>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"

if [ -z "$MR_IID" ]; then
    echo "Error: MR IID is required"
    echo "Usage: ./get-mr-details.sh <mr_iid>"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${API_URL}" | \
    jq '{
        iid: .iid,
        title: .title,
        description: .description,
        state: .state,
        author: .author.username,
        assignees: [.assignees[].username],
        reviewers: [.reviewers[].username],
        source_branch: .source_branch,
        target_branch: .target_branch,
        created_at: .created_at,
        updated_at: .updated_at,
        merged_at: .merged_at,
        closed_at: .closed_at,
        web_url: .web_url,
        has_conflicts: .has_conflicts,
        draft: .draft,
        labels: .labels,
        milestone: .milestone.title,
        changes_count: .changes_count,
        user_notes_count: .user_notes_count
    }'
