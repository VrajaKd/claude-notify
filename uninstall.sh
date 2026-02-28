#!/usr/bin/env bash
set -euo pipefail

WIN_TARGET="/mnt/c/Temp"
SETTINGS_FILE="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Claude Code Notification Uninstaller ==="
echo

# --- Step 1: Remove Windows scripts ---
echo -e "${YELLOW}[1/2] Removing Windows scripts ...${NC}"
removed=0
for f in claude-launcher.vbs claude-stop-hook.ps1 claude-dismiss.ps1 claude-notify.ps1; do
    if [ -f "$WIN_TARGET/$f" ]; then
        rm "$WIN_TARGET/$f"
        ((removed++))
    fi
done
# Also clean up any leftover PID files
for f in "$WIN_TARGET"/claude-notify-*.pid; do
    [ -f "$f" ] && rm "$f"
done
echo "  Removed $removed files."

# --- Step 2: Remove hooks from settings.json ---
echo -e "${YELLOW}[2/2] Removing hooks from settings.json ...${NC}"
if [ -f "$SETTINGS_FILE" ]; then
    if command -v jq &>/dev/null; then
        UPDATED=$(jq 'del(.hooks)' "$SETTINGS_FILE")
        echo "$UPDATED" | jq . > "$SETTINGS_FILE"
        echo "  Removed hooks key from settings.json."
    else
        echo "  Warning: jq not found, cannot auto-remove hooks."
        echo "  Manually remove the \"hooks\" section from: $SETTINGS_FILE"
    fi
else
    echo "  No settings.json found, nothing to do."
fi

echo
echo -e "${GREEN}Uninstall complete!${NC}"
