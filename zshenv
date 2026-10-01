#!/usr/bin/env zsh
# Minimal environment shared by interactive shells and child zsh processes.
# Source from ~/.zshenv; do not initialize runtime managers here.
: "${ZSHRC_CONFIG_DIR:=$HOME/.config/zsh}"
: "${ZSH_CONFIG_DIR:=$ZSHRC_CONFIG_DIR}"
export ZSHRC_CONFIG_DIR ZSH_CONFIG_DIR
export EDITOR="${EDITOR:-zed}"
export VISUAL="${VISUAL:-$EDITOR}"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

_zsh_environment_defaults() {
    local dir
    local -a defaults=("$HOME/bin" "$HOME/.local/bin" "$PYENV_ROOT/bin")
    [[ "$OSTYPE" == darwin* ]] && defaults+=(/opt/homebrew/bin)
    defaults+=(/usr/local/bin /usr/bin /bin /usr/sbin /sbin)
    # Append only missing entries: an inherited project runtime stays first.
    for dir in "${defaults[@]}"; do
        if [[ -d "$dir" && ":${PATH:-}:" != *":$dir:"* ]]; then
            path+=("$dir")
        fi
    done
    export PATH
    if [[ -z "${JAVA_HOME:-}" && -d "$HOME/.sdkman/candidates/java/current" ]]; then
        export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
    fi
}
_zsh_environment_defaults
unfunction _zsh_environment_defaults
