# Module: Agents

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Codex session shortcuts and CRUD for saved session IDs.

## Environment
- `CODEX_SESSIONS_FILE` (default `~/.config/zsh/codex-sessions.env`)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `codex_session` | Print `codex resume` for saved session | `fzf` (optional) | Sessions file exists |
| `codex_session_list` | List saved sessions | `awk` | None |
| `codex_session_add` | Add session entry | `awk`, `mktemp` | `name=id|desc` |
| `codex_session_update` | Update entry | `awk`, `mktemp` | Existing key |
| `codex_session_remove` | Remove entry | `awk`, `mktemp` | Existing key |
| `codex_session_edit` | Edit sessions file | `$EDITOR` | File writable |

## Notes
- Format: `name=id|description`
- If `fzf` is installed, `codex_session` uses it for selection.
