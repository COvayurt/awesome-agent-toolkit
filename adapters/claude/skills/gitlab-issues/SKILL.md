---
name: gitlab-issues
description: GitLab Issues integration - list issues, manage comments, update descriptions, assign milestones and people, create MRs
---

# GitLab Issues Skill

Manage GitLab Issues directly from your AI assistant. List issues by milestone, read/write comments, update descriptions, assign team members, and create merge requests from issues.

## Available Commands

| Command | Description |
|---------|-------------|
| `gitlab_list_issues` | List issues (filter by state, milestone) |
| `gitlab_get_issue_details` | Get full issue details including description |
| `gitlab_get_issue_comments` | Read all comments on an issue |
| `gitlab_post_issue_comment` | Post a new comment on an issue |
| `gitlab_update_issue` | Update description, milestone, assignees, labels |
| `gitlab_list_milestones` | List project milestones (for filtering/assigning) |
| `gitlab_list_project_members` | List team members (for assigning) |
| `gitlab_create_mr_from_issue` | Create a merge request linked to an issue |

## Keyword Detection

This skill auto-triggers on keywords:
- `gitlab issue`, `issues`, `bug`, `task`
- `milestone`, `sprint`, `backlog`
- `assign`, `assignee`, `team member`
- `issue description`, `update issue`
- `create mr`, `merge request from issue`

## State Filters

When listing issues:
- `opened` → Active issues (default)
- `closed` → Closed issues
- `all` → All issues

## Workflows

### 1. List Issues from Specific Milestone

```
User: "Show me all issues in Sprint 23"
Agent:
1. Call gitlab_list_milestones to find "Sprint 23" milestone
2. Call gitlab_list_issues with milestone="Sprint 23"
3. Format results showing IID, title, assignees, labels
```

**Response Format:**
| Issue | Title | Assignees | Labels | Status |
|-------|-------|-----------|--------|--------|
| #45 | Fix login timeout | @alice | bug, urgent | Open |
| #46 | Add dark mode | @bob, @carol | feature | Open |

### 2. Get Issue Description

```
User: "What's the description of issue 45?"
Agent:
1. Call gitlab_get_issue_details with issue_iid=45
2. Display the full description with formatting
3. Show metadata (assignees, milestone, labels)
```

### 3. Update Issue Description

```
User: "Update issue 45 description to include the new requirements"
Agent:
1. Call gitlab_get_issue_details to get current description
2. Call gitlab_update_issue with:
   - issue_iid: 45
   - description: Updated markdown content
3. Confirm the update was successful
```

**Description Template:**
```markdown
## Problem
[Clear description of the issue]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
[Implementation hints or constraints]

## Related
- Relates to #42
- Blocks #48
```

### 4. Post Comment on Issue

```
User: "Add a comment to issue 45 saying I've started working on it"
Agent:
1. Call gitlab_post_issue_comment with:
   - issue_iid: 45
   - body: Progress update comment
```

**Progress Comment Template:**
```markdown
## Status Update

**Started:** 2024-01-15
**Progress:** In development

### Completed
- [x] Set up branch `feature/fix-login-timeout`
- [x] Identified root cause

### Next Steps
- [ ] Implement fix
- [ ] Add tests
- [ ] Request review
```

### 5. Assign People to Issue

```
User: "Assign issue 45 to alice and bob"
Agent:
1. Call gitlab_list_project_members to find user IDs
   - alice → id: 12
   - bob → id: 15
2. Call gitlab_update_issue with:
   - issue_iid: 45
   - assignee_ids: [12, 15]
3. Confirm assignment
```

### 6. Set Milestone on Issue

```
User: "Move issue 45 to Sprint 24"
Agent:
1. Call gitlab_list_milestones to find "Sprint 24"
   - Sprint 24 → id: 8
2. Call gitlab_update_issue with:
   - issue_iid: 45
   - milestone_id: 8
3. Confirm milestone was set
```

### 7. Create MR from Issue

```
User: "Create a merge request for issue 45 from branch feature/fix-login"
Agent:
1. Call gitlab_create_mr_from_issue with:
   - issue_iid: 45
   - source_branch: "feature/fix-login"
   - target_branch: "main" (or leave empty for default)
2. Return the MR URL
```

**Result:**
- MR created: !67 "Resolve 'Fix login timeout'"
- Description: "Closes #45"
- Merging will automatically close the issue

### 8. Close Issue with Comment

```
User: "Close issue 45 with a resolution comment"
Agent:
1. Call gitlab_post_issue_comment with resolution details
2. Call gitlab_update_issue with:
   - issue_iid: 45
   - state_event: "close"
```

**Resolution Comment Template:**
```markdown
## Resolution

**Fixed in:** !67 (merged)
**Root Cause:** Session timeout was set too low (5 min instead of 30 min)

### Changes Made
- Updated session timeout to 30 minutes
- Added session refresh on user activity
- Added tests for timeout behavior

### Verification
- [x] Manual testing passed
- [x] CI pipeline passed
- [x] Deployed to staging
```

## Comment Best Practices

When posting issue comments:

1. **Use headers** - Structure with ##, ### for readability
2. **Include context** - Reference commits, MRs, or other issues
3. **Use checklists** - Track progress with `- [ ]` and `- [x]`
4. **@mention people** - Notify relevant team members
5. **Link related items** - Use #issue or !MR syntax

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid or expired token | Regenerate GITLAB_TOKEN |
| 404 Not Found | Wrong project ID or issue IID | Verify GITLAB_PROJECT_ID |
| 403 Forbidden | Insufficient permissions | Token needs `api` scope |
| 400 Bad Request | Invalid milestone/user ID | Use list commands to get valid IDs |

## Environment Variables

Required in `.env`:
```bash
GITLAB_HOST_URL=https://gitlab.com
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_PROJECT_ID=12345678
```

Same as gitlab-mr skill - shares the `core/gitlab/` configuration.
