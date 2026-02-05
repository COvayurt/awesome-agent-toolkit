#!/bin/bash
# hotspots.sh — Fetch security hotspots from SonarQube
#
# Usage:
#   ./hotspots.sh                         # Fetch all hotspots to review
#   ./hotspots.sh --status <status>       # Filter by status (TO_REVIEW, REVIEWED)
#   ./hotspots.sh --file <path>           # Filter by file
#   ./hotspots.sh --branch <branch>       # Filter by branch
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#   SONAR_PROJECT_KEY - Project key in SonarQube
#
# Outputs JSON with security hotspots.

set -euo pipefail

if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    echo "Error: SONAR_HOST_URL, SONAR_TOKEN, and SONAR_PROJECT_KEY must be set" >&2
    exit 1
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Parse arguments
STATUS="TO_REVIEW"
FILE_FILTER=""
BRANCH=""
PAGE_SIZE=100

while [[ $# -gt 0 ]]; do
    case $1 in
        --status)
            STATUS="$2"
            shift 2
            ;;
        --file)
            FILE_FILTER="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
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
API_URL="${SONAR_HOST_URL}/api/hotspots/search?projectKey=${SONAR_PROJECT_KEY}"
API_URL="${API_URL}&status=${STATUS}"
API_URL="${API_URL}&ps=${PAGE_SIZE}"

if [ -n "$FILE_FILTER" ]; then
    API_URL="${API_URL}&files=${FILE_FILTER}"
fi

if [ -n "$BRANCH" ]; then
    API_URL="${API_URL}&branch=${BRANCH}"
fi

# Fetch hotspots
RESPONSE=$(curl -s -f -u "${SONAR_TOKEN}:" "$API_URL" 2>&1)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "Error: Failed to fetch security hotspots" >&2
    exit 1
fi

echo "$RESPONSE"
