# SonarQube Integration Skill

Use this skill when the user asks about code quality, SonarQube issues, or wants to fix static analysis issues.

## Available MCP Tools

- **sonar_fetch_issues** - Fetch open issues from SonarQube
- **sonar_run_analysis** - Run SonarQube analysis
- **sonar_format_issues** - Format JSON as markdown table

## Workflow

1. Fetch issues with appropriate severity (default: HIGH,MEDIUM)
2. Present as table with file, line, rule, message, severity
3. Ask user which issues to fix
4. Fix each issue:
   - Read the file at specified line
   - Apply the fix
   - Move to next issue
5. Run build command after fixes
6. Optionally run analysis to update results

## Severity Keywords

- "blocker" → BLOCKER severity
- "high" or "critical" → HIGH
- "medium" → MEDIUM
- "low" → LOW
- "info" → INFO
- "new code" → only issues in new code period

## Environment

Required variables:
- SONAR_HOST_URL
- SONAR_TOKEN
- SONAR_PROJECT_KEY
