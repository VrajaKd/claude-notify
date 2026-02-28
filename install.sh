#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_TARGET="/mnt/c/Temp"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Claude Code Notification Installer ==="
echo

# --- Check prerequisites ---
if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install with: sudo apt install jq"
    exit 1
fi

if [ ! -d /mnt/c ]; then
    echo -e "${RED}Error: /mnt/c not found. This script must run in WSL2.${NC}"
    exit 1
fi

# --- Step 1: Copy Windows scripts ---
echo -e "${YELLOW}[1/2] Copying Windows scripts to $WIN_TARGET ...${NC}"
mkdir -p "$WIN_TARGET"
cp "$SCRIPT_DIR/windows/claude-launcher.vbs"   "$WIN_TARGET/"
cp "$SCRIPT_DIR/windows/claude-stop-hook.ps1"  "$WIN_TARGET/"
cp "$SCRIPT_DIR/windows/claude-dismiss.ps1"    "$WIN_TARGET/"
cp "$SCRIPT_DIR/windows/claude-notify.ps1"     "$WIN_TARGET/"
echo "  Copied 4 files."

# --- Step 2: Merge hooks into settings.json ---
echo -e "${YELLOW}[2/2] Configuring Claude Code hooks ...${NC}"

HOOKS_FILE="$SCRIPT_DIR/hooks.json"

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ -f "$SETTINGS_FILE" ]; then
    # Merge: overwrite only the "hooks" key, keep everything else
    jq --slurpfile hooks "$HOOKS_FILE" '.hooks = $hooks[0]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "  Merged hooks into existing settings.json."
else
    # Create new settings.json with just hooks
    jq -n --slurpfile hooks "$HOOKS_FILE" '{hooks: $hooks[0]}' > "$SETTINGS_FILE"
    echo "  Created new settings.json with hooks."
fi

echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Windows scripts:  $WIN_TARGET/claude-*.ps1, claude-launcher.vbs"
echo "Hooks config:     $SETTINGS_FILE"
echo
echo "Start a new Claude Code session to test the notifications."
