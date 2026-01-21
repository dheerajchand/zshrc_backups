# Module: Screen

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
GNU screen helpers (pyenv bootstrap for screen shells).

## Environment
- None

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `screen_ensure_pyenv` | Ensure pyenv init lines in `~/.zshenv` and `~/.zshrc` | `grep`, `cat` | User can write to shell config files |

## Notes
- Adds a `# pyenv (screen)` marker to avoid duplicate inserts.
