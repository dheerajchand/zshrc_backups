# Module: Credentials

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Credential storage/retrieval across 1Password, Keychain, env, Vault, AWS.

## Environment
- `CRED_BACKENDS`, `CRED_STORE_BACKENDS`
- `OP_ACCOUNT`, `OP_VAULT`
- `AWS_PROFILE` (if used)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_cred_backends` | Backend list | None | `CRED_BACKENDS` set |
| `_cred_store_backends` | Store backends | None | `CRED_STORE_BACKENDS` set |
| `_cred_is_known_backend` | Validate backend | None | Known list |
| `_cred_warn_unknown_backend` | Warn on unknown | None | STDERR available |
| `_cred_get_op` | Get from 1Password | `op` | Logged in |
| `_cred_put_op` | Store to 1Password | `op` | Logged in |
| `_cred_status_op` | Status for 1Password | `op` | Logged in |
| `_cred_get_keychain` | Get from Keychain | `security` (macOS) | macOS only |
| `_cred_put_keychain` | Store to Keychain | `security` | macOS only |
| `_cred_status_keychain` | Keychain status | `security` | macOS only |
| `_cred_get_env` | Get from env | shell env | Key exists |
| `_cred_put_env` | Store in env | shell env | Current session |
| `_cred_status_env` | Env status | shell env | None |
| `_cred_get_vault` | Get from Vault | `vault` CLI | Vault reachable |
| `_cred_put_vault` | Store in Vault | `vault` CLI | Vault reachable |
| `_cred_status_vault` | Vault status | `vault` CLI | Vault reachable |
| `_cred_get_aws` | Get AWS secrets | `aws` CLI | AWS profile set |
| `_cred_put_aws` | Store AWS secrets | `aws` CLI | AWS profile set |
| `_cred_status_aws` | AWS status | `aws` CLI | AWS profile set |
| `get_credential` | Resolve credential | Backends | Backend configured |
| `store_credential` | Store credential | Backends | Backend configured |
| `credential_backend_status` | Backend status | Backends | None |
| `ga_store_service_account` | Store GA creds | File IO | JSON file |
| `ga_get_service_account` | Retrieve GA creds | File IO | Stored file exists |
| `ga_list_credentials` | List GA creds | File IO | Credentials dir |
| `test_credential_system` | End‑to‑end test | Backends | Tools installed |

## Notes
- macOS Keychain functions are no‑ops on Linux.
