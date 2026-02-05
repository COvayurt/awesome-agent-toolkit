---
name: sonar
description: Process SonarQube issue JSON and extract actionable tasks. Use when user pastes SonarQube JSON export or mentions SonarQube issues.
---

# SonarQube Issue Processor

Process SonarQube issue JSON and extract actionable tasks.

## Instructions

When this skill is invoked, check if the user has provided JSON input.

### Fetching Issues from SonarQube

The hook scripts can fetch issues directly from SonarQube. The prompt hook automatically detects keywords in the user's prompt:

- **Default fetch**: Triggered by keywords like "sonar", "fix issue", "code smell", "bug scan", "quality gate". Fetches HIGH,MEDIUM severity issues from the overall codebase.
- **Severity detection**: The hook detects severity keywords in the prompt and filters accordingly:
  - "blocker" → `BLOCKER`
  - "high" or "critical" → `HIGH`
  - "medium" → `MEDIUM`
  - "low" → `LOW`
  - "info" → `INFO`
  - No keyword → defaults to `HIGH,MEDIUM`
- **New code fetch**: Triggered when the prompt also contains "new code". Uses SonarQube's `inNewCodePeriod=true` parameter.

### No JSON Provided

If the user invokes `/sonarqube:sonar` without any JSON (empty message or just the command), respond exactly:

```
Please paste your SonarQube JSON export.

Expected format: The JSON should contain an `"issues"` array from SonarQube's API or export.
```

Then wait for the user to paste the JSON.

### JSON Provided

When the user provides SonarQube JSON, parse it and follow these steps exactly:

### Step 1: Validate JSON Structure

Confirm the JSON has:
- `"issues"` array at root level
- Each issue contains: `rule`, `component`, `line`, `message`, `impacts` (array with `severity` and `softwareQuality`)
- Optional: `"components"` array for file path mapping

If invalid, respond: "This doesn't appear to be valid SonarQube JSON. Please paste the full JSON export."

### Step 2: Extract File Paths

For each issue's `component` field:
1. Look up the full path in the `components` array using the `key` field
2. Use the `path` or `longName` field for the relative file path
3. Extract just the filename for the summary table

### Step 3: Output Summary Table

If there are multiple issues, first output:

```
**SonarQube Issues Found: [total count]**

| # | File | Line | Issue | Impact Severity | Software Quality |
|---|------|------|-------|-----------------|------------------|
| 1 | `FileName.java` | 123 | Brief message (truncate to ~50 chars) | HIGH | RELIABILITY |
```

### Step 4: Output Detailed Tasks

For each issue, output:

```
---

**Task [N]:** In `[filename]`, SonarQube found **"[full message]"** at line **[line]**.
- Path: `[full relative path]`
- Rule: `[rule]`
- Impact Severity: [impacts[0].severity]
- Software Quality: [impacts[0].softwareQuality]
```

### Step 5: Prompt for Action

End with exactly:

```
---

**Ready to fix?** Reply with:
- Task numbers to fix (e.g., `1, 3, 5`)
- `all` to fix everything
- `skip` to just keep this list for reference
```

## When User Selects Tasks to Fix

1. Create a todo list with selected issues
2. Read the file at the specified line for each issue
3. Fix issues one by one, marking todos complete as you go
4. After all fixes, run your project's build command
5. If build fails, fix compilation errors before completing
