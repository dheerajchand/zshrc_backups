#!/usr/bin/env zsh
# =================================================================
# SECRETS - Local + 1Password environment loader
# =================================================================

: "${ZSH_SECRETS_MODE:=file}" # file|op|both|off
: "${ZSH_SECRETS_FILE:=$HOME/.config/zsh/secrets.env}"
: "${ZSH_SECRETS_MAP:=$HOME/.config/zsh/secrets.1p}"
: "${OP_VAULT:=Private}"

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
    if [[ "$line" == *"="* ]]; then
        local key="${line%%=*}"
        local val="${line#*=}"
        key="${key## }"; key="${key%% }"
        export "$key=$val"
    fi
}

secrets_load_file() {
    [[ -f "$ZSH_SECRETS_FILE" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _secrets_export_kv "$line"
    done < "$ZSH_SECRETS_FILE"
    _secrets_info "Loaded secrets from file"
}

secrets_load_op() {
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
            value="$(op item get "$service" --field="$field" --reveal 2>/dev/null || true)"
        else
            value="$(op item get "$service-$user" --field="$field" --reveal 2>/dev/null || true)"
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
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "1Password: Ready (vault: $OP_VAULT)"
        else
            echo "1Password: Auth required (run: op signin)"
        fi
    else
        echo "1Password: Not installed"
    fi
}

secrets_edit() {
    local editor="${EDITOR:-vi}"
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        umask 077
        touch "$ZSH_SECRETS_FILE"
    fi
    "$editor" "$ZSH_SECRETS_FILE"
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
