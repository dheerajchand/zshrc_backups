# Module: Utils

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Core utility helpers and shared variables.

## Environment
- `JARS_DIR`: universal jar storage root (default `~/.jars`)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `is_online` | Check internet connectivity | `ping` | `google.com` reachable |
| `is_online_status` | Print online/offline | `is_online` | None |
| `command_exists` | Check command availability | `command -v` | None |
| `mkcd` | Create dir and `cd` | `mkdir`, `cd` | Path is valid |
| `extract` | Extract common archive types | `tar`, `unzip`, `7z`, etc. | Correct file extension |
| `download_jars` | Download Maven jars | `curl` or `wget` | Coordinates are `group:artifact:version` |
| `findtext` | Recursive text search | `grep` | None |
| `path_add` | Add to `PATH` | `PATH` mutation | Directory exists |
| `path_clean` | Deduplicate `PATH` | `PATH` mutation | Directories are readable |
| `zshconfig` | Open config dir in editor | `$EDITOR` | Editor installed |
| `zshreboot` | Restart shell | `exec zsh` | Zsh installed |

## Notes
- `download_jars` writes into `JARS_DIR` by default.
- `extract` is extension-based (no content detection).
