# SonarQube Integration

This project has SonarQube integration configured via MCP server.

## Available Tools

Use these MCP tools to interact with SonarQube:

- **sonar_fetch_issues** - Fetch open issues from SonarQube
  - `severity`: Filter by HIGH, MEDIUM, LOW, BLOCKER, INFO
  - `newCode`: Set true to only fetch issues in new code period
  - `file`: Filter to specific file path

- **sonar_run_analysis** - Run SonarQube analysis on the project

- **sonar_format_issues** - Format raw SonarQube JSON as markdown table

## Workflow

When user asks about code quality, SonarQube issues, or fixing issues:

1. Use `sonar_fetch_issues` with appropriate severity filter
2. Present issues in a table format
3. Ask which issues to fix
4. Fix issues one by one, reading each file first
5. Run build after fixes
6. Optionally run `sonar_run_analysis` to update results

## Environment Setup

Required in `.env`:
```
SONAR_HOST_URL=https://your-sonarqube.com
SONAR_TOKEN=your_token
SONAR_PROJECT_KEY=your_project
```
