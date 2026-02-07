---
name: gitlab-issues
description: Use this skill when the user mentions "gitlab issues", "list issues", "show issues", "my issues", "milestone", "sprint", "create issue", "update issue", "assign issue", or wants to manage GitLab issues.
---

# GitLab Issues Integration

Manage GitLab issues using bash scripts. Create issues, create sub-issues, list issues, read comments, post updates, assign people, and create merge requests from issues.

## How to Use

**Call bash scripts directly via the Bash tool.** No MCP server required.

**Scripts location:** `~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-issues/1.2.1/core/scripts/`

**IMPORTANT:** Environment variables must be set. Check with:
```bash
echo $GITLAB_HOST_URL $GITLAB_TOKEN $GITLAB_PROJECT_ID
```

If empty, add them to `~/.claude/settings.json` under `env`:
```json
{
  "env": {
    "GITLAB_HOST_URL": "https://gitlab.com",
    "GITLAB_TOKEN": "glpat-xxxxxxxxxxxx",
    "GITLAB_PROJECT_ID": "12345678"
  }
}
```

## Available Commands

Set `PLUGIN_DIR=~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-issues/1.2.1`

### Create Issue

```bash
# Create a simple issue (title only)
bash $PLUGIN_DIR/core/scripts/create-issue.sh '{"title": "Fix login bug"}'

# Create issue with description and labels
bash $PLUGIN_DIR/core/scripts/create-issue.sh '{"title": "Add dark mode", "description": "Implement dark mode toggle in settings", "labels": "feature,ui"}'

# Create issue with full details
bash $PLUGIN_DIR/core/scripts/create-issue.sh '{"title": "API rate limiting", "description": "Add rate limiting to public endpoints", "labels": "backend,security", "assignee_ids": [12], "milestone_id": 8, "due_date": "2025-03-01", "weight": 3}'

# Create a confidential issue
bash $PLUGIN_DIR/core/scripts/create-issue.sh '{"title": "Security vulnerability", "description": "Details...", "confidential": true}'
```

Returns created issue details including IID, URL, assignees, and labels.

### Create Sub-Issue (Child Issue)

```bash
# Create a sub-issue linked to parent issue #45
bash $PLUGIN_DIR/core/scripts/create-sub-issue.sh 45 '{"title": "Implement login form validation"}'

# Create sub-issue with description and labels
bash $PLUGIN_DIR/core/scripts/create-sub-issue.sh 45 '{"title": "Add unit tests for auth", "description": "Cover edge cases", "labels": "testing"}'

# Create sub-issue with assignee
bash $PLUGIN_DIR/core/scripts/create-sub-issue.sh 45 '{"title": "Update API docs", "assignee_ids": [15], "labels": "docs"}'
```

Creates a new issue and links it as a child of the parent issue. On GitLab Premium 16.0+ uses native parent/child hierarchy; otherwise falls back to a "relates_to" link.

### List Issues

```bash
# List open issues (default)
bash $PLUGIN_DIR/core/scripts/list-issues.sh

# List closed issues
bash $PLUGIN_DIR/core/scripts/list-issues.sh closed

# List all issues
bash $PLUGIN_DIR/core/scripts/list-issues.sh all

# List issues from a specific milestone
bash $PLUGIN_DIR/core/scripts/list-issues.sh opened "Sprint 23"
```

### Get Issue Details

```bash
bash $PLUGIN_DIR/core/scripts/get-issue-details.sh 45
```

Returns full issue details including description, assignees, labels, milestone.

### Get Issue Comments

```bash
bash $PLUGIN_DIR/core/scripts/get-issue-comments.sh 45
```

### Post Comment on Issue

```bash
bash $PLUGIN_DIR/core/scripts/post-issue-comment.sh 45 "Your comment here"
```

### Update Issue

```bash
# Update description
bash $PLUGIN_DIR/core/scripts/update-issue.sh 45 --description "New description"

# Assign users (by user ID)
bash $PLUGIN_DIR/core/scripts/update-issue.sh 45 --assignee-ids "12,15"

# Set milestone (by milestone ID)
bash $PLUGIN_DIR/core/scripts/update-issue.sh 45 --milestone-id 8

# Add labels
bash $PLUGIN_DIR/core/scripts/update-issue.sh 45 --labels "bug,urgent"

# Close issue
bash $PLUGIN_DIR/core/scripts/update-issue.sh 45 --state-event close
```

### List Milestones

```bash
bash $PLUGIN_DIR/core/scripts/list-milestones.sh
```

Use this to find milestone IDs for filtering or assigning.

### List Project Members

```bash
bash $PLUGIN_DIR/core/scripts/list-project-members.sh
```

Use this to find user IDs for assigning issues.

### Create MR from Issue

```bash
bash $PLUGIN_DIR/core/scripts/create-mr-from-issue.sh 45 feature/my-branch
```

Creates a merge request linked to the issue. Merging will auto-close the issue.

## Workflows

### 1. List Issues from Milestone

When user asks "show issues in Sprint 23":

1. Run: `bash $PLUGIN_DIR/core/scripts/list-milestones.sh` to find milestone
2. Run: `bash $PLUGIN_DIR/core/scripts/list-issues.sh opened "Sprint 23"`
3. Present as table with IID, title, assignees, labels

### 2. Get Issue and Post Update

When user asks about a specific issue:

1. Run: `bash $PLUGIN_DIR/core/scripts/get-issue-details.sh <iid>`
2. Display description and metadata
3. If user wants to comment: `bash $PLUGIN_DIR/core/scripts/post-issue-comment.sh <iid> "comment"`

### 3. Assign Issue to Team Member

When user asks to assign an issue:

1. Run: `bash $PLUGIN_DIR/core/scripts/list-project-members.sh` to find user ID
2. Run: `bash $PLUGIN_DIR/core/scripts/update-issue.sh <iid> --assignee-ids "<user_id>"`

### 4. Create Issue with Assignment

When user asks to create and assign an issue:

1. Run: `bash $PLUGIN_DIR/core/scripts/list-project-members.sh` to find user ID
2. Run: `bash $PLUGIN_DIR/core/scripts/list-milestones.sh` to find milestone ID (if needed)
3. Run: `bash $PLUGIN_DIR/core/scripts/create-issue.sh '{"title": "...", "assignee_ids": [<user_id>], "milestone_id": <milestone_id>}'`

### 5. Break Down Issue into Sub-Issues

When user asks to split an issue into tasks:

1. Run: `bash $PLUGIN_DIR/core/scripts/get-issue-details.sh <parent_iid>` to understand the parent
2. For each sub-task, run: `bash $PLUGIN_DIR/core/scripts/create-sub-issue.sh <parent_iid> '{"title": "Sub-task title", "description": "..."}'`
3. Verify with: `bash $PLUGIN_DIR/core/scripts/get-issue-details.sh <parent_iid>` to see linked issues

## Output Format

Present issues as a table:

| IID | Title | State | Assignees | Labels | Milestone |
|-----|-------|-------|-----------|--------|-----------|
| #45 | Fix login timeout | opened | @alice | bug, urgent | Sprint 23 |
