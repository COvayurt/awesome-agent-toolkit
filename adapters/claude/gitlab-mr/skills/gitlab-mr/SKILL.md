---
name: gitlab-mr
description: Use this skill when the user mentions "merge request", "MR", "pull request", "code review", "review comments", "list MRs", "show MRs", "my MRs", "resolve discussion", or wants to manage GitLab merge requests.
---

# GitLab Merge Request Integration

Manage GitLab Merge Requests using bash scripts. List MRs, read comments, post feedback, and resolve discussions.

## How to Use

**Call bash scripts directly via the Bash tool.** No MCP server required.

**Scripts location:** `~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-mr/1.2.1/core/scripts/`

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

Set `PLUGIN_DIR=~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-mr/1.2.1`

### List Merge Requests

```bash
# List open MRs (default)
bash $PLUGIN_DIR/core/scripts/list-mrs.sh

# List merged MRs
bash $PLUGIN_DIR/core/scripts/list-mrs.sh merged

# List closed MRs
bash $PLUGIN_DIR/core/scripts/list-mrs.sh closed

# List all MRs
bash $PLUGIN_DIR/core/scripts/list-mrs.sh all
```

### Get MR Details

```bash
bash $PLUGIN_DIR/core/scripts/get-mr-details.sh 123
```

Returns full MR details including description, source/target branches, author.

### Get MR Comments

```bash
bash $PLUGIN_DIR/core/scripts/get-mr-comments.sh 123
```

### Get MR Discussions (Threaded)

```bash
bash $PLUGIN_DIR/core/scripts/get-mr-discussions.sh 123
```

Returns threaded discussions with code context. Includes discussion IDs for replies.

### Post Comment on MR

```bash
bash $PLUGIN_DIR/core/scripts/post-mr-comment.sh 123 "Your comment here"
```

### Reply to Discussion

```bash
bash $PLUGIN_DIR/core/scripts/reply-to-discussion.sh 123 "discussion_id_abc123" "Your reply"
```

### Resolve Discussion

```bash
bash $PLUGIN_DIR/core/scripts/resolve-discussion.sh 123 "discussion_id_abc123"
```

## Workflows

### 1. Review MR Comments

When user asks about MR comments or code review:

1. Run: `bash $PLUGIN_DIR/core/scripts/get-mr-details.sh <iid>` for context
2. Run: `bash $PLUGIN_DIR/core/scripts/get-mr-discussions.sh <iid>` for threaded comments
3. Group by: Unresolved (action needed) vs Resolved
4. Show code context for inline comments

### 2. Reply to Review Feedback

When user has fixed something and wants to reply:

1. Get discussion ID from the discussions list
2. Run: `bash $PLUGIN_DIR/core/scripts/reply-to-discussion.sh <mr_iid> "<discussion_id>" "Fixed in commit abc123..."`
3. Optionally resolve: `bash $PLUGIN_DIR/core/scripts/resolve-discussion.sh <mr_iid> "<discussion_id>"`

### 3. Post Fix Explanation

Template for fix comments:
```markdown
Fixed in commit `abc1234`.

**Changes made:**
- Replaced MD5 with bcrypt for password hashing
- Added salt rounds configuration

**Files changed:**
- `src/auth.js` - Implemented bcrypt hashing
- `tests/auth.test.js` - Added security tests
```

## Output Format

Present MRs as a table:

| IID | Title | State | Author | Source → Target |
|-----|-------|-------|--------|-----------------|
| !123 | Add login feature | opened | @developer | feature/login → main |
| !124 | Fix parser bug | merged | @coder | fix/parser → main |

### Unresolved Discussions Format

- **@reviewer** on `src/auth.js:45`:
  > Consider using bcrypt instead of md5
  - Discussion ID: `abc123def`
