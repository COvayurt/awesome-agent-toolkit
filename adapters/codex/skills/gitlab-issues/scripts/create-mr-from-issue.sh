#!/bin/bash
# Create a Merge Request from an Issue with a source branch
# Usage: ./create-mr-from-issue.sh <issue_iid> <source_branch> [target_branch]
# target_branch defaults to the project's default branch

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

ISSUE_IID="${1}"
SOURCE_BRANCH="${2}"
TARGET_BRANCH="${3:-}"

if [ -z "$ISSUE_IID" ] || [ -z "$SOURCE_BRANCH" ]; then
    echo "Error: Issue IID and source branch are required"
    echo "Usage: ./create-mr-from-issue.sh <issue_iid> <source_branch> [target_branch]"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')

# First, get the issue details for the MR title
ISSUE_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues/${ISSUE_IID}"
ISSUE_DATA=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${ISSUE_URL}")
ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')

# If no target branch specified, get the project's default branch
if [ -z "$TARGET_BRANCH" ]; then
    PROJECT_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}"
    TARGET_BRANCH=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${PROJECT_URL}" | jq -r '.default_branch')
fi

# Create the MR
MR_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests"

# Build the MR title with issue reference
MR_TITLE="Resolve \"${ISSUE_TITLE}\""
MR_DESCRIPTION="Closes #${ISSUE_IID}"

curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
        \"source_branch\": \"${SOURCE_BRANCH}\",
        \"target_branch\": \"${TARGET_BRANCH}\",
        \"title\": $(echo "$MR_TITLE" | jq -Rs .),
        \"description\": \"${MR_DESCRIPTION}\",
        \"remove_source_branch\": true
    }" \
    "${MR_URL}" | \
    jq '{
        iid: .iid,
        title: .title,
        description: .description,
        source_branch: .source_branch,
        target_branch: .target_branch,
        state: .state,
        web_url: .web_url,
        status: "Merge request created successfully"
    }'
