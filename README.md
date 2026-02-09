# Awesome Agent Toolkit

Universal plugins for AI coding agents — SonarQube and GitLab integrations.

## Supported Agents

| Agent | Skills | Hooks |
|-------|--------|-------|
| Claude Code | ✅ | ✅ |
| Codex CLI | ✅ | - |

## Plugins

| Plugin | Description |
|--------|-------------|
| [sonarqube](./core/sonarqube/) | Code quality, security hotspots, metrics, quality gates |
| [gitlab-issues](./core/gitlab/) | List issues, manage comments, assign people, create MRs |
| [gitlab-mr](./core/gitlab/) | List MRs, review comments, resolve discussions |

---

## Installation

### Claude Code

```bash
# Add marketplace (one-time)
/plugin marketplace add COVayurt/awesome-agent-toolkit

# Install plugins
/plugin install sonarqube@awesome-agent-toolkit
/plugin install gitlab-issues@awesome-agent-toolkit
/plugin install gitlab-mr@awesome-agent-toolkit
```

### Configuration

Add environment variables to `~/.claude/settings.json`:

```json
{
  "env": {
    "SONAR_HOST_URL": "https://sonarqube.example.com",
    "SONAR_TOKEN": "sqa_xxxxxxxxxxxxx",
    "SONAR_PROJECT_KEY": "my-project",
    "GITLAB_HOST_URL": "https://gitlab.com",
    "GITLAB_TOKEN": "glpat-xxxxxxxxxxxx",
    "GITLAB_PROJECT_ID": "12345678"
  }
}
```

---

## Usage Examples

### SonarQube
```
fetch sonar issues from new code
check quality gate status
show security hotspots
explain rule java:S2140
```

### GitLab Issues
```
fetch gitlab issues by v1.31.0 milestone
show issue 45 details
assign issue 45 to alice
```

### GitLab MRs
```
list open merge requests
show MR 123 discussions
resolve discussion on MR 123
```

---

## Architecture

```
awesome-agent-toolkit/
├── core/
│   ├── sonarqube/scripts/    # fetch-issues, quality-gate, metrics
│   └── gitlab/scripts/       # list-issues, list-mrs, post-comment
├── adapters/
│   ├── claude/               # Skills, hooks for Claude Code
│   └── codex/                # Skills for Codex CLI
└── .claude-plugin/           # Marketplace metadata
```

## License

MIT
