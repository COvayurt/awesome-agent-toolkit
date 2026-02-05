# Awesome Agent Toolkit

Universal plugins for AI coding agents — write once, run on Claude, Gemini, Codex, Cursor, and more.

## Supported Agents

| Agent | MCP | Native Features |
|-------|-----|-----------------|
| Claude Code | ✅ | Plugins, Skills, Hooks |
| Gemini CLI | ✅ | Extensions, GEMINI.md |
| Codex CLI | ✅ | Skills |
| Cursor | ✅ | .cursorrules |

## Plugins

| Plugin | Description |
|--------|-------------|
| [sonarqube](./core/sonarqube/) | Fetch issues, run analysis, auto-fix code quality |

---

## Installation

### Claude Code

```bash
# Add marketplace (one-time)
/plugin marketplace add covayurt/awesome-agent-toolkit

# Install plugin
/plugin install sonarqube
```

Or test locally:
```bash
claude --plugin-dir /path/to/awesome-agent-toolkit/adapters/claude
```

### Gemini CLI

```bash
# Copy context file
cp adapters/gemini/GEMINI.md /your/project/

# Add MCP server to ~/.gemini/settings.json
```

### Codex CLI

```bash
# Copy skill
cp adapters/codex/skills/sonar.md ~/.codex/skills/

# Add MCP config to ~/.codex/config.toml
```

### Cursor

```bash
# Copy rules and MCP config
cp adapters/cursor/.cursorrules /your/project/
cp adapters/cursor/mcp.json /your/project/.cursor/
```

### Manual Install (Any Agent)

```bash
./install.sh sonarqube claude   # or: gemini, codex, cursor
```

---

## Configuration

Create `.env` in your project's config directory:

```bash
SONAR_HOST_URL=https://sonarqube.example.com
SONAR_TOKEN=sqa_xxxxxxxxxxxxx
SONAR_PROJECT_KEY=my-project
```

---

## Usage

### Claude Code

```
/sonarqube:sonar              # invoke skill directly
show me sonar issues          # hook auto-triggers
fix high severity issues      # severity filter
```

### MCP Tools (All Agents)

| Tool | Description |
|------|-------------|
| `sonar_fetch_issues` | Fetch open issues (params: severity, newCode, file) |
| `sonar_run_analysis` | Run SonarQube scan |
| `sonar_format_issues` | Format JSON as markdown |

### Severity Keywords

`blocker` · `high` · `medium` · `low` · `info` · `new code`

---

## Architecture

```
awesome-agent-toolkit/
├── core/                    # Agent-agnostic (scripts + MCP server)
│   └── sonarqube/
├── adapters/                # Agent-specific configs
│   ├── claude/
│   ├── gemini/
│   ├── codex/
│   └── cursor/
└── install.sh
```

## License

MIT
