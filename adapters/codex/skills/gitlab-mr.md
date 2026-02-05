# GitLab Merge Request Skill

Manage GitLab Merge Requests - list MRs, read comments, post feedback, resolve discussions.

## MCP Tools

Use the `gitlab-mr` MCP server tools:

- `gitlab_list_mrs` - List merge requests (state: opened/closed/merged/all)
- `gitlab_get_mr_details` - Get full MR details
- `gitlab_get_mr_comments` - Read all comments on an MR
- `gitlab_get_mr_discussions` - Get threaded discussions with code context
- `gitlab_post_mr_comment` - Post a new comment
- `gitlab_reply_to_discussion` - Reply to a discussion thread
- `gitlab_resolve_discussion` - Mark discussion as resolved

## Workflows

### List Open MRs
```
gitlab_list_mrs(state="opened", per_page=20)
```

### Review Comments on MR
```
gitlab_get_mr_discussions(mr_iid=123)
```

### Post Fix Explanation
```
gitlab_reply_to_discussion(
  mr_iid=123,
  discussion_id="abc123",
  body="Fixed in commit `def456`. Changed X to Y because Z."
)
gitlab_resolve_discussion(mr_iid=123, discussion_id="abc123", resolve=true)
```

## Environment Variables

```bash
GITLAB_HOST_URL=https://gitlab.com
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_PROJECT_ID=12345678
```
