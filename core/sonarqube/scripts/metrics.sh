#!/bin/bash
# metrics.sh — Fetch project metrics from SonarQube
#
# Usage:
#   ./metrics.sh                      # Fetch default metrics
#   ./metrics.sh --metrics <list>     # Fetch specific metrics (comma-separated)
#   ./metrics.sh --branch <branch>    # Fetch for specific branch
#
# Default metrics: coverage, duplicated_lines_density, bugs, vulnerabilities,
#                  code_smells, security_hotspots, cognitive_complexity, ncloc
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#   SONAR_PROJECT_KEY - Project key in SonarQube
#
# Outputs JSON with metric values.

set -euo pipefail

if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    echo "Error: SONAR_HOST_URL, SONAR_TOKEN, and SONAR_PROJECT_KEY must be set" >&2
    exit 1
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Default metrics
DEFAULT_METRICS="coverage,duplicated_lines_density,bugs,vulnerabilities,code_smells,security_hotspots,cognitive_complexity,ncloc,sqale_index,reliability_rating,security_rating,sqale_rating"

# Parse arguments
METRICS="$DEFAULT_METRICS"
BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --metrics)
            METRICS="$2"
            shift 2
            ;;
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
API_URL="${SONAR_HOST_URL}/api/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=${METRICS}"

if [ -n "$BRANCH" ]; then
    API_URL="${API_URL}&branch=${BRANCH}"
fi

# Fetch metrics
RESPONSE=$(curl -s -f -u "${SONAR_TOKEN}:" "$API_URL" 2>&1)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "Error: Failed to fetch metrics" >&2
    exit 1
fi

echo "$RESPONSE"
