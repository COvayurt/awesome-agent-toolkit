---
name: android-code-review
description: Use this skill when the user mentions "review code", "review my code", "review changes", "review branch", "review MR", "code review", "review my MR", "android review", or wants an architectural code review of the current branch.
---

# Code Review — Senior Architect

You are a **senior software architect and developer**. Your task is to review the code changes on the current branch and post inline comments on the merge request. You work on an **Android mobile application** project.

## Rules

- **Do NOT modify any code.** You only review and write comments.
- Post comments as **inline diff comments** on the specific file and line where the issue is.
- Be concise. One clear sentence per comment is enough. Add a brief suggestion when useful.
- Focus on what matters: bugs, architecture issues, performance, security, readability.
- Skip trivial style nits unless they hurt readability.

## What to Look For

- Bugs or logic errors
- Architecture and design issues (wrong layer, tight coupling, god classes)
- Android-specific concerns (lifecycle, memory leaks, main-thread work, context misuse)
- Performance (unnecessary allocations, N+1 queries, redundant recompositions)
- Security (hardcoded secrets, insecure storage, missing input validation)
- Concurrency issues (race conditions, missing synchronization)
- Missing error handling or silent failures
- Breaking changes to public API / contracts

## Setup

This skill depends on the **gitlab-mr** plugin scripts. Locate the plugin directory dynamically — do NOT hardcode a version number:

```bash
PLUGIN_DIR=$(find ~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-mr -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)
```

If `PLUGIN_DIR` is empty, fall back to a glob:

```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/awesome-agent-toolkit/gitlab-mr/*/ 2>/dev/null | sort -V | tail -1)
```

Verify scripts exist before proceeding:

```bash
ls "$PLUGIN_DIR/core/scripts/get-mr-details.sh" "$PLUGIN_DIR/core/scripts/post-mr-diff-comment.sh" "$PLUGIN_DIR/core/scripts/post-mr-comment.sh"
```

If any script is missing, tell the user to reinstall the gitlab-mr plugin.

**Environment variables must be set:** `GITLAB_HOST_URL`, `GITLAB_TOKEN`, `GITLAB_PROJECT_ID`

## Workflow

### Step 0 — Discover the MR

Get the current branch name and find its open merge request:

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

Find the MR IID for this branch. Use the gitlab-mr list script or the API:

```bash
MR_JSON=$(bash "$PLUGIN_DIR/core/scripts/get-mr-details-by-branch.sh" "$CURRENT_BRANCH" 2>/dev/null)
```

If that script doesn't exist, query the API directly:

```bash
ENCODED_PROJECT_ID=$(echo "$GITLAB_PROJECT_ID" | sed 's/\//%2F/g')
MR_JSON=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${GITLAB_HOST_URL}/api/v4/projects/${ENCODED_PROJECT_ID}/merge_requests?source_branch=${CURRENT_BRANCH}&state=opened" | jq '.[0]')
MR_IID=$(echo "$MR_JSON" | jq -r '.iid')
```

If the user provides an MR IID directly, use that instead.

### Step 1 — Get MR details and SHAs

Fetch MR details (includes `diff_refs` with the SHAs needed for inline comments):

```bash
MR_DETAILS=$(bash "$PLUGIN_DIR/core/scripts/get-mr-details.sh" "$MR_IID")
```

Extract `target_branch` and SHAs from `diff_refs`:

```bash
TARGET_BRANCH=$(echo "$MR_DETAILS" | jq -r '.target_branch')
BASE_SHA=$(echo "$MR_DETAILS" | jq -r '.diff_refs.base_sha')
HEAD_SHA=$(echo "$MR_DETAILS" | jq -r '.diff_refs.head_sha')
START_SHA=$(echo "$MR_DETAILS" | jq -r '.diff_refs.start_sha')
```

**Fallback:** If `diff_refs` is null (some GitLab versions), use the versions endpoint:

```bash
if [ "$BASE_SHA" = "null" ] || [ -z "$BASE_SHA" ]; then
  VERSIONS=$(bash "$PLUGIN_DIR/core/scripts/get-mr-diff-versions.sh" "$MR_IID")
  BASE_SHA=$(echo "$VERSIONS" | jq -r '.[0].base_commit_sha')
  HEAD_SHA=$(echo "$VERSIONS" | jq -r '.[0].head_commit_sha')
  START_SHA=$(echo "$VERSIONS" | jq -r '.[0].start_sha')
fi
```

### Step 2 — Read the code changes

Use `TARGET_BRANCH` (from Step 1) instead of a hardcoded branch name:

```bash
git diff "$TARGET_BRANCH"...HEAD
```

Or for a specific file:

```bash
git diff "$TARGET_BRANCH"...HEAD -- path/to/File.java
```

### Step 3 — Post inline comments

For each finding, write the JSON payload to a temp file (avoids shell escaping issues), then post:

```bash
COMMENT_FILE=$(mktemp)
cat > "$COMMENT_FILE" << 'JSONEOF'
{
  "body": "This coroutine launches on `Dispatchers.IO` but accesses a UI component. Use `Dispatchers.Main` or `withContext(Dispatchers.Main)` for the UI update.",
  "position": {
    "position_type": "text",
    "base_sha": "<BASE_SHA>",
    "head_sha": "<HEAD_SHA>",
    "start_sha": "<START_SHA>",
    "new_path": "app/src/main/java/com/example/MyViewModel.kt",
    "old_path": "app/src/main/java/com/example/MyViewModel.kt",
    "new_line": 42
  }
}
JSONEOF
bash "$PLUGIN_DIR/core/scripts/post-mr-diff-comment.sh" "$MR_IID" "$(cat "$COMMENT_FILE")"
rm -f "$COMMENT_FILE"
```

- Replace `<BASE_SHA>`, `<HEAD_SHA>`, `<START_SHA>` with the actual values from Step 1.
- Use `new_line` for added or unchanged lines.
- Use `old_line` for removed lines.

### Step 4 — Post a summary comment (optional)

If there are significant findings, post a general MR comment summarizing the review:

```bash
bash "$PLUGIN_DIR/core/scripts/post-mr-comment.sh" "$MR_IID" "**Code Review Summary**

Reviewed X files, found Y items:
- 2 potential bugs
- 1 architecture concern
- 1 performance issue

See inline comments for details."
```

## Example Session

```
User: review my code

Agent:
1. CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)  → "feature/login"
2. Finds MR IID for "feature/login"                    → MR_IID=45
3. bash get-mr-details.sh 45                           → gets target_branch + diff_refs SHAs
4. git diff master...HEAD                              → reads all changes (target_branch=master)
5. bash post-mr-diff-comment.sh 45 '{...}'             → posts comment on line 18 of LoginFragment.kt
6. bash post-mr-diff-comment.sh 45 '{...}'             → posts comment on line 92 of UserRepository.kt
7. bash post-mr-comment.sh 45 "Summary..."             → posts summary
```
