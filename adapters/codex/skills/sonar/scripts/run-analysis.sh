#!/bin/bash
# run-analysis.sh — Runs SonarQube analysis using Gradle
#
# Usage:
#   ./run-analysis.sh
#
# Environment variables required:
#   SONAR_HOST_URL    - SonarQube server URL
#   SONAR_TOKEN       - Authentication token
#   SONAR_PROJECT_KEY - Project key in SonarQube
#
# Must be run from the project root directory.

set -euo pipefail

# Check required environment variables
if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    echo "Error: SONAR_HOST_URL, SONAR_TOKEN, and SONAR_PROJECT_KEY must be set" >&2
    exit 1
fi

echo "Running SonarQube analysis..."
echo "Host: $SONAR_HOST_URL"
echo "Project: $SONAR_PROJECT_KEY"

# Run Gradle sonar task
./gradlew sonar \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    --console=plain

echo ""
echo "SonarQube analysis complete!"
echo "View results at: ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
