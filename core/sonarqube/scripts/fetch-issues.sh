#!/bin/bash
# fetch-issues.sh — Fetches open issues from SonarQube API
#
# Usage:
#   ./fetch-issues.sh                    # Fetch all open issues (paginated)
#   ./fetch-issues.sh --file <path>      # Fetch issues for a specific file
#   ./fetch-issues.sh --severity <level> # Filter by impact severity (HIGH,MEDIUM,LOW)
#   ./fetch-issues.sh --new-code         # Only issues in new code period
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#   SONAR_PROJECT_KEY - Project key in SonarQube
#
# Outputs JSON to stdout.

set -euo pipefail

# Check required environment variables
if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    echo "Error: SONAR_HOST_URL, SONAR_TOKEN, and SONAR_PROJECT_KEY must be set" >&2
    exit 1
fi

# Strip trailing slash from host URL
SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Parse arguments
FILE_FILTER=""
SEVERITY_FILTER=""
NEW_CODE=false
PAGE_SIZE=100

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            FILE_FILTER="$2"
            shift 2
            ;;
        --severity)
            SEVERITY_FILTER="$2"
            shift 2
            ;;
        --new-code)
            NEW_CODE=true
            shift
            ;;
        --page-size)
            PAGE_SIZE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Build API URL
if [ "$NEW_CODE" = true ]; then
    API_URL="${SONAR_HOST_URL}/api/issues/search?componentKeys=${SONAR_PROJECT_KEY}"
    API_URL="${API_URL}&inNewCodePeriod=true"
else
    API_URL="${SONAR_HOST_URL}/api/issues/search?projectKeys=${SONAR_PROJECT_KEY}"
fi
API_URL="${API_URL}&statuses=OPEN,CONFIRMED,REOPENED"
API_URL="${API_URL}&ps=${PAGE_SIZE}"
API_URL="${API_URL}&s=SEVERITY&asc=false"

if [ -n "$FILE_FILTER" ]; then
    COMPONENT_KEY="${SONAR_PROJECT_KEY}:${FILE_FILTER}"
    API_URL="${API_URL}&components=${COMPONENT_KEY}"
fi

if [ -n "$SEVERITY_FILTER" ]; then
    API_URL="${API_URL}&impactSeverities=${SEVERITY_FILTER}"
fi

# Fetch issues
RESPONSE=$(curl -s -f -u "${SONAR_TOKEN}:" "$API_URL" 2>&1)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "Error: Failed to reach SonarQube at ${SONAR_HOST_URL}" >&2
    echo "curl exit code: $CURL_EXIT" >&2
    echo "$RESPONSE" >&2
    exit 1
fi

# Validate JSON response
if ! echo "$RESPONSE" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    echo "Error: Invalid JSON response from SonarQube API" >&2
    echo "$RESPONSE" | head -5 >&2
    exit 1
fi

# Output JSON to stdout
echo "$RESPONSE"
