# Module: Settings

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Centralized config loader for `vars.env`, `aliases.zsh`, and `paths.env`.

## Environment
- `ZSH_SETTINGS_DIR` (default `~/.config/zsh`)
- `ZSH_VARS_FILE`, `ZSH_ALIASES_FILE`, `ZSH_PATHS_FILE`

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `settings_init` | Create settings files | `cat` | Config dir writable |
| `settings_edit_vars` | Edit vars.env | `$EDITOR` | Editor installed |
| `settings_edit_aliases` | Edit aliases.zsh | `$EDITOR` | Editor installed |
| `settings_edit_paths` | Edit paths.env | `$EDITOR` | Editor installed |
| `settings_status` | Show settings file locations | None | None |

## Notes
- Load order: `vars.env` → `aliases.zsh` → `paths.env`.
