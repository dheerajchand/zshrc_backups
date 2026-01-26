#!/usr/bin/env zsh
# =================================================================
# AGENTS - Codex session helpers
# =================================================================

: "${CODEX_SESSIONS_FILE:=$HOME/.config/zsh/codex-sessions.env}"

_codex_sessions_ensure_file() {
    local file="$CODEX_SESSIONS_FILE"
    if [[ ! -f "$file" ]]; then
        umask 077
        touch "$file" 2>/dev/null || return 1
    fi
    return 0
}

_codex_sessions_list_keys() {
    local file="$CODEX_SESSIONS_FILE"
    [[ -f "$file" ]] || return 0
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {print $1}
    ' "$file"
}

_codex_sessions_get() {
    local key="$1"
    local file="$CODEX_SESSIONS_FILE"
    [[ -f "$file" ]] || return 1
    awk -F'=' -v k="$key" '
        $1==k {print $2; found=1}
        END {exit found?0:1}
    ' "$file"
}

codex_session_add() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: codex_session_add <name> <id>|<description>" >&2
        echo "Example: codex_session_add zsh_work \"019b...|ZSH refactor work\"" >&2
        return 1
    fi
    _codex_sessions_ensure_file || { echo "Cannot write $CODEX_SESSIONS_FILE" >&2; return 1; }
    if _codex_sessions_get "$key" >/dev/null 2>&1; then
        echo "Key exists: $key (use codex_session_update)" >&2
        return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$CODEX_SESSIONS_FILE"
}

codex_session_update() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: codex_session_update <name> <id>|<description>" >&2
        return 1
    fi
    _codex_sessions_ensure_file || { echo "Cannot write $CODEX_SESSIONS_FILE" >&2; return 1; }
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" -v v="$value" '
        BEGIN {updated=0}
        $1==k {print k "=" v; updated=1; next}
        {print}
        END {if (!updated) exit 2}
    ' "$CODEX_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CODEX_SESSIONS_FILE"
}

codex_session_remove() {
    local key="$1"
    if [[ -z "$key" ]]; then
        echo "Usage: codex_session_remove <name>" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" '
        $1==k {removed=1; next}
        {print}
        END {if (!removed) exit 2}
    ' "$CODEX_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CODEX_SESSIONS_FILE"
}

codex_session_list() {
    _codex_sessions_ensure_file || return 1
    echo "Codex sessions: $CODEX_SESSIONS_FILE"
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {
            printf "%-20s | %s\n", $1, $2
        }
    ' "$CODEX_SESSIONS_FILE"
}

codex_session_edit() {
    _codex_sessions_ensure_file || return 1
    "${EDITOR:-vi}" "$CODEX_SESSIONS_FILE"
}

codex_session() {
    local key="$1"
    _codex_sessions_ensure_file || return 1
    if [[ -z "$key" ]]; then
        local choice=""
        if command -v fzf >/dev/null 2>&1; then
            choice="$(_codex_sessions_list_keys | fzf --prompt='codex session> ')"
        else
            local keys
            keys=($(_codex_sessions_list_keys))
            if [[ ${#keys[@]} -eq 0 ]]; then
                echo "No sessions saved." >&2
                return 1
            fi
            echo "Select session:"
            select key in "${keys[@]}"; do
                choice="$key"
                break
            done
        fi
        key="$choice"
    fi
    if [[ -z "$key" ]]; then
        return 1
    fi
    local entry
    entry="$(_codex_sessions_get "$key" 2>/dev/null || true)"
    if [[ -z "$entry" ]]; then
        echo "Key not found: $key" >&2
        return 1
    fi
    local id desc
    id="${entry%%|*}"
    desc="${entry#*|}"
    if [[ "$id" == "$desc" ]]; then
        desc=""
    fi
    local cmd="codex resume $id"
    if [[ -n "$desc" ]]; then
        echo "$cmd  # $desc"
    else
        echo "$cmd"
    fi
    local reply="y"
    if [[ -o interactive ]]; then
        read -r "reply?Execute command? [Y/n]: "
        reply="${reply:-y}"
    fi
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        eval "$cmd"
    fi
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ agents loaded"
fi
