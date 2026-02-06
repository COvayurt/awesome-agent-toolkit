#!/bin/bash
# Get GitLab Issue details
# Usage: ./get-issue-details.sh <issue_iid>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

ISSUE_IID="${1}"

if [ -z "$ISSUE_IID" ]; then
    echo "Error: Issue IID is required"
    echo "Usage: ./get-issue-details.sh <issue_iid>"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/issues/${ISSUE_IID}"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${API_URL}" | \
    jq '{
        iid: .iid,
        title: .title,
        description: .description,
        state: .state,
        author: .author.username,
        assignees: [.assignees[].username],
        labels: .labels,
        milestone: .milestone.title,
        milestone_id: .milestone.id,
        due_date: .due_date,
        created_at: .created_at,
        updated_at: .updated_at,
        closed_at: .closed_at,
        closed_by: .closed_by.username,
        web_url: .web_url,
        time_stats: .time_stats,
        task_completion_status: .task_completion_status,
        has_tasks: .has_tasks,
        task_status: .task_status,
        weight: .weight
    }'
