#!/usr/bin/env zsh
# =================================================================
# SECRETS - Local + 1Password environment loader
# =================================================================

: "${ZSH_SECRETS_MODE:=file}" # file|op|both|off
: "${ZSH_SECRETS_FILE:=$HOME/.config/zsh/secrets.env}"
: "${ZSH_SECRETS_FILE_EXAMPLE:=$HOME/.config/zsh/secrets.env.example}"
: "${ZSH_SECRETS_MAP:=$HOME/.config/zsh/secrets.1p}"
: "${OP_ACCOUNTS_FILE:=$HOME/.config/zsh/op-accounts.env}"
: "${OP_ACCOUNTS_FILE_EXAMPLE:=$HOME/.config/zsh/op-accounts.env.example}"
: "${OP_VAULT:=Private}"
: "${OP_ACCOUNT:=}"

_secrets_warn() {
    echo "⚠️  $*" >&2
}

_secrets_info() {
    [[ -n "${ZSH_TEST_MODE:-}" ]] && return 0
    echo "🔐 $*"
}

_secrets_export_kv() {
    local line="$1"
    [[ -z "$line" ]] && return 0
    [[ "$line" == \#* ]] && return 0
    if [[ "$line" == export\ * ]]; then
        line="${line#export }"
    fi
    if [[ "$line" == *"="* ]]; then
        local key="${line%%=*}"
        local val="${line#*=}"
        key="${key## }"; key="${key%% }"
        export "$key=$val"
    fi
}

_op_account_alias() {
    local alias_name="$1"
    [[ -f "$OP_ACCOUNTS_FILE" ]] || return 1
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            val="${line#*=}"
            key="${key## }"; key="${key%% }"
            if [[ "$key" == "$alias_name" ]]; then
                echo "$val"
                return 0
            fi
        fi
    done < "$OP_ACCOUNTS_FILE"
    return 1
}

_op_account_alias_for_uuid() {
    local uuid="$1"
    [[ -f "$OP_ACCOUNTS_FILE" ]] || return 1
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            val="${line#*=}"
            key="${key## }"; key="${key%% }"
            if [[ "$val" == "$uuid" ]]; then
                echo "$key"
                return 0
            fi
        fi
    done < "$OP_ACCOUNTS_FILE"
    return 1
}

op_accounts_edit() {
    local editor="${EDITOR:-vi}"
    if [[ ! -f "$OP_ACCOUNTS_FILE" ]]; then
        umask 077
        if [[ -f "$OP_ACCOUNTS_FILE_EXAMPLE" ]]; then
            cp "$OP_ACCOUNTS_FILE_EXAMPLE" "$OP_ACCOUNTS_FILE"
        else
            touch "$OP_ACCOUNTS_FILE"
        fi
    fi
    "$editor" "$OP_ACCOUNTS_FILE"
}

secrets_load_file() {
    [[ -f "$ZSH_SECRETS_FILE" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _secrets_export_kv "$line"
    done < "$ZSH_SECRETS_FILE"
    _secrets_info "Loaded secrets from file"
}

secrets_load_op() {
    local account_arg="${1:-$OP_ACCOUNT}"
    local vault_arg="${2:-$OP_VAULT}"
    [[ -f "$ZSH_SECRETS_MAP" ]] || return 1
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot load 1Password secrets"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi

    local envvar service user field
    while read -r envvar service user field; do
        [[ -z "$envvar" ]] && continue
        [[ "$envvar" == \#* ]] && continue
        [[ -z "$service" || -z "$field" ]] && continue
        local value=""
        if [[ "$user" == "-" || -z "$user" ]]; then
            value="$(op item get "$service" \
                ${account_arg:+--account="$account_arg"} \
                ${vault_arg:+--vault="$vault_arg"} \
                --field="$field" --reveal 2>/dev/null || true)"
        else
            value="$(op item get "$service-$user" \
                ${account_arg:+--account="$account_arg"} \
                ${vault_arg:+--vault="$vault_arg"} \
                --field="$field" --reveal 2>/dev/null || true)"
        fi
        [[ -n "$value" ]] && export "$envvar=$value"
    done < "$ZSH_SECRETS_MAP"
    _secrets_info "Loaded secrets from 1Password map"
}

load_secrets() {
    case "$ZSH_SECRETS_MODE" in
        off) return 0 ;;
        file) secrets_load_file ;;
        op) secrets_load_op ;;
        both)
            secrets_load_file
            secrets_load_op
            ;;
        *)
            _secrets_warn "Unknown ZSH_SECRETS_MODE: $ZSH_SECRETS_MODE"
            return 1
            ;;
    esac
}

secrets_status() {
    echo "🔐 Secrets"
    echo "=========="
    echo "Mode: $ZSH_SECRETS_MODE"
    echo "File: $ZSH_SECRETS_FILE"
    echo "1Password map: $ZSH_SECRETS_MAP"
    echo "1Password account: ${OP_ACCOUNT:-default}"
    echo "1Password vault: $OP_VAULT"
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "1Password: Ready"
        else
            echo "1Password: Auth required (run: op signin)"
        fi
    else
        echo "1Password: Not installed"
    fi
}

op_set_default() {
    local account="${1:-}"
    local vault="${2:-}"
    if [[ -n "$account" ]]; then
        local resolved
        resolved="$(_op_account_alias "$account" 2>/dev/null || true)"
        export OP_ACCOUNT="${resolved:-$account}"
    fi
    if [[ -n "$vault" ]]; then
        export OP_VAULT="$vault"
    fi
    _secrets_info "1Password defaults: account=${OP_ACCOUNT:-default} vault=$OP_VAULT"
}

op_list_accounts_vaults() {
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot list accounts/vaults"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    local accounts_json
    accounts_json="$(op account list --format=json 2>/dev/null)"
    if [[ -z "$accounts_json" ]]; then
        _secrets_warn "No 1Password accounts found"
        return 1
    fi
    echo "🔐 1Password Accounts & Vaults"
    echo "=============================="
    local acct_list
    if command -v jq >/dev/null 2>&1; then
        acct_list="$(echo "$accounts_json" | jq -r '.[] | "\(.account_uuid)\t\(.email)\t\(.url)"')"
    else
        acct_list="$(python - <<'PY'
import json,sys
data=json.load(sys.stdin)
for item in data:
    print(f"{item.get('account_uuid','')}\t{item.get('email','')}\t{item.get('url','')}")
PY
)" <<<"$accounts_json"
    fi
    local line account_uuid email url alias
    while IFS=$'\t' read -r account_uuid email url; do
        [[ -z "$account_uuid" ]] && continue
        alias="$(_op_account_alias_for_uuid "$account_uuid" 2>/dev/null || true)"
        if [[ -n "$alias" ]]; then
            echo "Account: $alias ($account_uuid) @ $url"
        else
            echo "Account: $account_uuid @ $url"
        fi
        if command -v jq >/dev/null 2>&1; then
            local vaults
            vaults="$(op vault list --account="$account_uuid" --format=json 2>/dev/null | jq -r '.[]?.name' || true)"
            if [[ -z "$vaults" ]]; then
                echo "  - (none found or access denied)"
            else
                echo "$vaults" | awk '{print "  - " $0}'
            fi
        else
            local vaults
            vaults="$(op vault list --account="$account_uuid" --format=json 2>/dev/null | \
                python - <<'PY'
import json,sys
data=json.load(sys.stdin)
for item in data:
    name=item.get("name")
    if name:
        print(f"{name}")
PY
)"
            if [[ -z "$vaults" ]]; then
                echo "  - (none found or access denied)"
            else
                echo "$vaults" | awk '{print "  - " $0}'
            fi
        fi
    done <<<"$acct_list"
}

