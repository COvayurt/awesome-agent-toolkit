---
name: sonar
description: Use this skill when the user mentions "sonar", "sonarqube", "code quality", "code smell", "quality gate", "new code issues", "fetch issues", "security hotspots", or wants to analyze code quality.
---

# SonarQube Integration

Fetch and manage SonarQube issues, quality gates, and metrics using bash scripts.

## How to Use

**Call bash scripts directly via the Bash tool.** No MCP server required.

**Scripts location:** `~/.claude/plugins/cache/awesome-agent-toolkit/sonarqube/1.2.1/core/scripts/`

**IMPORTANT:** Environment variables must be set. Check with:
```bash
echo $SONAR_HOST_URL $SONAR_TOKEN $SONAR_PROJECT_KEY
```

If empty, add them to `~/.claude/settings.json` under `env`:
```json
{
  "env": {
    "SONAR_HOST_URL": "https://sonarqube.example.com",
    "SONAR_TOKEN": "sqa_xxxxxxxxxxxx",
    "SONAR_PROJECT_KEY": "my-project-key"
  }
}
```

## Available Commands

Set `PLUGIN_DIR=~/.claude/plugins/cache/awesome-agent-toolkit/sonarqube/1.2.1`

### Fetch Issues

```bash
# Fetch all open issues (HIGH, MEDIUM severity)
bash $PLUGIN_DIR/core/scripts/fetch-issues.sh --severity HIGH,MEDIUM

# Fetch only HIGH severity issues
bash $PLUGIN_DIR/core/scripts/fetch-issues.sh --severity HIGH

# Fetch issues from NEW CODE only (important for CI/CD)
bash $PLUGIN_DIR/core/scripts/fetch-issues.sh --severity HIGH --new-code

# Fetch issues for a specific file
bash $PLUGIN_DIR/core/scripts/fetch-issues.sh --file src/main/java/MyClass.java
```

### Check Quality Gate

```bash
bash $PLUGIN_DIR/core/scripts/quality-gate.sh
```

Returns: PASSED, FAILED, or ERROR with condition details.

### View Metrics

```bash
bash $PLUGIN_DIR/core/scripts/metrics.sh
```

Returns: Coverage %, duplications, bugs, vulnerabilities, code smells count.

### Security Hotspots

```bash
bash $PLUGIN_DIR/core/scripts/hotspots.sh
```

Returns: Security hotspots that need review.

### Rule Details

```bash
bash $PLUGIN_DIR/core/scripts/rule-details.sh java:S2140
```

Explains what a specific rule means and how to fix it.

### Run Analysis

```bash
bash $PLUGIN_DIR/core/scripts/run-analysis.sh
```

Triggers a SonarQube scan on the current project.

## Workflows

### 1. Fetch & Fix New Code Issues

When user asks about "new code issues" or "sonar issues from new code":

1. Run: `bash $PLUGIN_DIR/core/scripts/fetch-issues.sh --severity HIGH --new-code`
2. Parse the JSON output and present as a table
3. For each issue, offer to read the file and fix it

### 2. Check Quality Gate Before PR

When user asks about quality gate status:

1. Run: `bash $PLUGIN_DIR/core/scripts/quality-gate.sh`
2. Report PASSED/FAILED status
3. If failed, list which conditions failed

### 3. Review Security Issues

When user mentions security:

1. Run: `bash $PLUGIN_DIR/core/scripts/hotspots.sh`
2. Present hotspots with vulnerability categories
3. Recommend review actions

## Output Format

Present issues as a table:

| # | File | Line | Rule | Message | Severity |
|---|------|------|------|---------|----------|
| 1 | `File.java` | 42 | java:S2140 | Use nextInt() | HIGH |

After listing, ask:
**Ready to fix?** Reply with task numbers (e.g., `1, 3, 5`), `all`, or `skip`.
