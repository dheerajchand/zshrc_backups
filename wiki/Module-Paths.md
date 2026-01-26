# Module: Paths

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
User-defined convenience paths and variables.

## Environment
- `ZSH_PATHS_FILE` (default `~/.config/zsh/paths.env`)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `paths_init` | Create `paths.env` | `cat` | Config dir writable |
| `paths_edit` | Edit `paths.env` | `$EDITOR` | Editor installed |
| `paths_list` | List exported variables | `rg`/`grep` | File exists |

## Notes
- Add `export NAME="/path"` lines to `paths.env` for custom shortcuts.
