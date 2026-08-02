#!/bin/bash
set -e

echo "[PhantomCode] Initializing PhantomCode Environment..."

# 1. Start claude-code-router in the background
# The 'ccr start' command runs the router on port 3456 and Web UI on 3458
echo "[PhantomCode] Starting claude-code-router..."
# We run it with nohup to keep it running and bind to 0.0.0.0 so it can be accessed from outside the container!
nohup ccr start --host 0.0.0.0 > /var/log/ccr.log 2>&1 &

# Give the router a moment to spin up
sleep 2

# 2. Inject configuration for the official Claude extension
# The official Claude VS Code extension looks at the ANTHROPIC_BASE_URL env var or settings.
# We will inject this globally for the container!
export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"

# Inject into bashrc so terminal sessions get it too (for Claude Code CLI)
if ! grep -q "ANTHROPIC_BASE_URL" /root/.bashrc; then
    echo 'export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"' >> /root/.bashrc
    echo 'export ANTHROPIC_API_KEY="sk-phantom-dummy"' >> /root/.bashrc
fi

# We also ensure the code-server data directory exists
USER_DATA_DIR="/root/.local/share/code-server/User"
mkdir -p "$USER_DATA_DIR"

SETTINGS_FILE="$USER_DATA_DIR/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "{}" > "$SETTINGS_FILE"
fi

# Pre-install the official Claude extension if it's not already installed
# Since we injected EXTENSIONS_GALLERY in Dockerfile, this will fetch from Microsoft Marketplace!
echo "[PhantomCode] Installing official Claude extension..."
code-server --install-extension anthropic.claude-code || true

# Add proxy config to VS Code settings to make sure the router UI works well
# (Optional tweak, code-server proxies out of the box anyway)

echo "[PhantomCode] Starting code-server Web IDE..."
# 3. Start code-server in the foreground, listening on all interfaces
# --auth none because we assume local/safe usage or reverse proxy wrapper.
# If you want password protection, remove --auth none and code-server will generate a password in ~/.config/code-server/config.yaml
exec code-server --bind-addr 0.0.0.0:8080 --auth none .