secrets_edit() {
    local editor="${EDITOR:-vi}"
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        umask 077
        touch "$ZSH_SECRETS_FILE"
    fi
    "$editor" "$ZSH_SECRETS_FILE"
}

secrets_init() {
    local src="$ZSH_SECRETS_FILE_EXAMPLE"
    if [[ -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file already exists: $ZSH_SECRETS_FILE"
        return 1
    fi
    if [[ -f "$src" ]]; then
        umask 077
        cp "$src" "$ZSH_SECRETS_FILE"
        _secrets_info "Created secrets file from example"
        return 0
    fi
    umask 077
    touch "$ZSH_SECRETS_FILE"
    _secrets_info "Created empty secrets file"
}

secrets_sync_to_1p() {
    local title="${1:-zsh-secrets}"
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sync secrets to 1Password"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file not found: $ZSH_SECRETS_FILE"
        return 1
    fi
    op item create \
        --category="Secure Note" \
        --title="$title" \
        --vault="$OP_VAULT" \
        "secrets_file[text]=$(cat "$ZSH_SECRETS_FILE")" >/dev/null 2>&1 && {
        _secrets_info "Synced secrets file to 1Password item: $title"
        return 0
    }
    _secrets_warn "Failed to sync secrets file to 1Password"
    return 1
}

secrets_pull_from_1p() {
    local title="${1:-zsh-secrets}"
    local account_arg="${2:-$OP_ACCOUNT}"
    local vault_arg="${3:-$OP_VAULT}"
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot pull secrets from 1Password"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    local value
    value="$(op item get "$title" \
        ${account_arg:+--account="$account_arg"} \
        ${vault_arg:+--vault="$vault_arg"} \
        --field="secrets_file" --reveal 2>/dev/null || true)"
    if [[ -z "$value" ]]; then
        _secrets_warn "No secrets_file field found for item: $title"
        return 1
    fi
    umask 077
    printf '%s\n' "$value" > "$ZSH_SECRETS_FILE"
    _secrets_info "Pulled secrets into $ZSH_SECRETS_FILE"
}

secrets_profile_switch() {
    local profile="${1-}"
    local account="${2:-${OP_ACCOUNT-}}"
    local vault="${3:-${OP_VAULT-}}"
    if [[ -z "$profile" ]]; then
        echo "Usage: secrets_profile_switch <profile> [account] [vault]" >&2
        return 1
    fi
    export ZSH_ENV_PROFILE="$profile"
    if [[ -n "$account" ]]; then
        op_set_default "$account" "$vault"
    fi
    load_secrets
    _secrets_info "Switched profile to $profile"
}

op_list_items() {
    local account_arg="${1:-$OP_ACCOUNT}"
    local vault_arg="${2:-$OP_VAULT}"
    local filter="${3:-}"
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot list items"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    local items_json
    items_json="$(op item list \
        ${account_arg:+--account="$account_arg"} \
        ${vault_arg:+--vault="$vault_arg"} \
        --format=json 2>/dev/null || true)"
    if [[ -z "$items_json" ]]; then
        _secrets_warn "No items found"
        return 1
    fi
    if command -v jq >/dev/null 2>&1; then
        local titles
        if [[ -n "$filter" ]]; then
            titles="$(echo "$items_json" | jq -r --arg f "$filter" '.[] | select(.title | test($f;"i")) | .title')"
        else
            titles="$(echo "$items_json" | jq -r '.[].title')"
        fi
        if [[ -z "$titles" ]]; then
            _secrets_warn "No items found"
            return 1
        fi
        echo "$titles"
    else
        local titles
        titles="$(python - <<'PY' "$filter"
import json,sys,re
flt=sys.argv[1] if len(sys.argv)>1 else ""
data=json.load(sys.stdin)
out=[]
for item in data:
    title=item.get("title","")
    if not title:
        continue
    if flt:
        if re.search(flt, title, re.I):
            out.append(title)
    else:
        out.append(title)
print("\n".join(out))
PY
)"
        if [[ -z "$titles" ]]; then
            _secrets_warn "No items found"
            return 1
        fi
        echo "$titles"
    fi
}

machine_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        echo "$ZSH_ENV_PROFILE"
        return 0
    fi
    if command -v hostname >/dev/null 2>&1; then
        hostname -s 2>/dev/null || hostname
        return 0
    fi
    echo "unknown-host"
}

# Auto-load secrets unless disabled or in test mode
if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    load_secrets
fi

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ secrets loaded"
fi
