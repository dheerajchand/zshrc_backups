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
: "${OP_VAULT:=}"
: "${OP_ACCOUNT:=}"

_secrets_warn() {
    echo "⚠️  $*" >&2
}

_secrets_info() {
    [[ -n "${ZSH_TEST_MODE:-}" ]] && return 0
    echo "🔐 $*"
}

_secrets_update_env_file() {
    local key="$1"
    local value="$2"
    local file="$ZSH_SECRETS_FILE"
    local tmp
    umask 077
    if [[ ! -f "$file" ]]; then
        if ! printf '%s=%s\n' "$key" "$value" > "$file" 2>/dev/null; then
            _secrets_warn "Failed to create secrets file: $file"
            return 1
        fi
        chmod 600 "$file" 2>/dev/null || true
        return 0
    fi
    tmp="$(mktemp 2>/dev/null || mktemp -t zsh-secrets 2>/dev/null)"
    if [[ -z "$tmp" || ! -f "$tmp" ]]; then
        _secrets_warn "Failed to create temp file for secrets update"
        return 1
    fi
    if ! python - "$file" "$tmp" "$key" "$value" <<'PY'
import sys
src, dst, key, val = sys.argv[1:5]
found = False
with open(src, "r") as fh:
    lines = fh.read().splitlines()
out = []
for line in lines:
    if line.startswith(f"{key}="):
        out.append(f"{key}={val}")
        found = True
    else:
        out.append(line)
if not found:
    out.append(f"{key}={val}")
with open(dst, "w") as fh:
    fh.write("\n".join(out))
    fh.write("\n")
PY
    then
        _secrets_warn "Failed to update secrets file"
        rm -f "$tmp"
        return 1
    fi
    if ! mv "$tmp" "$file" 2>/dev/null; then
        _secrets_warn "Failed to update secrets file"
        rm -f "$tmp"
        return 1
    fi
    chmod 600 "$file" 2>/dev/null || true
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

_op_accounts_write_kv() {
    local alias_name="$1"
    local uuid="$2"
    local file="$OP_ACCOUNTS_FILE"
    [[ -z "$alias_name" || -z "$uuid" ]] && return 1
    umask 077
    [[ -f "$file" ]] || : > "$file"
    local tmp updated
    tmp="$(mktemp "${file}.XXXXXX")" || return 1
    updated=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "${alias_name}="* ]]; then
            echo "${alias_name}=${uuid}" >> "$tmp"
            updated=1
        else
            echo "$line" >> "$tmp"
        fi
    done < "$file"
    if [[ "$updated" -eq 0 ]]; then
        echo "${alias_name}=${uuid}" >> "$tmp"
    fi
    mv "$tmp" "$file"
}

op_accounts_set_alias() {
    local alias_name="${1:-}"
    local uuid="${2:-}"
    if [[ -z "$alias_name" || -z "$uuid" ]]; then
        echo "Usage: op_accounts_set_alias <alias> <account-uuid>" >&2
        return 1
    fi
    if [[ ! "$alias_name" =~ ^[A-Za-z0-9_]+$ ]]; then
        _secrets_warn "Alias must be alphanumeric/underscore: $alias_name"
        return 1
    fi
    _op_accounts_write_kv "$alias_name" "$uuid" || return 1
    _secrets_info "Set alias: $alias_name"
}

