#!/bin/bash
# post-tool-hook.sh — PostToolUse hook for sonarqube
#
# Tracks cumulative line changes from Edit/Write tool calls.
# When changes exceed the threshold (50 lines), instructs Claude
# to run SonarQube analysis and check for new code issues.

set -euo pipefail

# Check required environment variables
if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ] || [ -z "${SONAR_PROJECT_KEY:-}" ]; then
    exit 0
fi

# Read tool context from stdin
INPUT=$(cat)

# Count changed lines based on tool type
CHANGED_LINES=$(python3 -c "
import json, sys

try:
    data = json.loads('''$(echo "$INPUT" | sed "s/'''/\"/g")''')
    tool_name = data.get('tool_name', '')
    tool_input = data.get('tool_input', {})

    if tool_name == 'Edit':
        old = tool_input.get('old_string', '')
        new = tool_input.get('new_string', '')
        old_lines = old.count('\n') + (1 if old and not old.endswith('\n') else 0)
        new_lines = new.count('\n') + (1 if new and not new.endswith('\n') else 0)
        print(abs(new_lines - old_lines) + min(old_lines, new_lines))
    elif tool_name == 'Write':
        content = tool_input.get('content', '')
        print(content.count('\n') + (1 if content and not content.endswith('\n') else 0))
    else:
        print(0)
except Exception:
    print(0)
" 2>/dev/null || echo "0")

if [ "$CHANGED_LINES" -eq 0 ] 2>/dev/null; then
    exit 0
fi

# Cumulative tracking using a temp file keyed by project
COUNTER_FILE="/tmp/.sonar-change-counter-${SONAR_PROJECT_KEY//\//_}"
THRESHOLD=50

CURRENT_COUNT=0
if [ -f "$COUNTER_FILE" ]; then
    CURRENT_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
fi

NEW_COUNT=$((CURRENT_COUNT + CHANGED_LINES))

# Below threshold — save and exit silently
if [ "$NEW_COUNT" -lt "$THRESHOLD" ]; then
    echo "$NEW_COUNT" > "$COUNTER_FILE"
    exit 0
fi

# Threshold reached — reset counter and instruct Claude
echo "0" > "$COUNTER_FILE"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat << EOF
## SonarQube: Analysis Recommended

You have made **${NEW_COUNT} lines** of cumulative code changes. Run a SonarQube analysis to catch any introduced issues.

**Run these commands now:**

1. Trigger analysis:
\`\`\`bash
bash ${SCRIPT_DIR}/../core/scripts/run-analysis.sh
\`\`\`

2. After analysis completes, fetch new code issues:
\`\`\`bash
bash ${SCRIPT_DIR}/../core/scripts/fetch-issues.sh --new-code
\`\`\`

3. Review and fix any issues found before continuing.
EOF
