#!/bin/bash
# session-start-hook.sh — SessionStart hook for sonarqube
#
# Auto-loads quality gate status and critical issue count
# at session start so Claude knows the project's health.

set -euo pipefail

# Check required environment variables
if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    exit 0
fi

SONAR_HOST_URL="${SONAR_HOST_URL%/}"

# Fetch quality gate status
QG_RESPONSE=$(curl -s --max-time 5 -u "${SONAR_TOKEN}:" \
    "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}" 2>/dev/null || echo "")

# Fetch critical/blocker issue counts
ISSUES_RESPONSE=$(curl -s --max-time 5 -u "${SONAR_TOKEN}:" \
    "${SONAR_HOST_URL}/api/issues/search?projectKeys=${SONAR_PROJECT_KEY}&statuses=OPEN,CONFIRMED,REOPENED&ps=1&facets=impactSeverities" 2>/dev/null || echo "")

python3 -c "
import json, sys

try:
    qg_raw = '''$QG_RESPONSE'''
    issues_raw = '''$ISSUES_RESPONSE'''

    if not qg_raw and not issues_raw:
        sys.exit(0)

    print('## SonarQube Project Health (Auto-loaded)')
    print('')

    # Quality gate
    if qg_raw:
        qg = json.loads(qg_raw)
        status = qg.get('projectStatus', {}).get('status', 'UNKNOWN')
        icon = 'PASSED' if status == 'OK' else 'FAILED' if status == 'ERROR' else status
        print(f'**Quality Gate:** {icon}')

        conditions = qg.get('projectStatus', {}).get('conditions', [])
        failed = [c for c in conditions if c.get('status') == 'ERROR']
        if failed:
            print('')
            print('**Failed conditions:**')
            for c in failed:
                metric = c.get('metricKey', '')
                actual = c.get('actualValue', '')
                threshold = c.get('errorThreshold', '')
                print(f'- {metric}: {actual} (threshold: {threshold})')

    # Issue counts by severity
    if issues_raw:
        data = json.loads(issues_raw)
        total = data.get('total', 0)
        print(f'')
        print(f'**Open Issues:** {total}')

        facets = data.get('facets', [])
        for facet in facets:
            if facet.get('property') == 'impactSeverities':
                values = facet.get('values', [])
                counts = {v['val']: v['count'] for v in values if v.get('count', 0) > 0}
                if counts:
                    parts = [f'{k}: {v}' for k, v in sorted(counts.items())]
                    print(f'**By Severity:** {\" | \".join(parts)}')

    print('')
    print(f'**Dashboard:** {'''${SONAR_HOST_URL}'''}/dashboard?id={'''${SONAR_PROJECT_KEY}'''}')
except Exception:
    pass
" 2>/dev/null
