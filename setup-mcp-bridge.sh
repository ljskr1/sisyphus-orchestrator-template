#!/bin/bash
# Auto-setup script for Antigravity + OpenCode MCP Bridge — Optimized
# Run: chmod +x setup-mcp-bridge.sh && ./setup-mcp-bridge.sh

set -e

DRY_RUN=false
for arg in "$@"; do
    if [ "$arg" = "--dry-run" ]; then
        DRY_RUN=true
    fi
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_DIR="$HOME/opencode-mcp"
MCP_REPO="https://github.com/Traves-Theberge/opencode-mcp.git"
PORT=4096

dry_run_skip() {
    if $DRY_RUN; then
        echo "  [DRY RUN] Would: $1"
        return 0
    fi
    return 1
}

echo "=== Antigravity + OpenCode MCP Setup (Optimized) ==="
if $DRY_RUN; then
    echo "*** DRY RUN MODE — no changes will be made ***"
fi

# 1. Check prerequisites
echo -e "\n[1/5] Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found. Please install Node.js."
    exit 1
fi
echo "  Node.js: $(node --version)"

if ! command -v opencode &> /dev/null; then
    echo "ERROR: opencode CLI not found. Install: npm i -g opencode-ai"
    exit 1
fi
echo "  opencode: found"

# 2. Clone and build opencode-mcp
echo -e "\n[2/5] Setting up opencode-mcp..."

if [ -f "$MCP_DIR/dist/index.js" ]; then
    echo "  Already built. Skipping clone/build."
elif [ -d "$MCP_DIR" ]; then
    echo "  Directory exists but not built. Building..."
    if ! dry_run_skip "cd $MCP_DIR && npm install && npm run build"; then
        cd "$MCP_DIR"
        npm install
        npm run build
        cd "$REPO_DIR"
    fi
else
    echo "  Cloning opencode-mcp..."
    if ! dry_run_skip "git clone $MCP_REPO $MCP_DIR && cd $MCP_DIR && npm install && npm run build"; then
        git clone "$MCP_REPO" "$MCP_DIR"
        cd "$MCP_DIR"
        npm install
        npm run build
        cd "$REPO_DIR"
    fi
fi

if ! $DRY_RUN; then
    if [ ! -f "$MCP_DIR/dist/index.js" ]; then
        echo "ERROR: Build failed. dist/index.js not found."
        exit 1
    fi
    echo "  Build complete"
else
    echo "  [DRY RUN] Would verify dist/index.js exists"
fi

# 3. Create Antigravity MCP config
echo -e "\n[3/5] Creating Antigravity MCP config (optimized)..."

ANTIGRAVITY_DIR="$HOME/.gemini/antigravity-ide"
MCP_CONFIG_PATH="$ANTIGRAVITY_DIR/mcp_config.json"
SOURCE_CONFIG="$REPO_DIR/mcp-bridge-config.json"

if ! $DRY_RUN; then
    if [ ! -f "$SOURCE_CONFIG" ]; then
        echo "  ERROR: mcp-bridge-config.json not found in repo"
        exit 1
    fi
    echo "  Validating JSON..."
    if command -v python3 &> /dev/null; then
        if ! python3 -c "import json; json.load(open('$SOURCE_CONFIG'))" 2>/dev/null; then
            echo "  ERROR: $SOURCE_CONFIG is not valid JSON"
            exit 1
        fi
    elif command -v jq &> /dev/null; then
        if ! jq empty "$SOURCE_CONFIG" 2>/dev/null; then
            echo "  ERROR: $SOURCE_CONFIG is not valid JSON"
            exit 1
        fi
    else
        echo "  WARNING: Neither python3 nor jq found, skipping JSON validation"
    fi
    echo "  JSON validation passed"
fi

if ! dry_run_skip "mkdir -p $ANTIGRAVITY_DIR && cp $SOURCE_CONFIG $MCP_CONFIG_PATH"; then
    mkdir -p "$ANTIGRAVITY_DIR"
    cp "$SOURCE_CONFIG" "$MCP_CONFIG_PATH"
    echo "  Config copied to: $MCP_CONFIG_PATH"

    if grep -q '/Users/your-username/your-project' "$MCP_CONFIG_PATH"; then
        sed -i '' "s|/Users/your-username/your-project|$REPO_DIR|g" "$MCP_CONFIG_PATH"
        echo "  Replaced placeholder project path with $REPO_DIR"
    fi
    if grep -q '/Users/your-username/' "$MCP_CONFIG_PATH"; then
        sed -i '' "s|/Users/your-username/|$HOME/|g" "$MCP_CONFIG_PATH"
        echo "  Replaced placeholder user paths with $HOME/"
    fi
fi

# 4. Start opencode serve
echo -e "\n[4/5] Starting opencode server on port $PORT..."
SERVER_PID=""

if lsof -i :$PORT &> /dev/null; then
    echo "  Port $PORT already in use. Skipping start."
else
    if ! dry_run_skip "opencode serve --port $PORT"; then
        opencode serve --port $PORT &
        SERVER_PID=$!
        echo "  Server started with PID $SERVER_PID"
    fi

    if ! $DRY_RUN; then
        echo "  Waiting for server to be ready..."
        RETRY_MAX=10
        RETRY_INTERVAL=2
        for i in $(seq 1 $RETRY_MAX); do
            if curl -s "http://localhost:$PORT/global/health" > /dev/null 2>&1; then
                echo "  Server is ready (attempt $i/$RETRY_MAX)"
                break
            fi
            if [ "$i" -eq "$RETRY_MAX" ]; then
                echo "  WARNING: Server did not respond after $RETRY_MAX attempts"
                echo "  Check manually: curl http://localhost:$PORT/global/health"
                if [ -n "$SERVER_PID" ]; then
                    echo "  Cleaning up server PID $SERVER_PID..."
                    kill "$SERVER_PID" 2>/dev/null || true
                fi
            else
                echo "  Attempt $i/$RETRY_MAX — not ready yet, waiting ${RETRY_INTERVAL}s..."
                sleep "$RETRY_INTERVAL"
            fi
        done
    fi
fi

# 5. Summary + Token Optimization Tips
echo -e "\n[5/5] Setup complete!"
echo -e "\n=== Next Steps ==="
echo "1. Restart Antigravity IDE (close and reopen)"
echo "2. In Antigravity chat, run a test query like:"
echo "   \"Use opencode_run to list files in the current folder.\""
echo ""
echo "=== Token Optimization Tips ==="
echo "To maximize token savings on Path C (MCP Bridge):"
echo "1. REUSE SESSIONS: Use opencode_session_prompt rather than creating fresh sessions."
echo "2. TRUNCATE OUTPUTS: Limit files and command results to prevent bloated history."
