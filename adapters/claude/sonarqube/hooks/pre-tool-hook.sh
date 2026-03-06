#!/bin/bash
# pre-tool-hook.sh — PreToolUse hook for sonarqube
#
# Before Claude edits a file, fetches the top violated rules
# for the project and injects them as guidelines to follow.
# Uses a cache to avoid repeated API calls within the same session.

set -euo pipefail

# Check required environment variables
if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    exit 0
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Cache rules for 30 minutes to avoid hammering the API on every edit
CACHE_FILE="/tmp/.sonar-rules-cache-${SONAR_PROJECT_KEY//\//_}"
CACHE_TTL=1800

if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0") ))
    if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch top violated rules using issue facets
RESPONSE=$(curl -s --max-time 5 -u "${SONAR_TOKEN}:" \
    "${SONAR_HOST_URL}/api/issues/search?projectKeys=${SONAR_PROJECT_KEY}&statuses=OPEN,CONFIRMED,REOPENED&ps=1&facets=rules" 2>/dev/null || echo "")

if [ -z "$RESPONSE" ]; then
    exit 0
fi

OUTPUT=$(python3 -c "
import json, sys

try:
    data = json.loads('''$(echo "$RESPONSE" | sed "s/'''/'/g")''')
    facets = data.get('facets', [])

    rules = []
    for facet in facets:
        if facet.get('property') == 'rules':
            values = facet.get('values', [])
            rules = sorted(values, key=lambda x: x.get('count', 0), reverse=True)[:10]
            break

    if not rules:
        sys.exit(0)

    print('## SonarQube: Top Violated Rules for This Project')
    print('')
    print('**Avoid these common violations while writing code:**')
    print('')
    print('| Rule | Occurrences |')
    print('|------|-------------|')
    for r in rules:
        rule_key = r.get('val', '')
        count = r.get('count', 0)
        print(f'| \`{rule_key}\` | {count} |')
    print('')
    print('Follow these rules to keep code quality high.')
except Exception:
    pass
" 2>/dev/null || echo "")

if [ -n "$OUTPUT" ]; then
    echo "$OUTPUT" > "$CACHE_FILE"
    echo "$OUTPUT"
fi
