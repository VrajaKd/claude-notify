# claude-notify

Windows popup notifications for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) running in WSL2.

Claude Code is a CLI tool — when it finishes thinking or needs your input, there's no visual cue if you've switched to another window. This project adds native Windows popup notifications with a sound alert so you never miss when Claude is waiting for you.

## What you get

- A small popup in the top-right corner of your screen when Claude stops and needs attention
- A sound alert (Windows Exclamation) so you notice even if you're looking away
- Automatic popup dismissal when you submit your next prompt
- Support for multiple concurrent Claude sessions (popups stack vertically)
- Click anywhere on the popup to dismiss it

## Prerequisites

- **WSL2** with access to `/mnt/c/`
- **jq** — `sudo apt install jq`
- **Claude Code** — installed and working in WSL2

## Installation

```bash
git clone https://github.com/VrajaKd/claude-notify.git
cd claude-notify
./install.sh
```

This does two things:
1. Copies the Windows-side scripts to `C:\Temp\`
2. Merges notification hooks into `~/.claude/settings.json` (preserves your existing settings)

Start a new Claude Code session to test — you should see a popup and hear a sound when Claude finishes its response.

## Uninstallation

```bash
./uninstall.sh
```

Removes the Windows scripts and the `hooks` key from `settings.json`.

## How it works

Claude Code supports [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — shell commands that run on specific events. This project registers hooks for:

| Event | Action |
|---|---|
| `Stop` | Show popup + play sound (Claude finished generating) |
| `PermissionRequest` | Show popup + play sound (Claude needs approval) |
| `Notification` (elicitation_dialog) | Show popup + play sound |
| `UserPromptSubmit` | Dismiss popup (you're back) |
| `SessionEnd` | Dismiss popup (session closed) |
| `PostToolUse` (AskUserQuestion) | Dismiss popup |

The notification flow: WSL hook → `wscript.exe` (silent launcher) → PowerShell → WinForms popup window.

## File structure

```
claude-notify/
├── install.sh              # Copies scripts + merges hooks config
├── uninstall.sh            # Removes scripts + hooks config
├── hooks.json              # Claude Code hooks configuration
└── windows/
    ├── claude-launcher.vbs     # Silent VBS launcher (avoids console flash)
    ├── claude-stop-hook.ps1    # Plays sound + triggers popup
    ├── claude-notify.ps1       # WinForms popup window with shadow/stacking
    └── claude-dismiss.ps1      # Finds and closes popup by session name
```

## Customization

**Change the sound** — edit `windows/claude-stop-hook.ps1`, replace the `.wav` path:
```powershell
(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Exclamation.wav').PlaySync()
```

**Change popup appearance** — edit `windows/claude-notify.ps1` (font, colors, size, position are all in the WinForms setup).

**Change script location** — if you don't want to use `C:\Temp\`, update the paths in `hooks.json` and the cross-references in the PowerShell scripts.

After any changes, re-run `./install.sh` to apply.

## License

MIT