op_accounts_seed() {
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot seed aliases"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: eval \"\$(op signin)\")"
        return 1
    fi
    if [[ -z "${ZSH_TEST_MODE:-}" && ! -o interactive ]]; then
        _secrets_warn "Interactive shell required to seed aliases"
        return 1
    fi
    local json
    json="$(OP_CLI_NO_COLOR=1 op account list --format=json 2>/dev/null || true)"
    if [[ -z "$json" ]]; then
        _secrets_warn "No accounts returned by op account list"
        return 1
    fi
    local line account_uuid email url alias_name
    while IFS=$'\t' read -r account_uuid email url; do
        [[ -z "$account_uuid" ]] && continue
        alias_name="$(_op_account_alias_for_uuid "$account_uuid" 2>/dev/null || true)"
        if [[ -n "$alias_name" ]]; then
            continue
        fi
        read -r "alias_name?Alias for ${email:-unknown} @ ${url:-unknown} (${account_uuid}) [skip]: "
        [[ -z "$alias_name" ]] && continue
        if [[ ! "$alias_name" =~ ^[A-Za-z0-9_]+$ ]]; then
            _secrets_warn "Skipping invalid alias: $alias_name"
            continue
        fi
        _op_accounts_write_kv "$alias_name" "$account_uuid"
    done < <(printf '%s' "$json" | python -c "import json,sys; data=json.load(sys.stdin); [print(f\"{a.get('account_uuid','')}\\t{a.get('email','')}\\t{a.get('url','')}\") for a in data]")
    _secrets_info "Alias seeding complete"
}

_secrets_remote_path_default() {
    if [[ -n "${ZSH_CONFIG_DIR:-}" ]]; then
        echo "$ZSH_CONFIG_DIR"
    else
        echo "$HOME/.config/zsh"
    fi
}

_secrets_rsync_parse_args() {
    local user="" host="" path="" remote=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                user="$2"
                shift 2
                ;;
            --host)
                host="$2"
                shift 2
                ;;
            --path)
                path="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                return 2
                ;;
            *)
                if [[ -z "$remote" ]]; then
                    remote="$1"
                elif [[ -z "$path" ]]; then
                    path="$1"
                else
                    echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                    return 2
                fi
                shift
                ;;
        esac
    done
    if [[ -n "$user" || -n "$host" ]]; then
        [[ -z "$host" ]] && return 1
        if [[ -n "$user" ]]; then
            remote="${user}@${host}"
        else
            remote="$host"
        fi
    fi
    if [[ -z "$path" ]]; then
        path="$(_secrets_remote_path_default)"
    fi
    echo "$remote" "$path"
    return 0
}

secrets_rsync_to_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args secrets_rsync_to_host "$@")" || {
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local src_base
    src_base="$(_secrets_remote_path_default)"
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        "$src_base/op-accounts.env" \
        "$src_base/secrets.env" \
        "$src_base/secrets.1p" \
        "${remote}:${remote_path}/"
}

secrets_rsync_from_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args secrets_rsync_from_host "$@")" || {
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local dest_base
    dest_base="$(_secrets_remote_path_default)"
    umask 077
    mkdir -p "$dest_base"
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        "${remote}:${remote_path}/op-accounts.env" \
        "${remote}:${remote_path}/secrets.env" \
        "${remote}:${remote_path}/secrets.1p" \
        "$dest_base/"
}

secrets_rsync_to_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_to_host --user "$user" --host "cyberpower"
}

secrets_rsync_from_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_from_host --user "$user" --host "cyberpower"
}

secrets_load_file() {
    [[ -f "$ZSH_SECRETS_FILE" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _secrets_export_kv "$line"
    done < "$ZSH_SECRETS_FILE"
    _secrets_info "Loaded secrets from file"
}

secrets_load_op() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to load"
        return 1
    fi
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
                ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
                --field="$field" --reveal 2>/dev/null || true)"
        else
            value="$(op item get "$service-$user" \
                ${account_arg:+--account="$account_arg"} \
                ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
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

_secrets_check_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        return 0
    fi
    if [[ -n "${_SECRETS_PROFILE_WARNED:-}" ]]; then
        return 0
    fi
    if [[ -n "${ZSH_TEST_MODE:-}" ]]; then
        return 0
    fi
    if [[ ! -o interactive ]]; then
        return 0
    fi
    _SECRETS_PROFILE_WARNED=1
    _secrets_warn "ZSH_ENV_PROFILE not set. Run: secrets_init_profile"
    _secrets_info "Available profiles: dev, staging, prod, laptop"
    _secrets_info "Run 'secrets_init_profile' for setup wizard"
}

_secrets_validate_profile() {
    local profile="${1:-}"
    local list
    list="$(_secrets_profile_list)"
    if [[ " $list " == *" $profile "* ]]; then
        return 0
    fi
    _secrets_warn "Invalid profile: $profile (expected one of: $(_secrets_default_profiles))"
    return 1
}

