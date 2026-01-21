# Module: Backup

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Git-based backup and sync for the zsh config repo.

## Environment
- `ZSHRC_CONFIG_DIR` (default `~/.config/zsh`)
- `ZSHRC_MAIN_REPO` (informational)
- `ZSHRC_BACKUP_REPO` (informational)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `backup` | Commit + push config | `git` | Repo initialized, remotes set |
| `pushmain` | Shortcut for `backup` | `backup` | Same as `backup` |
| `repo_sync` | Pull/rebase + push | `git` | Clean repo, remote reachable |
| `repo_status` | Print repo status | `git` | Repo initialized |

## Notes
- Pushes `origin main` and `backup main` if `backup` remote exists.
- Aliases: `zshbackup`, `zshsync`, `zshstatus`.
