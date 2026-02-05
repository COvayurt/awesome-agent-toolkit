# GitLab Issues Skill

Manage GitLab Issues - list by milestone, comment, update descriptions, assign people, create MRs.

## MCP Tools

| Tool | Description |
|------|-------------|
| `gitlab_list_issues` | List issues by state/milestone |
| `gitlab_get_issue_details` | Get full issue details |
| `gitlab_get_issue_comments` | Read all comments |
| `gitlab_post_issue_comment` | Post a new comment |
| `gitlab_update_issue` | Update description, milestone, assignees |
| `gitlab_list_milestones` | List project milestones |
| `gitlab_list_project_members` | List team members |
| `gitlab_create_mr_from_issue` | Create MR linked to issue |

## Common Workflows

### List Issues from Milestone
```json
{"tool": "gitlab_list_issues", "args": {"state": "opened", "milestone": "Sprint 23"}}
```

### Get Issue Description
```json
{"tool": "gitlab_get_issue_details", "args": {"issue_iid": 45}}
```

### Update Issue
```json
{"tool": "gitlab_update_issue", "args": {
  "issue_iid": 45,
  "description": "## Updated description\n\nNew content here...",
  "milestone_id": 8,
  "assignee_ids": [12, 15]
}}
```

### Post Comment
```json
{"tool": "gitlab_post_issue_comment", "args": {
  "issue_iid": 45,
  "body": "## Progress Update\n\n- Started implementation\n- Branch: `feature/fix`"
}}
```

### Create MR from Issue
```json
{"tool": "gitlab_create_mr_from_issue", "args": {
  "issue_iid": 45,
  "source_branch": "feature/fix-login",
  "target_branch": "main"
}}
```

## Environment Variables

Required:
- `GITLAB_HOST_URL` - GitLab instance URL
- `GITLAB_TOKEN` - Personal Access Token (api scope)
- `GITLAB_PROJECT_ID` - Project ID or path