_secrets_profile_list() {
    if typeset -p ZSH_PROFILE_ORDER >/dev/null 2>&1; then
        local -a ordered
        ordered=("${ZSH_PROFILE_ORDER[@]}")
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            local -a filtered
            local name
            for name in "${ordered[@]}"; do
                [[ -n "${ZSH_PROFILE_CONFIGS[$name]-}" ]] && filtered+=("$name")
            done
            [[ "${#filtered[@]}" -gt 0 ]] && echo "${filtered[*]}" && return 0
        fi
        echo "${ordered[*]}"
        return 0
    fi
    if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
        local -a keys
        keys=("${(@k)ZSH_PROFILE_CONFIGS}")
        echo "${keys[*]}"
        return 0
    fi
    if [[ -n "${ZSH_PROFILE_LIST:-}" ]]; then
        echo "$ZSH_PROFILE_LIST"
        return 0
    fi
    _secrets_default_profiles
}

_secrets_default_profiles() {
    echo "dev staging prod laptop cyberpower"
}

_op_latest_item_id_by_title() {
    local title="$1"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    local items_json
    items_json="$(OP_CLI_NO_COLOR=1 op item list \
        ${account_arg:+--account="$account_arg"} \
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
        --format=json 2>/dev/null || true)"
    if [[ -n "$items_json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            local id
            id="$(echo "$items_json" | jq -r --arg t "$title" '
                [ .[] | select(.title == $t) ] | sort_by(.updatedAt // .updated_at // .createdAt // .created_at) | last | .id // empty
            ' 2>/dev/null || true)"
            [[ -n "$id" ]] && { echo "$id"; return 0; }
        fi
        python - <<'PY' "$items_json" "$title" 2>/dev/null && return 0
import json,sys
data=json.loads(sys.argv[1])
title=sys.argv[2]
matches=[i for i in data if i.get("title")==title]
def ts(i):
    return i.get("updatedAt") or i.get("updated_at") or i.get("createdAt") or i.get("created_at") or ""
matches.sort(key=ts)
if matches:
    print(matches[-1].get("id",""))
PY
    fi

    local line id
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == ID* ]] && continue
        if echo "$line" | awk '{print $2}' | grep -qx "$title"; then
            id="$(echo "$line" | awk '{print $1}')"
        fi
    done < <(OP_CLI_NO_COLOR=1 op item list \
        ${account_arg:+--account="$account_arg"} \
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} 2>/dev/null || true)
    [[ -n "$id" ]] && { echo "$id"; return 0; }
    return 1
}

secrets_validate_setup() {
    local errors=0
    if [[ "$ZSH_SECRETS_MODE" == "op" || "$ZSH_SECRETS_MODE" == "both" ]]; then
        if ! command -v op >/dev/null 2>&1; then
            _secrets_warn "op CLI not found. Install: brew install --cask 1password-cli"
            ((errors++))
        elif ! op account list >/dev/null 2>&1; then
            _secrets_warn "1Password not authenticated. Run: op signin"
            ((errors++))
        fi
        if [[ ! -f "$ZSH_SECRETS_MAP" ]]; then
            _secrets_warn "1Password mapping file not found: $ZSH_SECRETS_MAP"
            _secrets_info "Create from example: cp $ZSH_SECRETS_MAP.example $ZSH_SECRETS_MAP"
            ((errors++))
        fi
    fi
    if [[ "$errors" -eq 0 ]]; then
        _secrets_info "Secrets setup looks good"
    fi
    return "$errors"
}

