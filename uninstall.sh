#!/usr/bin/env bash

# =============================================================================
# uninstall.sh - Remove components installed by setup-antigravity-opencode.sh
# =============================================================================
#
# What this script removes:
#   1. ~/opencode-mcp (cloned repository and built binaries)
#   2. ~/.gemini/antigravity-ide/mcp_config.json (MCP configuration)
#   3. Running opencode server process (port 4096)
#
# Safety measures:
#   - Only removes expected paths (nothing outside them)
#   - Checks for existence before removal
#   - Won't remove ~/.gemini if it has other contents
#   - Supports --dry-run to preview without changes
#
# Usage:
#   ./uninstall.sh              # Interactive removal
#   ./uninstall.sh --dry-run    # Preview what would be removed
#
# =============================================================================

set -e

# --- Configuration ---
OPENCODE_MCP_DIR="$HOME/opencode-mcp"
GEMINI_ANTIGRAVITY_DIR="$HOME/.gemini/antigravity-ide"
MCP_CONFIG_FILE="$GEMINI_ANTIGRAVITY_DIR/mcp_config.json"
OPENCODE_SERVER_PORT=4096
DRY_RUN=false

# --- Parse arguments ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

# --- Helper functions ---
log() {
  echo "→ $1"
}

warn() {
  echo "  ⚠ $1"
}

removed_count=0
skipped_count=0

remove_path() {
  local path="$1"
  local description="$2"

  if [ ! -e "$path" ]; then
    warn "$description not found, skipping"
    skipped_count=$((skipped_count + 1))
    return
  fi

  if $DRY_RUN; then
    log "[dry-run] Would remove: $description ($path)"
    removed_count=$((removed_count + 1))
    return
  fi

  log "Removing $description: $path"
  rm -rf "$path"
  removed_count=$((removed_count + 1))
  echo "  ✓ Removed"
}

# --- Main ---
if $DRY_RUN; then
  echo ""
  echo "========================================"
  echo "  DRY RUN - No changes will be made"
  echo "========================================"
  echo ""
else
  echo ""
  echo "========================================"
  echo "  Uninstalling opencode components"
  echo "========================================"
  echo ""
fi

# --- Step 1: Stop opencode server if running ---
echo "Step 1: Check for running opencode server"
if lsof -ti :$OPENCODE_SERVER_PORT >/dev/null 2>&1; then
  if $DRY_RUN; then
    log "[dry-run] Would stop opencode server on port $OPENCODE_SERVER_PORT"
  else
    log "Stopping opencode server on port $OPENCODE_SERVER_PORT"
    # Find PIDs using the port and kill them
    PIDS=$(lsof -ti :$OPENCODE_SERVER_PORT 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
      echo "$PIDS" | xargs kill 2>/dev/null || true
      # Wait briefly for process to exit
      sleep 1
      # Force kill if still running
      PIDS=$(lsof -ti :$OPENCODE_SERVER_PORT 2>/dev/null || true)
      if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
      fi
      echo "  ✓ Server stopped"
    fi
  fi
else
  warn "No opencode server running on port $OPENCODE_SERVER_PORT"
fi
echo ""

# --- Step 2: Remove opencode-mcp directory ---
echo "Step 2: Remove opencode-mcp repository"
remove_path "$OPENCODE_MCP_DIR" "opencode-mcp directory"
echo ""

# --- Step 3: Remove MCP config ---
echo "Step 3: Remove MCP configuration"
remove_path "$MCP_CONFIG_FILE" "mcp_config.json"
echo ""

# --- Step 4: Remove .gemini/antigravity-ide directory (if empty) ---
echo "Step 4: Clean up .gemini/antigravity-ide directory"
if [ -d "$GEMINI_ANTIGRAVITY_DIR" ]; then
  if $DRY_RUN; then
    # Check if it would be empty after removals
    if [ -d "$GEMINI_ANTIGRAVITY_DIR" ]; then
      remaining=$(find "$GEMINI_ANTIGRAVITY_DIR" -type f 2>/dev/null | wc -l)
      if [ "$remaining" -eq 0 ]; then
        log "[dry-run] Would remove empty directory: $GEMINI_ANTIGRAVITY_DIR"
        removed_count=$((removed_count + 1))
      else
        warn "Directory still has $remaining file(s), skipping removal"
        skipped_count=$((skipped_count + 1))
      fi
    fi
  else
    # Only remove if directory is empty after config removal
    if [ -d "$GEMINI_ANTIGRAVITY_DIR" ]; then
      remaining=$(find "$GEMINI_ANTIGRAVITY_DIR" -type f 2>/dev/null | wc -l)
      if [ "$remaining" -eq 0 ]; then
        log "Removing empty directory: $GEMINI_ANTIGRAVITY_DIR"
        rmdir "$GEMINI_ANTIGRAVITY_DIR"
        echo "  ✓ Removed"
        removed_count=$((removed_count + 1))
      else
        warn "Directory still has $remaining file(s), skipping removal"
        skipped_count=$((skipped_count + 1))
      fi
    fi
  fi
else
  warn "antigravity-ide directory not found, skipping"
  skipped_count=$((skipped_count + 1))
fi
echo ""

# --- Summary ---
echo "========================================"
echo "  Summary"
echo "========================================"
if $DRY_RUN; then
  echo "  Items that would be removed: $removed_count"
  echo "  Items skipped: $skipped_count"
  echo ""
  echo "  To actually remove, run without --dry-run"
else
  echo "  Items removed: $removed_count"
  echo "  Items skipped: $skipped_count"
  echo ""
  if [ $removed_count -gt 0 ]; then
    echo "  Uninstall complete!"
  else
    echo "  Nothing to remove (already clean)"
  fi
fi
echo ""
