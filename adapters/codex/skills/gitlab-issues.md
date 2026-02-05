# GitLab Issues Skill

Manage GitLab Issues - list by milestone, comment, update descriptions, assign people, create MRs.

## MCP Tools

Use the `gitlab-mr` MCP server tools (includes both MR and Issue tools):

- `gitlab_list_issues` - List issues (filter by state, milestone)
- `gitlab_get_issue_details` - Get full issue details
- `gitlab_get_issue_comments` - Read all comments
- `gitlab_post_issue_comment` - Post a new comment
- `gitlab_update_issue` - Update description, milestone, assignees, labels
- `gitlab_list_milestones` - List milestones
- `gitlab_list_project_members` - List team members
- `gitlab_create_mr_from_issue` - Create MR linked to issue

## Workflows

### List Issues from Milestone
```
gitlab_list_issues(state="opened", milestone="Sprint 23")
```

### Get Issue Description
```
gitlab_get_issue_details(issue_iid=45)
```

### Update Issue Description
```
gitlab_update_issue(issue_iid=45, description="## New description\n...")
```

### Post Comment
```
gitlab_post_issue_comment(issue_iid=45, body="Started working on this...")
```

### Assign People
```
# First get user IDs
gitlab_list_project_members()
# Then assign
gitlab_update_issue(issue_iid=45, assignee_ids=[12, 15])
```

### Set Milestone
```
# First get milestone ID
gitlab_list_milestones()
# Then set
gitlab_update_issue(issue_iid=45, milestone_id=8)
```

### Create MR from Issue
```
gitlab_create_mr_from_issue(issue_iid=45, source_branch="feature/fix-login")
```

## Environment Variables

```bash
GITLAB_HOST_URL=https://gitlab.com
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_PROJECT_ID=12345678
```
