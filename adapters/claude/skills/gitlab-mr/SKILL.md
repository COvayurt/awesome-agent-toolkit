---
name: gitlab-mr
description: GitLab Merge Request integration - list MRs, read comments, post feedback, resolve discussions
---

# GitLab Merge Request Skill

Manage GitLab Merge Requests directly from your AI assistant. List active/closed MRs, read review comments, and post responses with proper explanations.

## Available Commands

| Command | Description |
|---------|-------------|
| `gitlab_list_mrs` | List merge requests (opened, closed, merged, all) |
| `gitlab_get_mr_details` | Get full details of a specific MR |
| `gitlab_get_mr_comments` | Read all comments on an MR |
| `gitlab_get_mr_discussions` | Get threaded discussions with code context |
| `gitlab_post_mr_comment` | Post a new comment on an MR |
| `gitlab_reply_to_discussion` | Reply to an existing discussion thread |
| `gitlab_resolve_discussion` | Mark a discussion as resolved/unresolved |

## Keyword Detection

This skill auto-triggers on keywords:
- `gitlab`, `merge request`, `MR`, `code review`
- `list mrs`, `open mrs`, `my mrs`
- `mr comments`, `review comments`, `discussion`
- `resolve discussion`, `mark fixed`

## State Filters

When listing MRs:
- `opened` → Active merge requests (default)
- `closed` → Closed without merging
- `merged` → Successfully merged
- `all` → All merge requests

## Workflows

### 1. List Active Merge Requests

```
User: "Show me open merge requests"
Agent:
1. Call gitlab_list_mrs with state="opened"
2. Format results as table showing IID, title, author, branches
3. Highlight any with conflicts or draft status
```

**Response Format:**
| MR | Title | Author | Source → Target | Status |
|----|-------|--------|-----------------|--------|
| !123 | Add login feature | @developer | feature/login → main | Ready |
| !124 | Fix bug in parser | @coder | fix/parser → main | Draft |

### 2. Review MR Comments

```
User: "Show comments on MR 123"
Agent:
1. Call gitlab_get_mr_details to get MR context
2. Call gitlab_get_mr_discussions to get threaded comments
3. Group by:
   - Unresolved discussions (action needed)
   - Resolved discussions
   - General comments
4. Show code context for inline comments
```

**Response Format:**
#### Unresolved Discussions
- **@reviewer** on `src/auth.js:45`:
  > Consider using bcrypt instead of md5 for password hashing
  - Discussion ID: `abc123def`

#### Resolved Discussions
- ~~**@reviewer** on `src/utils.js:12`: Missing null check~~ ✓

### 3. Post Fix Explanation Comment

When you've fixed an issue from a code review:

```
User: "I fixed the password hashing issue, reply to that discussion"
Agent:
1. Call gitlab_reply_to_discussion with:
   - mr_iid: 123
   - discussion_id: "abc123def"
   - body: Structured fix explanation (see template below)
2. Optionally call gitlab_resolve_discussion to mark resolved
```

**Fix Comment Template:**
```markdown
Fixed in commit `abc1234`.

**Changes made:**
- Replaced MD5 with bcrypt for password hashing
- Added salt rounds configuration (default: 12)
- Updated tests to verify secure hashing

**Files changed:**
- `src/auth.js` - Implemented bcrypt hashing
- `src/config.js` - Added BCRYPT_ROUNDS setting
- `tests/auth.test.js` - Added security tests
```

### 4. Resolve Multiple Discussions

```
User: "Mark all the fixed discussions as resolved on MR 123"
Agent:
1. Call gitlab_get_mr_discussions to list unresolved
2. For each discussion the user confirmed as fixed:
   - Call gitlab_resolve_discussion with resolve=true
3. Summarize what was resolved
```

### 5. Post General Review Feedback

```
User: "Add a comment to MR 123 saying the implementation looks good"
Agent:
1. Call gitlab_post_mr_comment with:
   - mr_iid: 123
   - body: Approval comment with specifics
```

**Approval Comment Template:**
```markdown
## Review: Approved ✅

**What I reviewed:**
- Code logic and correctness
- Error handling
- Test coverage

**Highlights:**
- Clean implementation of the auth flow
- Good separation of concerns
- Comprehensive test cases

Ready to merge once CI passes.
```

## Comment Best Practices

When posting fix explanations:

1. **Reference the commit** - Include commit hash or link
2. **Explain what changed** - Brief summary of the fix
3. **List affected files** - Help reviewer verify changes
4. **Mention any side effects** - Config changes, migrations, etc.

When replying to review feedback:

1. **Acknowledge the feedback** - Show you understood the concern
2. **Explain your solution** - Why this approach was chosen
3. **Ask for re-review if needed** - "Please take another look"

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid or expired token | Regenerate GITLAB_TOKEN |
| 404 Not Found | Wrong project ID or MR IID | Verify GITLAB_PROJECT_ID and MR number |
| 403 Forbidden | Insufficient permissions | Token needs `api` scope |

## Environment Variables

Required in `.env`:
```bash
GITLAB_HOST_URL=https://gitlab.com
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_PROJECT_ID=12345678
```

See `core/gitlab/scripts/.env.example` for template.
