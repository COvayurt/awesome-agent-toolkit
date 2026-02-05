# GitLab Merge Request Skill

Manage GitLab Merge Requests - list MRs, read comments, post feedback, resolve discussions.

## MCP Tools

Use the `gitlab-mr` MCP server tools:

| Tool | Description |
|------|-------------|
| `gitlab_list_mrs` | List merge requests by state |
| `gitlab_get_mr_details` | Get full MR details |
| `gitlab_get_mr_comments` | Read all comments |
| `gitlab_get_mr_discussions` | Get threaded discussions |
| `gitlab_post_mr_comment` | Post a new comment |
| `gitlab_reply_to_discussion` | Reply to a thread |
| `gitlab_resolve_discussion` | Resolve/unresolve |

## Common Workflows

### List Open Merge Requests
```json
{"tool": "gitlab_list_mrs", "args": {"state": "opened"}}
```

### Read Discussion Comments
```json
{"tool": "gitlab_get_mr_discussions", "args": {"mr_iid": 123}}
```

### Reply with Fix Explanation
```json
{"tool": "gitlab_reply_to_discussion", "args": {
  "mr_iid": 123,
  "discussion_id": "abc123def",
  "body": "Fixed in commit `abc1234`.\n\n**Changes:**\n- Updated X to Y\n- Added tests"
}}
```

### Resolve Discussion
```json
{"tool": "gitlab_resolve_discussion", "args": {
  "mr_iid": 123,
  "discussion_id": "abc123def",
  "resolve": true
}}
```

## Environment Variables

Required:
- `GITLAB_HOST_URL` - GitLab instance URL
- `GITLAB_TOKEN` - Personal Access Token (api scope)
- `GITLAB_PROJECT_ID` - Project ID or path