secrets_init_profile() {
    if [[ -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file already exists: $ZSH_SECRETS_FILE"
        return 1
    fi
    echo "🔐 ZSH Secrets Profile Setup"
    echo "============================"
    echo ""
    echo "Select environment profile:"
    echo "  1) dev      - Development environment"
    echo "  2) staging  - Staging environment"
    echo "  3) prod     - Production environment"
    echo "  4) laptop   - Personal laptop"
    echo ""
    local choice profile
    read -r "choice?Profile [1-4]: "
    case "$choice" in
        1) profile="dev" ;;
        2) profile="staging" ;;
        3) profile="prod" ;;
        4) profile="laptop" ;;
        *) _secrets_warn "Invalid choice"; return 1 ;;
    esac

    local mode="file"
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
        local use_op
        read -r "use_op?Use 1Password for secrets? [y/N]: "
        if [[ "$use_op" == [Yy]* ]]; then
            mode="both"
        fi
    else
        if command -v op >/dev/null 2>&1; then
            _secrets_warn "1Password not authenticated. Using file-only mode."
        else
            _secrets_warn "1Password CLI not installed. Using file-only mode."
        fi
    fi

    umask 077
    cat > "$ZSH_SECRETS_FILE" <<EOF
# ZSH Environment Profile
ZSH_ENV_PROFILE=$profile

# Secrets Mode: file, op, both, off
ZSH_SECRETS_MODE=$mode

# 1Password Configuration (optional)
# OP_ACCOUNT=your-account-alias
# OP_VAULT=Private
EOF
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "Failed to create secrets file"
        return 1
    fi
    chmod 600 "$ZSH_SECRETS_FILE" 2>/dev/null || true
    local perms
    perms="$(stat -f "%OLp" "$ZSH_SECRETS_FILE" 2>/dev/null || stat -c "%a" "$ZSH_SECRETS_FILE" 2>/dev/null || true)"
    if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
        _secrets_warn "Secrets file has insecure permissions: $perms"
    fi

    if [[ "$mode" == "op" || "$mode" == "both" ]]; then
        if [[ ! -f "$ZSH_SECRETS_MAP" && -f "$ZSH_SECRETS_MAP.example" ]]; then
            cp "$ZSH_SECRETS_MAP.example" "$ZSH_SECRETS_MAP"
            _secrets_info "Created $ZSH_SECRETS_MAP from example"
        fi
    fi

    export ZSH_ENV_PROFILE="$profile"
    export ZSH_SECRETS_MODE="$mode"
    load_secrets
    _secrets_info "Profile setup complete: $profile"
}

