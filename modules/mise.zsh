#!/usr/bin/env zsh
# Opt-in shell integration. Explicit `mise exec` / `mise run` need no hooks.
_zsh_mise_init() {
    [[ -o interactive && "${ZSH_MISE_ACTIVATE:-0}" == 1 ]] || return 0
    [[ -z "${ZSH_TEST_MODE:-}" ]] || return 0
    if ! command -v mise >/dev/null 2>&1; then
        print -u2 -- "mise: ZSH_MISE_ACTIVATE=1 but mise is not installed"
        return 1
    fi
    # Never silently carry a personal virtualenv into a project shell.
    if [[ -n "${PYENV_VIRTUAL_ENV:-}" || ( -n "${VIRTUAL_ENV:-}" && -z "${__MISE_DIFF:-}" ) ]]; then
        print -u2 -- "mise: deactivate the current virtualenv before starting a mise shell"
        return 1
    fi
    # Re-sourcing zshrc must not register duplicate hooks.
    (( ${+functions[_mise_hook]} )) && return 0
    local activation
    activation="$(mise activate zsh)" || return $?
    eval "$activation"
}

_zsh_mise_status() {
    if (( ${+functions[_mise_hook]} )); then
        print -- "shell hooks active"
    elif ! command -v mise >/dev/null 2>&1; then
        print -- "CLI not installed"
    else
        print -- "shell hooks inactive"
    fi
}

_zsh_mise_load() {
    local result=0
    _zsh_mise_init || result=$?
    if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
        if (( result == 0 )); then
            print -- "✅ mise loaded ($(_zsh_mise_status))"
        else
            print -u2 -- "⚠️ mise loaded ($(_zsh_mise_status); activation failed)"
        fi
    fi
    return "$result"
}
_zsh_mise_load
