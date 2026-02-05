#!/bin/bash
# install.sh — Universal installer for awesome-agent-toolkit
#
# Usage:
#   ./install.sh [plugin] [agent]
#
# Examples:
#   ./install.sh sonarqube          # Auto-detect agent
#   ./install.sh sonarqube claude   # Install for Claude Code
#   ./install.sh sonarqube gemini   # Install for Gemini CLI
#   ./install.sh sonarqube codex    # Install for Codex CLI
#   ./install.sh sonarqube cursor   # Install for Cursor

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
    elif [ -d ".gemini" ] || [ -f "GEMINI.md" ]; then
        echo "gemini"
    elif [ -d ".codex" ] || [ -f "$HOME/.codex/config.toml" ]; then
        echo "codex"
    elif [ -d ".cursor" ]; then
        echo "cursor"
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
        log_warn "Could not auto-detect agent. Please specify: claude, gemini, codex, or cursor"
        echo "Usage: ./install.sh $PLUGIN [agent]"
        exit 1
    fi
    log_info "Auto-detected agent: $AGENT"
fi

# Validate adapter exists
if [ ! -d "$TOOLKIT_DIR/adapters/$AGENT" ]; then
    log_error "Adapter for '$AGENT' not found"
    echo "Available adapters: claude, gemini, codex, cursor"
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
        echo "  2. Fill in your SonarQube credentials"
        echo "  3. Restart Claude Code"
        ;;

    gemini)
        # Copy context file
        cp "$TOOLKIT_DIR/adapters/gemini/GEMINI.md" .

        # Copy MCP config (user needs to merge into ~/.gemini/settings.json)
        mkdir -p .gemini
        cp "$TOOLKIT_DIR/adapters/gemini/mcp-config.json" .gemini/

        # Copy core scripts
        mkdir -p .gemini/scripts
        cp -r "$TOOLKIT_DIR/core/$PLUGIN/scripts/"* .gemini/scripts/
        chmod +x .gemini/scripts/*.sh

        # Copy env example
        cp "$TOOLKIT_DIR/core/$PLUGIN/.env.example" .gemini/.env.example

        log_info "Gemini CLI integration installed"
        log_info "Next steps:"
        echo "  1. Copy .gemini/.env.example to .gemini/.env"
        echo "  2. Fill in your SonarQube credentials"
        echo "  3. Add MCP server config to ~/.gemini/settings.json"
        ;;

    codex)
        # Copy skill file
        mkdir -p ~/.codex/skills
        cp "$TOOLKIT_DIR/adapters/codex/skills/"* ~/.codex/skills/

        # Copy MCP config (user needs to merge into ~/.codex/config.toml)
        log_info "MCP config template saved. Merge into ~/.codex/config.toml:"
        cat "$TOOLKIT_DIR/adapters/codex/mcp-config.toml"

        # Copy core scripts
        mkdir -p .codex/scripts
        cp -r "$TOOLKIT_DIR/core/$PLUGIN/scripts/"* .codex/scripts/
        chmod +x .codex/scripts/*.sh

        # Copy env example
        cp "$TOOLKIT_DIR/core/$PLUGIN/.env.example" .codex/.env.example

        log_info "Codex CLI integration installed"
        log_info "Next steps:"
        echo "  1. Copy .codex/.env.example to .codex/.env"
        echo "  2. Fill in your SonarQube credentials"
        echo "  3. Merge MCP config into ~/.codex/config.toml"
        ;;

    cursor)
        # Copy rules file
        if [ -f ".cursorrules" ]; then
            log_warn ".cursorrules already exists, appending..."
            echo "" >> .cursorrules
            cat "$TOOLKIT_DIR/adapters/cursor/.cursorrules" >> .cursorrules
        else
            cp "$TOOLKIT_DIR/adapters/cursor/.cursorrules" .
        fi

        # Copy MCP config
        mkdir -p .cursor
        cp "$TOOLKIT_DIR/adapters/cursor/mcp.json" .cursor/

        # Copy core scripts
        mkdir -p .cursor/scripts
        cp -r "$TOOLKIT_DIR/core/$PLUGIN/scripts/"* .cursor/scripts/
        chmod +x .cursor/scripts/*.sh

        # Copy env example
        cp "$TOOLKIT_DIR/core/$PLUGIN/.env.example" .cursor/.env.example

        log_info "Cursor integration installed"
        log_info "Next steps:"
        echo "  1. Copy .cursor/.env.example to .cursor/.env"
        echo "  2. Fill in your SonarQube credentials"
        echo "  3. Restart Cursor"
        ;;

    *)
        log_error "Unknown agent: $AGENT"
        exit 1
        ;;
esac

log_info "Installation complete!"
