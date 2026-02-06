#!/bin/bash
# install.sh — Universal installer for awesome-agent-toolkit
#
# Usage:
#   ./install.sh [plugin] [agent]
#
# Examples:
#   ./install.sh sonarqube          # Auto-detect agent
#   ./install.sh sonarqube claude   # Install for Claude Code
#   ./install.sh sonarqube codex    # Install for Codex CLI

set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="${1:-sonarqube}"
AGENT="${2:-auto}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Auto-detect agent based on existing config files
detect_agent() {
    if [ -d ".claude" ] || [ -f "CLAUDE.md" ]; then
        echo "claude"
    elif [ -d ".codex" ] || [ -f "$HOME/.codex/config.toml" ]; then
        echo "codex"
    else
        echo "unknown"
    fi
}

# Validate plugin exists
if [ ! -d "$TOOLKIT_DIR/core/$PLUGIN" ]; then
    log_error "Plugin '$PLUGIN' not found in $TOOLKIT_DIR/core/"
    echo "Available plugins:"
    ls -1 "$TOOLKIT_DIR/core/"
    exit 1
fi

# Auto-detect agent if not specified
if [ "$AGENT" = "auto" ]; then
    AGENT=$(detect_agent)
    if [ "$AGENT" = "unknown" ]; then
        log_warn "Could not auto-detect agent. Please specify: claude or codex"
        echo "Usage: ./install.sh $PLUGIN [agent]"
        exit 1
    fi
    log_info "Auto-detected agent: $AGENT"
fi

# Validate adapter exists
if [ ! -d "$TOOLKIT_DIR/adapters/$AGENT" ]; then
    log_error "Adapter for '$AGENT' not found"
    echo "Available adapters: claude, codex"
    exit 1
fi

log_info "Installing $PLUGIN for $AGENT..."

case "$AGENT" in
    claude)
        # Create .claude directory structure
        mkdir -p .claude/hooks .claude/skills

        # Copy core scripts
        mkdir -p .claude/scripts
        cp -r "$TOOLKIT_DIR/core/$PLUGIN/scripts/"* .claude/scripts/
        chmod +x .claude/scripts/*.sh

        # Copy adapter files
        cp -r "$TOOLKIT_DIR/adapters/claude/.claude-plugin" .claude/
        cp -r "$TOOLKIT_DIR/adapters/claude/skills/"* .claude/skills/
        cp -r "$TOOLKIT_DIR/adapters/claude/hooks/"* .claude/hooks/
        chmod +x .claude/hooks/*.sh 2>/dev/null || true

        # Copy MCP config if exists
        if [ -f "$TOOLKIT_DIR/adapters/claude/.mcp.json" ]; then
            cp "$TOOLKIT_DIR/adapters/claude/.mcp.json" .claude/
        fi

        # Copy env example
        cp "$TOOLKIT_DIR/core/$PLUGIN/.env.example" .claude/.env.example

        log_info "Claude Code plugin installed to .claude/"
        log_info "Next steps:"
        echo "  1. Copy .claude/.env.example to .claude/.env"
        echo "  2. Fill in your credentials"
        echo "  3. Restart Claude Code"
        ;;

    codex)
        # Copy skills to ~/.agents/skills/ (Codex skill location)
        mkdir -p ~/.agents/skills

        # Copy each skill directory
        for skill_dir in "$TOOLKIT_DIR/adapters/codex/skills/"*/; do
            skill_name=$(basename "$skill_dir")
            log_info "Installing skill: $skill_name"
            cp -r "$skill_dir" ~/.agents/skills/
            chmod +x ~/.agents/skills/"$skill_name"/scripts/*.sh 2>/dev/null || true
        done

        log_info "Codex CLI skills installed to ~/.agents/skills/"
        log_info "Next steps:"
        echo "  1. Enable skills: codex --enable skills"
        echo "  2. Add env vars to your shell profile (~/.bashrc or ~/.zshrc):"
        echo "     export GITLAB_HOST_URL=https://gitlab.com"
        echo "     export GITLAB_TOKEN=glpat-xxx"
        echo "     export GITLAB_PROJECT_ID=12345"
        echo "     export SONAR_HOST_URL=https://sonarqube.example.com"
        echo "     export SONAR_TOKEN=sqa_xxx"
        echo "     export SONAR_PROJECT_KEY=my-project"
        echo "  3. Restart your shell and Codex"
        ;;

    *)
        log_error "Unknown agent: $AGENT"
        echo "Supported agents: claude, codex"
        exit 1
        ;;
esac

log_info "Installation complete!"