secrets_status() {
    echo "🔐 Secrets"
    echo "=========="
    echo "Mode: $ZSH_SECRETS_MODE"
    echo "File: $ZSH_SECRETS_FILE"
    echo "1Password map: $ZSH_SECRETS_MAP"
    echo "1Password account: ${OP_ACCOUNT:-default}"
    echo "1Password vault: ${OP_VAULT:-default}"
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
    if [[ -n "$vault" && -z "$account" ]]; then
        _secrets_warn "Vault specified without account; refusing to set vault"
        return 1
    fi
    if [[ -n "$account" ]]; then
        local resolved
        resolved="$(_op_account_alias "$account" 2>/dev/null || true)"
        export OP_ACCOUNT="${resolved:-$account}"
        if [[ -z "$vault" ]]; then
            unset OP_VAULT
        fi
    fi
    if [[ -n "$vault" ]]; then
        export OP_VAULT="$vault"
    fi
    _secrets_info "1Password defaults: account=${OP_ACCOUNT:-default} vault=${OP_VAULT:-default}"
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
    else
        local perms=""
        perms="$(stat -f "%OLp" "$ZSH_SECRETS_FILE" 2>/dev/null || stat -c "%a" "$ZSH_SECRETS_FILE" 2>/dev/null || true)"
        if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
            _secrets_warn "secrets file has insecure permissions ($perms). Fixing..."
            chmod 600 "$ZSH_SECRETS_FILE" 2>/dev/null || true
        fi
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

secrets_init_map() {
    local src="$ZSH_SECRETS_MAP.example"
    if [[ -f "$ZSH_SECRETS_MAP" ]]; then
        _secrets_warn "secrets map already exists: $ZSH_SECRETS_MAP"
        return 1
    fi
    if [[ -f "$src" ]]; then
        umask 077
        cp "$src" "$ZSH_SECRETS_MAP"
        _secrets_info "Created secrets map from example"
        return 0
    fi
    umask 077
    touch "$ZSH_SECRETS_MAP"
    _secrets_info "Created empty secrets map"
}

secrets_sync_to_1p() {
    local title="${1:-zsh-secrets}"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to sync"
        return 1
    fi
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
    local err_file
    err_file="$(mktemp)"
    if op item create \
        --category="Secure Note" \
        --title="$title" \
        ${account_arg:+--account="$account_arg"} \
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
        "secrets_file[text]=$(cat "$ZSH_SECRETS_FILE")" \
        "notesPlain=$(cat "$ZSH_SECRETS_FILE")" >/dev/null 2>"$err_file"; then
        rm -f "$err_file"
        _secrets_info "Synced secrets file to 1Password item: $title"
        return 0
    fi
    _secrets_warn "Failed to sync secrets file to 1Password"
    if [[ -s "$err_file" ]]; then
        sed -n '1,3p' "$err_file" >&2
    fi
    rm -f "$err_file"
    return 1
}

secrets_pull_from_1p() {
    local title="${1:-zsh-secrets}"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to pull"
        return 1
    fi
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot pull secrets from 1Password"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    local item_id
    item_id="$(_op_latest_item_id_by_title "$title" "$account_arg" "$vault_arg")"
    if [[ -z "$item_id" ]]; then
        _secrets_warn "Item not found: $title"
        return 1
    fi
    local value
    value="$(op item get "$item_id" \
        ${account_arg:+--account="$account_arg"} \
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
        --field="secrets_file" --reveal 2>/dev/null || true)"
    if [[ -z "$value" ]]; then
        local item_json
        item_json="$(op item get "$item_id" \
            ${account_arg:+--account="$account_arg"} \
            ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
            --format=json 2>/dev/null || true)"
        if [[ -n "$item_json" ]]; then
            if command -v jq >/dev/null 2>&1; then
                value="$(echo "$item_json" | jq -r '
                    (.fields[]? | select((.id=="secrets_file") or (.label=="secrets_file") or (.title=="secrets_file") or (.name=="secrets_file")) | .value) // .notesPlain // empty
                ')"
            else
                value="$(python - <<'PY' "$item_json"
import json,sys
data=json.loads(sys.argv[1])
value=""
for field in data.get("fields", []) or []:
    if field.get("id") == "secrets_file" or field.get("label") == "secrets_file" or field.get("title") == "secrets_file" or field.get("name") == "secrets_file":
        value = field.get("value","")
        break
if not value:
    value = data.get("notesPlain","") or ""
print(value)
PY
)"
            fi
        fi
    fi
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
    if ! _secrets_validate_profile "$profile"; then
        echo "Available profiles: $(_secrets_profile_list)" >&2
        return 1
    fi
    _secrets_update_env_file "ZSH_ENV_PROFILE" "$profile"
    export ZSH_ENV_PROFILE="$profile"
    if [[ -n "$account" ]]; then
        if ! op_set_default "$account" "$vault"; then
            return 1
        fi
    elif [[ -n "$vault" ]]; then
        _secrets_warn "Vault specified without account; clearing vault"
        OP_VAULT=""
        unset OP_VAULT
    fi
    load_secrets
    _secrets_info "Switched profile to $profile"
}

op_list_items() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local filter="${3:-}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to list items"
        return 1
    fi
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
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
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

op_signin_account() {
    local account_alias="${1:-}"
    if [[ -z "$account_alias" ]]; then
        echo "Usage: op_signin_account <account-alias>" >&2
        return 1
    fi
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sign in"
        return 1
    fi
    local resolved
    resolved="$(_op_account_alias "$account_alias" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
        _secrets_warn "Account alias not found: $account_alias"
        _secrets_info "Edit: op_accounts_edit"
        return 1
    fi
    eval "$(op signin --account "$resolved")"
}

op_signin_all() {
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sign in"
        return 1
    fi
    if [[ ! -f "$OP_ACCOUNTS_FILE" ]]; then
        _secrets_warn "No account aliases file: $OP_ACCOUNTS_FILE"
        _secrets_info "Create: op_accounts_edit"
        return 1
    fi
    local line alias_name
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" == *"="* ]]; then
            alias_name="${line%%=*}"
            alias_name="${alias_name## }"; alias_name="${alias_name%% }"
            [[ -z "$alias_name" ]] && continue
            echo "🔐 Signing in: $alias_name"
            op_signin_account "$alias_name" || return 1
        fi
    done < "$OP_ACCOUNTS_FILE"
}

