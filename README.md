# Codex Window Keeper

Small Linux helper for keeping the Codex CLI 5-hour usage window started.

I run it on a headless Debian server. It checks the Codex rate-limit state every minute and, when the 5-hour window is not actually started, sends one minimal Codex request to start it.

Files:

- `codex-window-keeper` — the actual script
- `install.sh` — installs it to your user crontab
- `uninstall.sh` — removes it

No root access required.

## Requirements

- Linux
- `bash`
- `python3`
- `cron`
- Codex CLI installed and authenticated

## Install

```bash
chmod +x codex-window-keeper install.sh uninstall.sh
./install.sh
```

Check status:

```bash
~/.local/bin/codex-window-keeper --status
```

Safe test:

```bash
~/.local/bin/codex-window-keeper --dry-run
```

Uninstall:

```bash
./uninstall.sh
```
