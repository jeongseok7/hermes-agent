#!/bin/bash
# Docker entrypoint: bootstrap config files into the mounted volume, then run hermes.
set -e

HERMES_HOME="/opt/data"
INSTALL_DIR="/opt/hermes"

# Create essential directory structure.  Cache and platform directories
# (cache/images, cache/audio, platforms/whatsapp, etc.) are created on
# demand by the application — don't pre-create them here so new installs
# get the consolidated layout from get_hermes_dir().
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills} 2>/dev/null || true

# .env
if [ ! -f "$HERMES_HOME/.env" ] && [ -f "$INSTALL_DIR/.env.example" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env" 2>/dev/null || true
fi

# config.yaml
if [ ! -f "$HERMES_HOME/config.yaml" ] && [ -f "$INSTALL_DIR/cli-config.yaml.example" ]; then
    cp "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml" 2>/dev/null || true
fi

# SOUL.md
if [ ! -f "$HERMES_HOME/SOUL.md" ] && [ -f "$INSTALL_DIR/docker/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md" 2>/dev/null || true
fi

# Sync bundled skills (manifest-based so user edits are preserved)
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" || echo "Warning: skills sync failed (non-fatal)"
fi

# Install custom CA certificate into system trust store if mounted
CUSTOM_CA="/opt/custom-ca.pem"
if [ -f "$CUSTOM_CA" ] && [ -s "$CUSTOM_CA" ]; then
    cp "$CUSTOM_CA" /usr/local/share/ca-certificates/custom-ca.crt
    update-ca-certificates
fi

# Configure Composio MCP server if API key is provided
if [ -n "$COMPOSIO_API_KEY" ]; then
    python3 -c "
import yaml, sys
config_path = '$HERMES_HOME/config.yaml'
try:
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f) or {}
except Exception:
    config = {}
if 'mcp_servers' not in config or not isinstance(config.get('mcp_servers'), dict):
    config['mcp_servers'] = {}
config['mcp_servers']['composio'] = {
    'url': 'https://connect.composio.dev/mcp',
    'headers': {'x-consumer-api-key': '\${COMPOSIO_API_KEY}'},
}
with open(config_path, 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)
print('Composio MCP server configured')
" || echo "Warning: Composio config update failed (non-fatal)"
fi

exec hermes "$@"
