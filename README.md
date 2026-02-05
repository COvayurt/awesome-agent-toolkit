# Awesome Agent Toolkit

> Universal plugins for AI coding agents — write once, run on Claude, Gemini, Codex, Cursor, and more.

Most AI coding tools have their own plugin/extension formats. This toolkit solves that fragmentation by providing **agent-agnostic core implementations** with thin adapters for each platform.

## Why?

| Problem | Solution |
|---------|----------|
| Each AI agent has different plugin formats | Core logic is shared, adapters handle the wiring |
| MCP servers work everywhere but need setup | Pre-configured MCP configs for each agent |
| Duplicating integrations across tools | One source of truth in `core/` |

## Supported Agents

| Agent | Status | Native Features Used |
|-------|--------|---------------------|
| [Claude Code](https://claude.ai/code) | ✅ Full | Plugins, Skills, Hooks, MCP |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | ✅ Full | Extensions, GEMINI.md, MCP |
| [Codex CLI](https://openai.com/codex) | ✅ Full | Skills, MCP |
| [Cursor](https://cursor.sh) | ✅ Full | .cursorrules, MCP |
| Any MCP-compatible agent | ✅ MCP only | MCP servers |

## Available Plugins

### SonarQube

Static code analysis integration — fetch issues, run scans, auto-fix code quality problems.

| Feature | Description |
|---------|-------------|
| Fetch Issues | Query open issues by severity, file, or new code period |
| Run Analysis | Execute SonarQube scan via Gradle |
| Auto-Context | Hook injects issues when you mention "sonar" in prompts |
| MCP Tools | `sonar_fetch_issues`, `sonar_run_analysis`, `sonar_format_issues` |

## Installation

### One-Line Install

```bash
# From your project directory
curl -sL https://raw.githubusercontent.com/covayurt/awesome-agent-toolkit/main/install.sh | bash -s sonarqube claude
```

### Manual Install

```bash
# Clone the toolkit
git clone https://github.com/covayurt/awesome-agent-toolkit ~/awesome-agent-toolkit

# Install plugin (auto-detects your agent)
~/awesome-agent-toolkit/install.sh sonarqube

# Or specify agent explicitly
~/awesome-agent-toolkit/install.sh sonarqube claude
~/awesome-agent-toolkit/install.sh sonarqube gemini
~/awesome-agent-toolkit/install.sh sonarqube codex
~/awesome-agent-toolkit/install.sh sonarqube cursor
```

### Post-Install

1. Copy `.env.example` to `.env` in the appropriate directory
2. Fill in your credentials
3. Restart your AI agent

## Usage

### Claude Code

```bash
# Use the skill directly
> /sonarqube:sonar

# Or just mention sonar in your prompt (hook auto-triggers)
> show me sonar issues
> fix high severity code smells
> fetch medium sonar issues for new code
```

### Other Agents

Use MCP tools directly or mention SonarQube in your prompts:

```
fetch sonarqube issues with high severity
run sonar analysis on this project
```

### Severity Keywords

Include these in your prompt to filter issues:

| Keyword | Severity Filter |
|---------|-----------------|
| `blocker` | BLOCKER |
| `high`, `critical` | HIGH |
| `medium` | MEDIUM |
| `low` | LOW |
| `info` | INFO |
| `new code` | New code period only |

## Architecture

```
awesome-agent-toolkit/
│
├── core/                        # Agent-agnostic implementations
│   └── sonarqube/
│       ├── scripts/             # Portable shell scripts
│       │   ├── fetch-issues.sh
│       │   ├── run-analysis.sh
│       │   └── format-issues.py
│       ├── mcp-server/          # Universal MCP server
│       │   ├── index.js
│       │   └── package.json
│       └── .env.example
│
├── adapters/                    # Agent-specific configurations
│   ├── claude/                  # Claude Code plugin
│   │   ├── .claude-plugin/
│   │   ├── skills/
│   │   ├── hooks/
│   │   └── .mcp.json
│   ├── gemini/                  # Gemini CLI
│   │   ├── GEMINI.md
│   │   └── mcp-config.json
│   ├── codex/                   # Codex CLI
│   │   ├── skills/
│   │   └── mcp-config.toml
│   └── cursor/                  # Cursor
│       ├── .cursorrules
│       └── mcp.json
│
├── install.sh                   # Universal installer
└── README.md
```

### Design Principles

1. **Core is agent-agnostic** — Shell scripts and MCP servers work everywhere
2. **Adapters are thin** — Just configuration, no duplicated logic
3. **MCP is the universal layer** — All agents support Model Context Protocol
4. **Progressive enhancement** — MCP works standalone; native features add convenience

## Configuration

### Environment Variables

Create `.env` in the appropriate directory for your agent:

```bash
# SonarQube connection
SONAR_HOST_URL=https://sonarqube.example.com
SONAR_TOKEN=sqa_xxxxxxxxxxxxx
SONAR_PROJECT_KEY=my-project
```

### MCP Server

The MCP server exposes three tools:

| Tool | Description | Parameters |
|------|-------------|------------|
| `sonar_fetch_issues` | Fetch open issues | `severity`, `newCode`, `file` |
| `sonar_run_analysis` | Run SonarQube scan | — |
| `sonar_format_issues` | Format JSON as markdown | `json` |

## Contributing

### Adding a New Plugin

1. Create core implementation:
   ```
   core/your-plugin/
   ├── scripts/          # Shell scripts
   ├── mcp-server/       # MCP server (optional)
   └── .env.example
   ```

2. Create adapters for each agent:
   ```
   adapters/claude/      # Add plugin.json, skills, hooks
   adapters/gemini/      # Add GEMINI.md, mcp-config
   adapters/codex/       # Add skills
   adapters/cursor/      # Add .cursorrules
   ```

3. Update `install.sh` to handle your plugin

### Adding a New Agent

1. Research the agent's extension format
2. Create adapter directory in `adapters/`
3. Add installation logic to `install.sh`
4. Update this README

## License

MIT

## Links

- [Claude Code Plugins Docs](https://docs.anthropic.com/claude-code/plugins)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [Codex CLI](https://openai.com/codex)
- [Model Context Protocol](https://modelcontextprotocol.io)
