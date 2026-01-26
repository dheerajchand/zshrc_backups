# Module: Secrets

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Secrets loading, 1Password integration, profiles, and rsync fallbacks.

## Environment
- `ZSH_SECRETS_MODE` (`file|op|both|off`)
- `ZSH_SECRETS_FILE`, `ZSH_SECRETS_MAP`
- `OP_ACCOUNT`, `OP_VAULT`
- `OP_ACCOUNTS_FILE`

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_secrets_warn` | Warning output | None | STDERR available |
| `_secrets_info` | Info output | None | Not in test mode |
| `_secrets_update_env_file` | Update key in secrets file | `mktemp` | File writable |
| `_secrets_export_kv` | Export key/value | shell `export` | Format `KEY=VAL` |
| `_op_account_alias` | Alias→UUID | `OP_ACCOUNTS_FILE` | File exists |
| `_op_account_alias_for_uuid` | UUID→Alias | `OP_ACCOUNTS_FILE` | File exists |
| `op_accounts_edit` | Edit alias file | `$EDITOR` | Editor installed |
| `_op_accounts_write_kv` | Write alias line | `mktemp` | File writable |
| `_op_account_uuid_configured` | UUID present on device | `python` | `op account list` JSON |
| `_op_account_shorthand_configured` | Shorthand present on device | `python` | `op account list` JSON |
| `op_accounts_set_alias` | Set alias entry | `_op_accounts_write_kv` | Valid alias |
| `op_accounts_seed` | Prompt to seed aliases | `op`, `python` | Interactive shell |
| `_secrets_safe_title` | Redact titles | None | Used by verify |
| `_secrets_truncate` | Truncate string | None | Max length int |
| `op_verify_accounts` | Verify accounts + items | `op`, `python` | Sessions active |
| `_secrets_local_path_default` | Local config path | None | `$HOME` available |
| `_secrets_remote_path_default` | Remote config path | None | Uses `~/.config/zsh` |
| `_secrets_rsync_parse_args` | Parse rsync args | None | Valid args |
| `secrets_rsync_to_host` | Push secrets to host | `rsync` | SSH access |
| `secrets_rsync_from_host` | Pull secrets from host | `rsync` | SSH access |
| `secrets_rsync_to_cyberpower` | Push to cyberpower | `rsync` | Host reachable |
| `secrets_rsync_from_cyberpower` | Pull from cyberpower | `rsync` | Host reachable |
| `secrets_rsync_verify` | Verify local/remote files | `ssh` | Host reachable |
| `secrets_load_file` | Load secrets.env | File IO | `ZSH_SECRETS_FILE` exists |
| `secrets_load_op` | Load from 1Password map | `op` | Logged in |
| `load_secrets` | Dispatch loader | `secrets_load_*` | Mode valid |
| `_secrets_check_profile` | Warn if no profile | None | Interactive shell |
| `_secrets_validate_profile` | Validate profile | None | Profile list configured |
| `_secrets_profile_list` | Profile list | `ZSH_PROFILE_*` | Configured |
| `_secrets_default_profiles` | Default profiles | None | Static list |
| `_op_latest_item_id_by_title` | Find newest item | `op`, `python`/`jq` | Logged in |
| `secrets_validate_setup` | Validate op setup | `op` | Non-blocking |
| `secrets_init_profile` | Interactive setup | `op` | Interactive shell |
| `secrets_status` | Print status | None | Files present |
| `op_set_default` | Set `OP_ACCOUNT/OP_VAULT` | None | Args valid |
| `op_list_accounts_vaults` | List accounts/vaults | `op`, `jq/python` | Logged in |
| `secrets_edit` | Edit secrets.env | `$EDITOR` | File writable |
| `secrets_init` | Create secrets.env | File IO | Example exists |
| `secrets_init_map` | Create secrets.1p | File IO | Example exists |
| `secrets_sync_to_1p` | Sync file to 1Password | `op` | Logged in |
| `secrets_pull_from_1p` | Pull file from 1Password | `op` | Logged in |
| `secrets_sync_codex_sessions_to_1p` | Sync codex sessions | `op` | Logged in |
| `secrets_pull_codex_sessions_from_1p` | Pull codex sessions | `op` | Logged in |
| `secrets_sync_all_to_1p` | Sync all secrets files | `op` | Logged in |
| `secrets_pull_all_from_1p` | Pull all secrets files | `op` | Logged in |
| `secrets_profile_switch` | Set profile + reload | `load_secrets` | Valid profile |
| `op_list_items` | List items in vault | `op` | Logged in |
| `op_signin_account` | Sign in by alias | `op` | Alias configured |
| `op_signin_all` | Sign in all aliases | `op` | Accounts configured |
| `op_login_headless` | Headless sign‑in flow | `op` | Interactive shell |
| `secrets_profiles` | List profiles + desc | None | Profiles configured |
| `secrets_bootstrap_from_1p` | Pull all secrets files | `op` | Logged in |
| `op_signin_account_uuid` | Sign in with UUID | `op` | UUID configured |
| `op_set_default_alias` | Set default by alias | None | Alias configured |
| `machine_profile` | Resolve profile | `hostname` | Hostname available |

## Notes
- `op_login_headless` sets `OP_SESSION_<alias>` tokens.
- `secrets_rsync_*` is the supported fallback for headless servers without op GUI.
