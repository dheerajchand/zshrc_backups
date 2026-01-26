#!/usr/bin/env zsh
# =================================================================
# PATHS - Custom path aliases and convenience variables
# =================================================================

: "${ZSH_PATHS_FILE:=$HOME/.config/zsh/paths.env}"

paths_init() {
    if [[ -f "$ZSH_PATHS_FILE" ]]; then
        echo "paths file already exists: $ZSH_PATHS_FILE"
        return 1
    fi
    umask 077
    cat > "$ZSH_PATHS_FILE" <<'EOF'
# Custom convenience paths
# Example:
# export WRITING_STUFF="$HOME/Documents/Writing_Projects/Current"
EOF
    echo "Created $ZSH_PATHS_FILE"
}

paths_edit() {
    [[ -f "$ZSH_PATHS_FILE" ]] || paths_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_PATHS_FILE"
}

paths_list() {
    [[ -f "$ZSH_PATHS_FILE" ]] || { echo "No paths file: $ZSH_PATHS_FILE"; return 1; }
    echo "Custom paths: $ZSH_PATHS_FILE"
    rg -n "^export " "$ZSH_PATHS_FILE" 2>/dev/null || grep -n "^export " "$ZSH_PATHS_FILE"
}

if [[ -f "$ZSH_PATHS_FILE" ]]; then
    source "$ZSH_PATHS_FILE"
fi

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ paths loaded"
fi
