#!/bin/bash
# quality-gate.sh — Check quality gate status for the project
#
# Usage:
#   ./quality-gate.sh
#   ./quality-gate.sh --branch <branch-name>
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#   SONAR_PROJECT_KEY - Project key in SonarQube
#
# Outputs JSON with quality gate status.

set -euo pipefail

if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    echo "Error: SONAR_HOST_URL, SONAR_TOKEN, and SONAR_PROJECT_KEY must be set" >&2
    exit 1
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Parse arguments
BRANCH=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Build API URL
API_URL="${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}"

if [ -n "$BRANCH" ]; then
    API_URL="${API_URL}&branch=${BRANCH}"
fi

# Fetch quality gate status
RESPONSE=$(curl -s -f -u "${SONAR_TOKEN}:" "$API_URL" 2>&1)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "Error: Failed to fetch quality gate status" >&2
    exit 1
fi

echo "$RESPONSE"
