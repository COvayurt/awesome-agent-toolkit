#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const SCRIPTS_DIR = join(__dirname, "..", "scripts");

const server = new Server(
  {
    name: "gitlab",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Helper to run scripts
function runScript(scriptName, args = []) {
  const scriptPath = join(SCRIPTS_DIR, scriptName);
  const escapedArgs = args.map((arg) =>
    typeof arg === "string" ? `'${arg.replace(/'/g, "'\\''")}'` : arg
  );
  const command = `bash "${scriptPath}" ${escapedArgs.join(" ")}`;

  try {
    const result = execSync(command, {
      encoding: "utf-8",
      env: {
        ...process.env,
        GITLAB_HOST_URL: process.env.GITLAB_HOST_URL,
        GITLAB_TOKEN: process.env.GITLAB_TOKEN,
        GITLAB_PROJECT_ID: process.env.GITLAB_PROJECT_ID,
      },
      maxBuffer: 10 * 1024 * 1024,
    });
    return result;
  } catch (error) {
    throw new Error(`Script error: ${error.message}\n${error.stderr || ""}`);
  }
}

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "gitlab_list_mrs",
        description:
          "List merge requests in the GitLab project. Returns MR IID, title, state, author, branches, and URL.",
        inputSchema: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description:
                "Filter by MR state: opened, closed, merged, or all",
              enum: ["opened", "closed", "merged", "all"],
              default: "opened",
            },
            per_page: {
              type: "number",
              description: "Number of MRs to return (default: 20, max: 100)",
              default: 20,
            },
          },
        },
      },
      {
        name: "gitlab_get_mr_details",
        description:
          "Get detailed information about a specific merge request including description, assignees, reviewers, and labels.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
          },
          required: ["mr_iid"],
        },
      },
      {
        name: "gitlab_get_mr_comments",
        description:
          "Get all comments/notes on a merge request. Returns comment body, author, timestamps, and resolution status.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            per_page: {
              type: "number",
              description: "Number of comments to return (default: 50)",
              default: 50,
            },
          },
          required: ["mr_iid"],
        },
      },
      {
        name: "gitlab_get_mr_discussions",
        description:
          "Get threaded discussions on a merge request. Includes inline code comments with file paths and line numbers.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            per_page: {
              type: "number",
              description: "Number of discussions to return (default: 50)",
              default: 50,
            },
          },
          required: ["mr_iid"],
        },
      },
      {
        name: "gitlab_post_mr_comment",
        description:
          "Post a new comment on a merge request. Use this to provide feedback, ask questions, or document fixes.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            body: {
              type: "string",
              description:
                "The comment text. Supports GitLab-flavored Markdown.",
            },
          },
          required: ["mr_iid", "body"],
        },
      },
      {
        name: "gitlab_reply_to_discussion",
        description:
          "Reply to an existing discussion thread on a merge request. Use this to respond to code review comments.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            discussion_id: {
              type: "string",
              description: "The ID of the discussion thread to reply to",
            },
            body: {
              type: "string",
              description:
                "The reply text. Supports GitLab-flavored Markdown.",
            },
          },
          required: ["mr_iid", "discussion_id", "body"],
        },
      },
      {
        name: "gitlab_resolve_discussion",
        description:
          "Resolve or unresolve a discussion thread. Use after addressing code review feedback.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            discussion_id: {
              type: "string",
              description: "The ID of the discussion thread",
            },
            resolve: {
              type: "boolean",
              description: "true to resolve, false to unresolve",
              default: true,
            },
          },
          required: ["mr_iid", "discussion_id"],
        },
      },
      {
        name: "gitlab_get_mr_diff_versions",
        description:
          "Get diff versions for a merge request to obtain SHA values needed for posting line-level inline comments.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
          },
          required: ["mr_iid"],
        },
      },
      {
        name: "gitlab_post_mr_diff_comment",
        description:
          "Post an inline comment on a specific file and line in a merge request diff. Requires SHA values from gitlab_get_mr_diff_versions.",
        inputSchema: {
          type: "object",
          properties: {
            mr_iid: {
              type: "number",
              description: "The internal ID (IID) of the merge request",
            },
            body: {
              type: "string",
              description:
                "The comment text. Supports GitLab-flavored Markdown.",
            },
            base_sha: {
              type: "string",
              description:
                "Base commit SHA from diff versions (base_commit_sha)",
            },
            head_sha: {
              type: "string",
              description:
                "Head commit SHA from diff versions (head_commit_sha)",
            },
            start_sha: {
              type: "string",
              description:
                "Start commit SHA from diff versions (start_commit_sha)",
            },
            new_path: {
              type: "string",
              description: "File path on the new side of the diff",
            },
            old_path: {
              type: "string",
              description:
                "File path on the old side of the diff (defaults to new_path if not provided)",
            },
            new_line: {
              type: "number",
              description:
                "Line number on the new side (for added or unchanged lines)",
            },
            old_line: {
              type: "number",
              description:
                "Line number on the old side (for removed or unchanged lines)",
            },
          },
          required: ["mr_iid", "body", "base_sha", "head_sha", "start_sha", "new_path"],
        },
      },
      // Issue tools
      {
        name: "gitlab_list_issues",
        description:
          "List issues in the GitLab project. Can filter by state and milestone.",
        inputSchema: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description: "Filter by issue state: opened, closed, or all",
              enum: ["opened", "closed", "all"],
              default: "opened",
            },
            milestone: {
              type: "string",
              description:
                "Filter by milestone title. Use 'none' for no milestone, 'any' for any milestone.",
            },
            per_page: {
              type: "number",
              description: "Number of issues to return (default: 20, max: 100)",
              default: 20,
            },
          },
        },
      },
      {
        name: "gitlab_get_issue_details",
        description:
          "Get detailed information about a specific issue including description, assignees, milestone, and labels.",
        inputSchema: {
          type: "object",
          properties: {
            issue_iid: {
              type: "number",
              description: "The internal ID (IID) of the issue",
            },
          },
          required: ["issue_iid"],
        },
      },
      {
        name: "gitlab_get_issue_comments",
        description:
          "Get all comments/notes on an issue. Returns comment body, author, and timestamps.",
        inputSchema: {
          type: "object",
          properties: {
            issue_iid: {
              type: "number",
              description: "The internal ID (IID) of the issue",
            },
            per_page: {
              type: "number",
              description: "Number of comments to return (default: 50)",
              default: 50,
            },
          },
          required: ["issue_iid"],
        },
      },
      {
        name: "gitlab_post_issue_comment",
        description:
          "Post a new comment on an issue. Use this to provide updates, ask questions, or document progress.",
        inputSchema: {
          type: "object",
          properties: {
            issue_iid: {
              type: "number",
              description: "The internal ID (IID) of the issue",
            },
            body: {
              type: "string",
              description:
                "The comment text. Supports GitLab-flavored Markdown.",
            },
          },
          required: ["issue_iid", "body"],
        },
      },
      {
        name: "gitlab_update_issue",
        description:
          "Update an issue's description, milestone, assignees, labels, or state. Pass only the fields you want to change.",
        inputSchema: {
          type: "object",
          properties: {
            issue_iid: {
              type: "number",
              description: "The internal ID (IID) of the issue",
            },
            description: {
              type: "string",
              description: "New description for the issue (Markdown supported)",
            },
            milestone_id: {
              type: "number",
              description:
                "Milestone ID to assign (use 0 or null to remove milestone)",
            },
            assignee_ids: {
              type: "array",
              items: { type: "number" },
              description: "Array of user IDs to assign. Empty array to unassign all.",
            },
            labels: {
              type: "string",
              description: "Comma-separated list of labels",
            },
            title: {
              type: "string",
              description: "New title for the issue",
            },
            state_event: {
              type: "string",
              enum: ["close", "reopen"],
              description: "Change issue state: 'close' or 'reopen'",
            },
          },
          required: ["issue_iid"],
        },
      },
      {
        name: "gitlab_list_milestones",
        description:
          "List project milestones. Use this to find milestone IDs for filtering issues or assigning to issues.",
        inputSchema: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description: "Filter by milestone state: active, closed, or all",
              enum: ["active", "closed", "all"],
              default: "active",
            },
          },
        },
      },
      {
        name: "gitlab_list_project_members",
        description:
          "List project members. Use this to find user IDs for assigning issues.",
        inputSchema: {
          type: "object",
          properties: {
            per_page: {
              type: "number",
              description: "Number of members to return (default: 100)",
              default: 100,
            },
          },
        },
      },
      {
        name: "gitlab_create_mr_from_issue",
        description:
          "Create a merge request linked to an issue. The MR title will reference the issue and closing it will close the issue.",
        inputSchema: {
          type: "object",
          properties: {
            issue_iid: {
              type: "number",
              description: "The internal ID (IID) of the issue",
            },
            source_branch: {
              type: "string",
              description: "The source branch containing the changes",
            },
            target_branch: {
              type: "string",
              description:
                "The target branch to merge into (defaults to project default branch)",
            },
          },
          required: ["issue_iid", "source_branch"],
        },
      },
      {
        name: "gitlab_create_issue",
        description:
          "Create a new issue in the GitLab project. Returns the created issue details including IID and URL.",
        inputSchema: {
          type: "object",
          properties: {
            title: {
              type: "string",
              description: "The title of the issue (required)",
            },
            description: {
              type: "string",
              description:
                "Issue description. Supports GitLab-flavored Markdown.",
            },
            labels: {
              type: "string",
              description: "Comma-separated list of labels",
            },
            assignee_ids: {
              type: "array",
              items: { type: "number" },
              description: "Array of user IDs to assign",
            },
            milestone_id: {
              type: "number",
              description: "Milestone ID to assign",
            },
            due_date: {
              type: "string",
              description: "Due date in YYYY-MM-DD format",
            },
            weight: {
              type: "number",
              description: "Issue weight (numeric)",
            },
            confidential: {
              type: "boolean",
              description: "Whether the issue is confidential",
              default: false,
            },
            issue_type: {
              type: "string",
              enum: ["issue", "incident", "task"],
              description: "Type of issue",
              default: "issue",
            },
          },
          required: ["title"],
        },
      },
      {
        name: "gitlab_create_sub_issue",
        description:
          "Create a sub-issue (child issue) linked to a parent issue. Creates the issue and establishes a parent-child relationship. On GitLab Premium 16.0+ uses native parent/child links, otherwise falls back to 'relates_to' link.",
        inputSchema: {
          type: "object",
          properties: {
            parent_issue_iid: {
              type: "number",
              description:
                "The internal ID (IID) of the parent issue to link to",
            },
            title: {
              type: "string",
              description: "The title of the sub-issue (required)",
            },
            description: {
              type: "string",
              description:
                "Sub-issue description. Supports GitLab-flavored Markdown.",
            },
            labels: {
              type: "string",
              description: "Comma-separated list of labels",
            },
            assignee_ids: {
              type: "array",
              items: { type: "number" },
              description: "Array of user IDs to assign",
            },
            milestone_id: {
              type: "number",
              description: "Milestone ID to assign",
            },
            due_date: {
              type: "string",
              description: "Due date in YYYY-MM-DD format",
            },
            weight: {
              type: "number",
              description: "Issue weight (numeric)",
            },
            confidential: {
              type: "boolean",
              description: "Whether the sub-issue is confidential",
              default: false,
            },
          },
          required: ["parent_issue_iid", "title"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      case "gitlab_list_mrs":
        result = runScript("list-mrs.sh", [
          args.state || "opened",
          args.per_page || 20,
        ]);
        break;

      case "gitlab_get_mr_details":
        result = runScript("get-mr-details.sh", [args.mr_iid]);
        break;

      case "gitlab_get_mr_comments":
        result = runScript("get-mr-comments.sh", [
          args.mr_iid,
          args.per_page || 50,
        ]);
        break;

      case "gitlab_get_mr_discussions":
        result = runScript("get-mr-discussions.sh", [
          args.mr_iid,
          args.per_page || 50,
        ]);
        break;

      case "gitlab_post_mr_comment":
        result = runScript("post-mr-comment.sh", [args.mr_iid, args.body]);
        break;

      case "gitlab_reply_to_discussion":
        result = runScript("reply-to-discussion.sh", [
          args.mr_iid,
          args.discussion_id,
          args.body,
        ]);
        break;

      case "gitlab_resolve_discussion":
        result = runScript("resolve-discussion.sh", [
          args.mr_iid,
          args.discussion_id,
          args.resolve !== false ? "true" : "false",
        ]);
        break;

      case "gitlab_get_mr_diff_versions":
        result = runScript("get-mr-diff-versions.sh", [args.mr_iid]);
        break;

      case "gitlab_post_mr_diff_comment": {
        const diffPayload = {
          body: args.body,
          position: {
            position_type: "text",
            base_sha: args.base_sha,
            head_sha: args.head_sha,
            start_sha: args.start_sha,
            new_path: args.new_path,
            old_path: args.old_path || args.new_path,
          },
        };
        if (args.new_line !== undefined) diffPayload.position.new_line = args.new_line;
        if (args.old_line !== undefined) diffPayload.position.old_line = args.old_line;
        result = runScript("post-mr-diff-comment.sh", [
          args.mr_iid,
          JSON.stringify(diffPayload),
        ]);
        break;
      }

      // Issue tools
      case "gitlab_list_issues":
        result = runScript("list-issues.sh", [
          args.state || "opened",
          args.milestone || "",
          args.per_page || 20,
        ]);
        break;

      case "gitlab_get_issue_details":
        result = runScript("get-issue-details.sh", [args.issue_iid]);
        break;

      case "gitlab_get_issue_comments":
        result = runScript("get-issue-comments.sh", [
          args.issue_iid,
          args.per_page || 50,
        ]);
        break;

      case "gitlab_post_issue_comment":
        result = runScript("post-issue-comment.sh", [args.issue_iid, args.body]);
        break;

      case "gitlab_update_issue": {
        const payload = {};
        if (args.description !== undefined) payload.description = args.description;
        if (args.milestone_id !== undefined) payload.milestone_id = args.milestone_id;
        if (args.assignee_ids !== undefined) payload.assignee_ids = args.assignee_ids;
        if (args.labels !== undefined) payload.labels = args.labels;
        if (args.title !== undefined) payload.title = args.title;
        if (args.state_event !== undefined) payload.state_event = args.state_event;
        result = runScript("update-issue.sh", [
          args.issue_iid,
          JSON.stringify(payload),
        ]);
        break;
      }

      case "gitlab_list_milestones":
        result = runScript("list-milestones.sh", [args.state || "active"]);
        break;

      case "gitlab_list_project_members":
        result = runScript("list-project-members.sh", [args.per_page || 100]);
        break;

      case "gitlab_create_mr_from_issue":
        result = runScript("create-mr-from-issue.sh", [
          args.issue_iid,
          args.source_branch,
          args.target_branch || "",
        ]);
        break;

      case "gitlab_create_issue": {
        const createPayload = {};
        createPayload.title = args.title;
        if (args.description !== undefined) createPayload.description = args.description;
        if (args.labels !== undefined) createPayload.labels = args.labels;
        if (args.assignee_ids !== undefined) createPayload.assignee_ids = args.assignee_ids;
        if (args.milestone_id !== undefined) createPayload.milestone_id = args.milestone_id;
        if (args.due_date !== undefined) createPayload.due_date = args.due_date;
        if (args.weight !== undefined) createPayload.weight = args.weight;
        if (args.confidential !== undefined) createPayload.confidential = args.confidential;
        if (args.issue_type !== undefined) createPayload.issue_type = args.issue_type;
        result = runScript("create-issue.sh", [JSON.stringify(createPayload)]);
        break;
      }

      case "gitlab_create_sub_issue": {
        const subPayload = {};
        subPayload.title = args.title;
        if (args.description !== undefined) subPayload.description = args.description;
        if (args.labels !== undefined) subPayload.labels = args.labels;
        if (args.assignee_ids !== undefined) subPayload.assignee_ids = args.assignee_ids;
        if (args.milestone_id !== undefined) subPayload.milestone_id = args.milestone_id;
        if (args.due_date !== undefined) subPayload.due_date = args.due_date;
        if (args.weight !== undefined) subPayload.weight = args.weight;
        if (args.confidential !== undefined) subPayload.confidential = args.confidential;
        result = runScript("create-sub-issue.sh", [
          args.parent_issue_iid,
          JSON.stringify(subPayload),
        ]);
        break;
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: "text",
          text: result,
        },
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("GitLab MR MCP Server running on stdio");
}

main().catch(console.error);
