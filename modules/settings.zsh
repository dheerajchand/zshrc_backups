#!/usr/bin/env zsh
# =================================================================
# SETTINGS - Centralized user config (vars/paths/aliases)
# =================================================================

: "${ZSH_SETTINGS_DIR:=$HOME/.config/zsh}"
: "${ZSH_VARS_FILE:=$ZSH_SETTINGS_DIR/vars.env}"
: "${ZSH_ALIASES_FILE:=$ZSH_SETTINGS_DIR/aliases.zsh}"
: "${ZSH_PATHS_FILE:=$ZSH_SETTINGS_DIR/paths.env}"

settings_init() {
    local created=0
    umask 077
    if [[ ! -f "$ZSH_VARS_FILE" ]]; then
        cat > "$ZSH_VARS_FILE" <<'EOF'
# Custom variables (export VAR="value")
# Example:
# export JARS_DIR="$HOME/.jars"
# export PYENV_DEFAULT_VENV="default_31111"
EOF
        created=1
        echo "Created $ZSH_VARS_FILE"
    fi
    if [[ ! -f "$ZSH_ALIASES_FILE" ]]; then
        cat > "$ZSH_ALIASES_FILE" <<'EOF'
# Custom aliases
# Example:
# alias proj='cd ~/Projects'
EOF
        created=1
        echo "Created $ZSH_ALIASES_FILE"
    fi
    if [[ ! -f "$ZSH_PATHS_FILE" ]]; then
        cat > "$ZSH_PATHS_FILE" <<'EOF'
# Custom convenience paths
# Example:
# export WRITING_STUFF="$HOME/Documents/Writing_Projects/Current"
EOF
        created=1
        echo "Created $ZSH_PATHS_FILE"
    fi
    [[ "$created" -eq 1 ]] || echo "All settings files already exist"
}

settings_edit_vars() {
    [[ -f "$ZSH_VARS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_FILE"
}

settings_edit_aliases() {
    [[ -f "$ZSH_ALIASES_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_ALIASES_FILE"
}

settings_edit_paths() {
    [[ -f "$ZSH_PATHS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_PATHS_FILE"
}

settings_status() {
    echo "⚙️  Settings"
    echo "============"
    echo "Vars:    $ZSH_VARS_FILE"
    echo "Aliases: $ZSH_ALIASES_FILE"
    echo "Paths:   $ZSH_PATHS_FILE"
}

# Load order: vars -> aliases -> paths
if [[ -f "$ZSH_VARS_FILE" ]]; then
    source "$ZSH_VARS_FILE"
fi
if [[ -f "$ZSH_ALIASES_FILE" ]]; then
    source "$ZSH_ALIASES_FILE"
fi
if [[ -f "$ZSH_PATHS_FILE" ]]; then
    export PATHS_LOADED=1
    source "$ZSH_PATHS_FILE"
fi

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ settings loaded"
fi
