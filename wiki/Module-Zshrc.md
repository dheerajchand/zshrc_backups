# Module: Zshrc

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Core shell orchestration: module loading, help output, profile theme, and startup banner.

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `detect_ide` | Detect IDE/terminal environment | `TERM_PROGRAM`, process list | Runs in interactive shells |
| `_zsh_startup_use_staggered` | Resolve startup mode (`auto/staggered/full`) | `ZSH_STARTUP_MODE`, `detect_ide` | Defaults to `auto` |
| `load_module` | Source a module and record its result | `modules/<name>.zsh` file exists | Honors `ZSH_DISABLE_<NAME>`; preserves the source return code |
| `_zsh_auto_recover_data_services` | Attempt Spark/Hadoop/Zeppelin restart on startup | `spark_start`, `start_hadoop`, `zeppelin_start` | Skips in IDE unless enabled |
| `help` | Command quick reference | Output formatting | Names match actual functions |
| `modules` | Show module load results | Registry maintained by `load_module` | Includes pending, disabled, missing, and failed modules |
| `_profile_palette` | Resolve profile colors | `ZSH_PROFILE_COLORS` | Profiles defined |
| `apply_profile_theme` | Set color vars | ANSI support | Intended for prompts/banners |
| `zsh_status_banner` | Startup banner | `python_status`, `spark_status`, `hadoop_status` | Modules loaded first |

## Notes
- Shared startup groups define the load plan and initial status inventory. `modules` loops over that inventory; adding a module to a startup group includes it automatically. Extra calls to `load_module` also register their module, even without description metadata.
- Status records the latest load attempt: `Pending` before a deferred callback runs, `Loading` during sourcing, `Loaded` after a zero return, `Disabled` when the opt-out flag skips sourcing, `File missing` when the file is absent, or `Load failed (exit N)` after a nonzero return. Retrying updates the same entry.
- These are shell-module results, not service health checks. A module can load successfully while its associated CLI or service is unavailable. Mise additionally reports its current shell-hook state.
- Re-sourcing `zshrc` rebuilds the inventory for the new startup pass. Disabling an already loaded module does not remove functions or hooks from the current process; use a new shell for a clean opt-out.
- Profile colors are driven by `ZSH_ENV_PROFILE` and `ZSH_PROFILE_COLORS`.
- Banner assumes Spark/Hadoop presence based on command availability.
- Startup behavior is controlled by `ZSH_STARTUP_MODE` (`auto`, `staggered`, `full`).
- Auto-recovery in IDE terminals is off by default (`ZSH_AUTO_RECOVER_IN_IDE=0`).
