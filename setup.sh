#!/bin/bash

# Setup script for Sisyphus Orchestrator workspace setup and verification.

set -e

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}======================================================${NC}"
echo -e "${BLUE}${BOLD}   Sisyphus Orchestrator Workspace Setup & Verify     ${NC}"
echo -e "${BLUE}${BOLD}======================================================${NC}"

# 1. Check Bun installation
echo -e "\n${BLUE}[1/4] Checking Bun installation...${NC}"
if command -v bun &> /dev/null; then
  BUN_VERSION=$(bun --version)
  echo -e "${GREEN}✓ Bun is installed (version $BUN_VERSION)${NC}"
else
  echo -e "${YELLOW}⚠ Bun is not installed or not in your PATH.${NC}"
  echo -e "You can install Bun by running: curl -fsSL https://bun.sh/install | bash"
fi

# 2. Check oh-my-openagent CLI
echo -e "\n${BLUE}[2/4] Checking oh-my-openagent CLI...${NC}"
CLI_PATH="$HOME/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js"
DIST_CLI_PATH="$HOME/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/dist/cli/index.js"

if [ -f "$CLI_PATH" ]; then
  echo -e "${GREEN}✓ Found oh-my-openagent CLI script at:${NC}"
  echo -e "  $CLI_PATH"
else
  echo -e "${RED}✗ Could not find oh-my-openagent CLI script.${NC}"
  echo -e "Expected path: $CLI_PATH"
  echo -e "Make sure you have installed/cached oh-my-openagent via opencode."
fi

# 3. Patch the casing/agent-name resolution bug
echo -e "\n${BLUE}[3/4] Checking casing/agent-name resolution bug...${NC}"
if [ -f "$DIST_CLI_PATH" ]; then
  # Check if already patched
  if grep -q "resolvedName: isKnownAgent ? displayName : trimmed" "$DIST_CLI_PATH"; then
    echo -e "${GREEN}✓ CLI is already patched (resolvedName is set to displayName).${NC}"
  else
    echo -e "${YELLOW}⚡ CLI is not patched yet (resolvedName is likely configKey). Patching now...${NC}"
    
    # Create a backup
    cp "$DIST_CLI_PATH" "${DIST_CLI_PATH}.bak"
    echo -e "  Created backup: ${DIST_CLI_PATH}.bak"
    
    # Run sed replacement
    bun -e '
      const fs = require("fs");
      const path = "'"$DIST_CLI_PATH"'";
      let content = fs.readFileSync(path, "utf8");
      const target = "resolvedName: isKnownAgent ? configKey : trimmed";
      const replacement = "resolvedName: isKnownAgent ? displayName : trimmed";
      if (content.includes(target)) {
        content = content.replace(target, replacement);
        fs.writeFileSync(path, content, "utf8");
        console.log("  Successfully patched index.js");
      } else {
        console.log("  Target pattern not found or already changed.");
      }
    '
    
    # Verification
    if grep -q "resolvedName: isKnownAgent ? displayName : trimmed" "$DIST_CLI_PATH"; then
      echo -e "${GREEN}✓ Casing bug patched successfully!${NC}"
    else
      echo -e "${RED}✗ Failed to patch the casing bug. Please check permissions or patch manually.${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠ Could not find $DIST_CLI_PATH to inspect/patch.${NC}"
fi

# 4. Check configuration
echo -e "\n${BLUE}[4/4] Checking oh-my-openagent configuration...${NC}"
CONFIG_PATH="$HOME/.config/opencode/oh-my-openagent.json"
if [ -f "$CONFIG_PATH" ]; then
  echo -e "${GREEN}✓ Configuration found at: $CONFIG_PATH${NC}"
  # Check if model is mapped to mimo-v2.5-free
  if grep -q "opencode/mimo-v2.5-free" "$CONFIG_PATH"; then
    echo -e "${GREEN}✓ Configuration is set to use the free model (opencode/mimo-v2.5-free).${NC}"
  else
    echo -e "${YELLOW}⚠ Configuration found, but does not seem to default to opencode/mimo-v2.5-free.${NC}"
    echo -e "Please review delegation-guide.md to configure the free model."
  fi
else
  echo -e "${YELLOW}⚠ Configuration not found at: $CONFIG_PATH${NC}"
  echo -e "You can create one with the settings shown in delegation-guide.md."
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${GREEN}${BOLD}Setup verification complete!${NC}"
echo -e "Please read ${BOLD}README.md${NC} and ${BOLD}delegation-guide.md${NC} for next steps."
echo -e "${BLUE}======================================================${NC}"
