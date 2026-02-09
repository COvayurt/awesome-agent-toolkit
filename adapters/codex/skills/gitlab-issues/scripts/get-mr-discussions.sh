#!/bin/bash
# Get GitLab Merge Request discussions (threaded comments)
# Usage: ./get-mr-discussions.sh <mr_iid> [per_page]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

MR_IID="${1}"
PER_PAGE="${2:-100}"

if [ -z "$MR_IID" ]; then
    echo "Error: MR IID is required"
    echo "Usage: ./get-mr-discussions.sh <mr_iid> [per_page]"
    exit 1
fi

if [ -z "$GITLAB_HOST_URL" ] || [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: GITLAB_HOST_URL, GITLAB_TOKEN, GITLAB_PROJECT_ID"
    exit 1
fi

ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
API_URL="${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests/${MR_IID}/discussions"

# Fetch all pages of discussions
ALL_DISCUSSIONS="[]"
PAGE=1

while true; do
    RESPONSE=$(curl -s -D - --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${API_URL}?per_page=${PER_PAGE}&page=${PAGE}")

    # Split headers and body
    HEADERS=$(echo "$RESPONSE" | sed '/^\r$/q')
    BODY=$(echo "$RESPONSE" | sed '1,/^\r$/d')

    # Merge this page into accumulated results
    ALL_DISCUSSIONS=$(echo "$ALL_DISCUSSIONS" "$BODY" | jq -s '.[0] + .[1]')

    # Check if there's a next page
    NEXT_PAGE=$(echo "$HEADERS" | grep -i '^x-next-page:' | tr -d '\r' | awk '{print $2}')

    if [ -z "$NEXT_PAGE" ] || [ "$NEXT_PAGE" = "" ]; then
        break
    fi

    PAGE=$NEXT_PAGE
done

echo "$ALL_DISCUSSIONS" | \
    jq '[.[] | {
        id: .id,
        individual_note: .individual_note,
        notes: [.notes[] | {
            id: .id,
            body: .body,
            author: .author.username,
            created_at: .created_at,
            system: .system,
            resolvable: .resolvable,
            resolved: .resolved,
            resolved_by: .resolved_by.username,
            position: (if .position then {
                file_path: .position.new_path,
                old_line: .position.old_line,
                new_line: .position.new_line
            } else null end)
        }]
    }]'
