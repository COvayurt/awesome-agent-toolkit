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
| [sonarqube](./core/sonarqube/) | Code quality, security hotspots, metrics, quality gates |

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

### Other Agents

```bash
./install.sh sonarqube gemini   # Gemini CLI
./install.sh sonarqube codex    # Codex CLI
./install.sh sonarqube cursor   # Cursor
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

## MCP Tools

| Tool | Description |
|------|-------------|
| `sonar_fetch_issues` | Fetch open issues (severity, newCode, file) |
| `sonar_quality_gate` | Check if project passes/fails quality gate |
| `sonar_metrics` | Get coverage, duplications, complexity, bugs count |
| `sonar_hotspots` | Fetch security hotspots to review |
| `sonar_rule_details` | Get rule explanation and fix examples |
| `sonar_run_analysis` | Run SonarQube scan via Gradle |

---

## Usage Examples

```
# Issues
show me sonar issues
fix high severity issues
fetch blocker issues for new code

# Quality gate
check quality gate status
is the quality gate passing?

# Metrics
show project metrics
what's the code coverage?

# Security
show security hotspots
review security hotspots

# Rules
explain rule java:S2140
what does rule python:S1234 mean?
```

---

## Architecture

```
awesome-agent-toolkit/
├── core/sonarqube/
│   ├── scripts/           # fetch-issues, quality-gate, metrics, hotspots, rule-details
│   └── mcp-server/        # Universal MCP server
├── adapters/
│   ├── claude/            # Plugin, skills, hooks
│   ├── gemini/            # GEMINI.md, mcp-config
│   ├── codex/             # Skills
│   └── cursor/            # .cursorrules
└── install.sh
```

## License

MIT
