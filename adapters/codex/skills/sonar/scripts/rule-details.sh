#!/bin/bash
# rule-details.sh — Fetch rule explanation from SonarQube
#
# Usage:
#   ./rule-details.sh --rule <rule-key>
#
# Example:
#   ./rule-details.sh --rule java:S2140
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#
# Outputs JSON with rule details including description and examples.

set -euo pipefail

if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ]; then
    echo "Error: SONAR_HOST_URL and SONAR_TOKEN must be set" >&2
    exit 1
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Parse arguments
RULE_KEY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --rule)
            RULE_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$RULE_KEY" ]; then
    echo "Error: --rule <rule-key> is required" >&2
    echo "Example: ./rule-details.sh --rule java:S2140" >&2
    exit 1
fi

# Build API URL
API_URL="${SONAR_HOST_URL}/api/rules/show?key=${RULE_KEY}"

# Fetch rule details
RESPONSE=$(curl -s -f -u "${SONAR_TOKEN}:" "$API_URL" 2>&1)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "Error: Failed to fetch rule details for ${RULE_KEY}" >&2
    exit 1
fi

echo "$RESPONSE"
