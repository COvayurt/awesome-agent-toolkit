#!/bin/bash
# List GitLab Merge Requests
# Usage: ./list-mrs.sh [state] [per_page]
# state: opened, closed, merged, all (default: opened)
# per_page: number of MRs to fetch (default: 20)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

STATE="${1:-opened}"
PER_PAGE="${2:-20}"

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

# URL encode the project ID if it contains slashes
ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')

API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?state=${STATE}&per_page=${PER_PAGE}&order_by=updated_at&sort=desc" | \
    jq '[.[] | {
        iid: .iid,
        title: .title,
        state: .state,
        author: .author.username,
        source_branch: .source_branch,
        target_branch: .target_branch,
        created_at: .created_at,
        updated_at: .updated_at,
        web_url: .web_url,
        has_conflicts: .has_conflicts,
        draft: .draft,
        labels: .labels
    }]'
