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

# The hooks config to merge
HOOKS_JSON='{
  "Stop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "[ -z \"$CLAUDE_NONINTERACTIVE\" ] && setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-stop-hook.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ],
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-dismiss.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-dismiss.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ],
  "Notification": [
    {
      "matcher": "elicitation_dialog",
      "hooks": [
        {
          "type": "command",
          "command": "[ -z \"$CLAUDE_NONINTERACTIVE\" ] && setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-stop-hook.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ],
  "PermissionRequest": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "[ -z \"$CLAUDE_NONINTERACTIVE\" ] && setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-stop-hook.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "AskUserQuestion",
      "hooks": [
        {
          "type": "command",
          "command": "setsid wscript.exe '\''C:\\Temp\\claude-launcher.vbs'\'' '\''C:\\Temp\\claude-dismiss.ps1'\'' \"${CLAUDE_SESSION:-Claude}\" </dev/null >/dev/null 2>&1 &"
        }
      ]
    }
  ]
}'

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ -f "$SETTINGS_FILE" ]; then
    # Merge: overwrite only the "hooks" key, keep everything else
    EXISTING=$(cat "$SETTINGS_FILE")
    MERGED=$(echo "$EXISTING" | jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks')
    echo "$MERGED" | jq . > "$SETTINGS_FILE"
    echo "  Merged hooks into existing settings.json."
else
    # Create new settings.json with just hooks
    echo '{}' | jq --argjson hooks "$HOOKS_JSON" '{hooks: $hooks}' > "$SETTINGS_FILE"
    echo "  Created new settings.json with hooks."
fi

echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Windows scripts:  $WIN_TARGET/claude-*.ps1, claude-launcher.vbs"
echo "Hooks config:     $SETTINGS_FILE"
echo
echo "Start a new Claude Code session to test the notifications."
