#!/usr/bin/env node
/**
 * SonarQube MCP Server
 *
 * Provides SonarQube integration via Model Context Protocol.
 * Works with Claude Code, Gemini CLI, Codex CLI, Cursor, and any MCP-compatible agent.
 *
 * Environment variables required:
 *   SONAR_HOST_URL    - SonarQube server URL
 *   SONAR_TOKEN       - Authentication token
 *   SONAR_PROJECT_KEY - Project key in SonarQube
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { execSync } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const SCRIPTS_DIR = join(__dirname, "..", "scripts");

const server = new Server(
  {
    name: "sonarqube",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler("tools/list", async () => {
  return {
    tools: [
      {
        name: "sonar_fetch_issues",
        description: "Fetch open issues from SonarQube for the current project",
        inputSchema: {
          type: "object",
          properties: {
            severity: {
              type: "string",
              description: "Filter by impact severity (BLOCKER, HIGH, MEDIUM, LOW, INFO). Comma-separated for multiple.",
              default: "HIGH,MEDIUM"
            },
            newCode: {
              type: "boolean",
              description: "Only fetch issues in the new code period",
              default: false
            },
            file: {
              type: "string",
              description: "Filter to a specific file path (relative to project root)"
            }
          }
        }
      },
      {
        name: "sonar_run_analysis",
        description: "Run SonarQube analysis on the current project (requires Gradle)"
      },
      {
        name: "sonar_quality_gate",
        description: "Check quality gate status - returns PASSED, FAILED, or ERROR",
        inputSchema: {
          type: "object",
          properties: {
            branch: {
              type: "string",
              description: "Branch name to check (optional, defaults to main branch)"
            }
          }
        }
      },
      {
        name: "sonar_metrics",
        description: "Fetch project metrics like coverage, duplications, complexity, bugs count",
        inputSchema: {
          type: "object",
          properties: {
            metrics: {
              type: "string",
              description: "Comma-separated metric keys (e.g., coverage,bugs,code_smells). Defaults to common metrics."
            },
            branch: {
              type: "string",
              description: "Branch name (optional)"
            }
          }
        }
      },
      {
        name: "sonar_hotspots",
        description: "Fetch security hotspots that need review",
        inputSchema: {
          type: "object",
          properties: {
            status: {
              type: "string",
              enum: ["TO_REVIEW", "REVIEWED"],
              description: "Filter by review status",
              default: "TO_REVIEW"
            },
            file: {
              type: "string",
              description: "Filter to a specific file"
            },
            branch: {
              type: "string",
              description: "Branch name (optional)"
            }
          }
        }
      },
      {
        name: "sonar_rule_details",
        description: "Get detailed explanation of a SonarQube rule including description and fix examples",
        inputSchema: {
          type: "object",
          properties: {
            rule: {
              type: "string",
              description: "Rule key (e.g., java:S2140, python:S1234)"
            }
          },
          required: ["rule"]
        }
      },
      {
        name: "sonar_format_issues",
        description: "Format SonarQube JSON response as a readable markdown table",
        inputSchema: {
          type: "object",
          properties: {
            json: {
              type: "string",
              description: "Raw JSON response from SonarQube API"
            }
          },
          required: ["json"]
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "sonar_fetch_issues": {
        const cmdArgs = [];
        if (args?.severity) cmdArgs.push("--severity", args.severity);
        if (args?.newCode) cmdArgs.push("--new-code");
        if (args?.file) cmdArgs.push("--file", args.file);

        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "fetch-issues.sh")}" ${cmdArgs.join(" ")}`,
          { encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_run_analysis": {
        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "run-analysis.sh")}"`,
          { encoding: "utf-8", env: process.env, cwd: process.cwd() }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_quality_gate": {
        const cmdArgs = [];
        if (args?.branch) cmdArgs.push("--branch", args.branch);

        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "quality-gate.sh")}" ${cmdArgs.join(" ")}`,
          { encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_metrics": {
        const cmdArgs = [];
        if (args?.metrics) cmdArgs.push("--metrics", args.metrics);
        if (args?.branch) cmdArgs.push("--branch", args.branch);

        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "metrics.sh")}" ${cmdArgs.join(" ")}`,
          { encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_hotspots": {
        const cmdArgs = [];
        if (args?.status) cmdArgs.push("--status", args.status);
        if (args?.file) cmdArgs.push("--file", args.file);
        if (args?.branch) cmdArgs.push("--branch", args.branch);

        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "hotspots.sh")}" ${cmdArgs.join(" ")}`,
          { encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_rule_details": {
        if (!args?.rule) {
          return { content: [{ type: "text", text: "Error: rule argument is required (e.g., java:S2140)" }] };
        }
        const result = execSync(
          `bash "${join(SCRIPTS_DIR, "rule-details.sh")}" --rule "${args.rule}"`,
          { encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      case "sonar_format_issues": {
        if (!args?.json) {
          return { content: [{ type: "text", text: "Error: json argument is required" }] };
        }
        const result = execSync(
          `python3 "${join(SCRIPTS_DIR, "format-issues.py")}"`,
          { input: args.json, encoding: "utf-8", env: process.env }
        );
        return { content: [{ type: "text", text: result }] };
      }

      default:
        return { content: [{ type: "text", text: `Unknown tool: ${name}` }] };
    }
  } catch (error) {
    return {
      content: [{
        type: "text",
        text: `Error executing ${name}: ${error.message}\n${error.stderr || ""}`
      }]
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("SonarQube MCP server running on stdio");
}

main().catch(console.error);
