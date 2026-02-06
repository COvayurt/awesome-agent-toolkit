#!/bin/bash
# List GitLab Project Members (for assigning issues)
# Usage: ./list-project-members.sh [per_page]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

PER_PAGE="${1:-100}"

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/members/all"

curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${API_URL}?per_page=${PER_PAGE}" | \
    jq '[.[] | {
        id: .id,
        username: .username,
        name: .name,
        state: .state,
        access_level: .access_level,
        access_level_description: (
            if .access_level == 50 then "Owner"
            elif .access_level == 40 then "Maintainer"
            elif .access_level == 30 then "Developer"
            elif .access_level == 20 then "Reporter"
            elif .access_level == 10 then "Guest"
            else "Unknown"
            end
        )
    }]'
