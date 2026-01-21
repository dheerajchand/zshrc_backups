# Module: Zshrc

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Core shell orchestration: module loading, help output, profile theme, and startup banner.

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `detect_ide` | Detect IDE/terminal environment | `TERM_PROGRAM`, process list | Runs in interactive shells |
| `load_module` | Source module by name | `modules/<name>.zsh` file exists | Modules live under `$ZSH_CONFIG_DIR/modules` |
| `help` | Command quick reference | Output formatting | Names match actual functions |
| `modules` | Show loaded modules | Module list in `zshrc` | Module names are stable |
| `_profile_palette` | Resolve profile colors | `ZSH_PROFILE_COLORS` | Profiles defined |
| `apply_profile_theme` | Set color vars | ANSI support | Intended for prompts/banners |
| `zsh_status_banner` | Startup banner | `python_status`, `spark_status`, `hadoop_status` | Modules loaded first |

## Notes
- Profile colors are driven by `ZSH_ENV_PROFILE` and `ZSH_PROFILE_COLORS`.
- Banner assumes Spark/Hadoop presence based on command availability.
