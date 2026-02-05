---
name: sonar
description: SonarQube integration - fetch issues, check quality gate, view metrics, review security hotspots, explain rules.
---

# SonarQube Integration

## Available Commands

| Command | Description |
|---------|-------------|
| Fetch issues | Get code quality issues by severity |
| Quality gate | Check if project passes/fails |
| Metrics | View coverage, duplications, complexity |
| Security hotspots | Review security issues |
| Rule details | Explain what a rule means |
| Run analysis | Execute SonarQube scan |

## Keyword Detection

The hook auto-triggers on these keywords:
- `sonar`, `fix issue`, `code smell`, `bug scan`, `quality gate`

### Severity filters
- `blocker` → BLOCKER
- `high` / `critical` → HIGH
- `medium` → MEDIUM
- `low` → LOW
- `info` → INFO
- `new code` → new code period only

## Workflows

### Fetch & Fix Issues

When user asks about sonar issues:
1. Fetch issues with appropriate severity filter
2. Present as table: File | Line | Rule | Message | Severity
3. Ask which to fix
4. For each issue:
   - Read file at specified line
   - Apply fix
   - Move to next
5. Run build after fixes

### Quality Gate Check

When user asks about quality gate:
1. Fetch quality gate status
2. Report: PASSED, FAILED, or ERROR
3. If failed, show which conditions failed

### View Metrics

When user asks about metrics/coverage:
1. Fetch project metrics
2. Present key metrics:
   - Coverage %
   - Duplications %
   - Bugs / Vulnerabilities / Code Smells count
   - Complexity

### Security Hotspots

When user asks about security:
1. Fetch hotspots with TO_REVIEW status
2. Present as table with vulnerability category
3. Review each hotspot and recommend action

### Rule Explanation

When user asks "what does rule X mean" or "explain rule X":
1. Fetch rule details using rule key (e.g., java:S2140)
2. Present:
   - Rule name and description
   - Why it matters
   - How to fix (with examples if available)

## Response Format

### Issue Table
```
| # | File | Line | Rule | Message | Severity |
|---|------|------|------|---------|----------|
| 1 | `File.java` | 42 | java:S2140 | Use nextInt() | HIGH |
```

### After Listing Issues
```
**Ready to fix?** Reply with:
- Task numbers (e.g., `1, 3, 5`)
- `all` to fix everything
- `skip` to keep for reference
```