secrets_profiles() {
    local list
    local -a profiles
    list="$(_secrets_profile_list)"
    if [[ -z "$list" ]]; then
        echo "No profiles configured." >&2
        return 1
    fi
    profiles=("${(@s: :)list}")
    local profile desc colors
    for profile in "${profiles[@]}"; do
        desc=""
        colors=""
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            desc="${ZSH_PROFILE_CONFIGS[$profile]-}"
        fi
        if typeset -p ZSH_PROFILE_COLORS >/dev/null 2>&1; then
            colors="${ZSH_PROFILE_COLORS[$profile]-}"
        fi
        if [[ -n "$colors" && -n "$desc" ]]; then
            echo "$profile - $desc (colors: $colors)"
        elif [[ -n "$desc" ]]; then
            echo "$profile - $desc"
        elif [[ -n "$colors" ]]; then
            echo "$profile (colors: $colors)"
        else
            echo "$profile"
        fi
    done
}

secrets_bootstrap_from_1p() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot bootstrap secrets"
        return 1
    fi
    if ! op account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: eval \"\$(op signin)\")"
        return 1
    fi
    if [[ -z "$account_arg" ]]; then
        local shorthand
        shorthand="$(op account list --format=json 2>/dev/null | \
            python - <<'PY'
import json,sys
data=json.load(sys.stdin)
print(data[0].get("shorthand","") if data else "")
PY
)"
        if [[ -n "$shorthand" ]]; then
            account_arg="$shorthand"
        fi
    fi
    if [[ -n "$account_arg" ]]; then
        op_set_default "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    fi
    local old_file
    old_file="$ZSH_SECRETS_FILE"

    ZSH_SECRETS_FILE="$OP_ACCOUNTS_FILE" \
        secrets_pull_from_1p "op-accounts-env" "$OP_ACCOUNT" "$OP_VAULT" || true
    if [[ -f "$OP_ACCOUNTS_FILE" ]]; then
        _secrets_info "Pulled op-accounts.env"
    else
        _secrets_warn "op-accounts.env not found in 1Password"
    fi

    ZSH_SECRETS_FILE="$old_file" \
        secrets_pull_from_1p "zsh-secrets-env" "$OP_ACCOUNT" "$OP_VAULT" || true

    ZSH_SECRETS_FILE="$ZSH_SECRETS_MAP" \
        secrets_pull_from_1p "zsh-secrets-map" "$OP_ACCOUNT" "$OP_VAULT" || true

    export ZSH_SECRETS_FILE="$old_file"
    load_secrets
    _secrets_info "Bootstrap complete"
}

op_signin_account_uuid() {
    local account_alias="${1:-}"
    if [[ -z "$account_alias" ]]; then
        echo "Usage: op_signin_account_uuid <account-alias>" >&2
        return 1
    fi
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sign in"
        return 1
    fi
    local resolved
    resolved="$(_op_account_alias "$account_alias" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
        _secrets_warn "Account alias not found: $account_alias"
        _secrets_info "Edit: op_accounts_edit"
        return 1
    fi
    eval "$(op signin --account "$resolved")"
}

op_set_default_alias() {
    local account_alias="${1:-}"
    local vault="${2:-}"
    if [[ -z "$account_alias" ]]; then
        echo "Usage: op_set_default_alias <account-alias> [vault]" >&2
        return 1
    fi
    local resolved
    resolved="$(_op_account_alias "$account_alias" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
        _secrets_warn "Account alias not found: $account_alias"
        _secrets_info "Edit: op_accounts_edit"
        return 1
    fi
    op_set_default "$resolved" "$vault"
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
    _secrets_check_profile
    [[ "${ZSH_SECRETS_VERBOSE:-}" == "1" ]] && echo "✅ secrets loaded"
fi

 
