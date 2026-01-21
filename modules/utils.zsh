#!/usr/bin/env zsh
# =================================================================
# UTILS - Core Utilities
# =================================================================
# Essential helper functions for daily shell work
# =================================================================

: "${JARS_DIR:=$HOME/.jars}"

# Check if internet connection is available
# Used by Spark to decide: local JARs vs Maven downloads
is_online() {
    ping -c 1 google.com &> /dev/null
}

is_online_status() {
    is_online && echo "online" || echo "offline"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Universal archive extraction
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Unknown archive format: $1" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

download_jars() {
    local dest="${JARS_DIR}"
    local -a coords=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dest)
                dest="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: download_jars [--dest <dir>] <group:artifact:version> [more...]" >&2
                return 0
                ;;
            *)
                coords+=("$1")
                shift
                ;;
        esac
    done
    if [[ ${#coords[@]} -eq 0 ]]; then
        echo "Usage: download_jars [--dest <dir>] <group:artifact:version> [more...]" >&2
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo "Neither curl nor wget found; cannot download jars" >&2
        return 1
    fi
    mkdir -p "$dest" || return 1
    local coord
    for coord in "${coords[@]}"; do
        for c in ${(s:,:)coord}; do
            [[ -z "$c" ]] && continue
            local group artifact version
            IFS=':' read -r group artifact version <<< "$c"
            if [[ -z "$group" || -z "$artifact" || -z "$version" ]]; then
                echo "Invalid coordinate: $c" >&2
                return 1
            fi
            local group_path="${group//./\/}"
            local jar_name="${artifact}-${version}.jar"
            local url="https://repo1.maven.org/maven2/${group_path}/${artifact}/${version}/${jar_name}"
            local out="${dest}/${jar_name}"
            if [[ -f "$out" ]]; then
                continue
            fi
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL "$url" -o "$out" || return 1
            else
                wget -qO "$out" "$url" || return 1
            fi
        done
    done
}

# Recursive text search
findtext() {
    grep -r "$1" .
}

# Add directory to PATH if not already present
path_add() {
    local new_path="$1"
    local position="${2:-prepend}"
    
    if [[ -d "$new_path" && ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            prepend) export PATH="$new_path:$PATH" ;;
            append)  export PATH="$PATH:$new_path" ;;
        esac
    fi
}

# Simple PATH deduplication
path_clean() {
    local seen=()
    local cleaned=""
    for dir in ${(s/:/)PATH}; do
        if [[ -d "$dir" ]] && [[ ! " ${seen[@]} " =~ " $dir " ]]; then
            seen+=("$dir")
            cleaned="${cleaned:+$cleaned:}$dir"
        fi
    done
    export PATH="$cleaned"
    echo "✅ PATH cleaned: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') directories"
}

# Edit zsh configuration
zshconfig() {
    local editor="${EDITOR:-vim}"
    local config_dir="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}"
    
    if [[ ! -d "$config_dir" ]]; then
        echo "❌ Configuration directory not found: $config_dir"
        return 1
    fi
    
    echo "🔧 Opening configuration directory: $config_dir"
    echo "📝 Using editor: $editor"
    
    # Open the directory in the specified editor
    if command -v "$editor" >/dev/null 2>&1; then
        "$editor" "$config_dir"
    else
        echo "❌ Editor not found: $editor"
        echo "💡 Set EDITOR environment variable or install $editor"
        return 1
    fi
}

# Reload zsh configuration
zshreboot() {
    echo "🔄 Reloading zsh configuration..."
    
    # Use exec to replace current shell with fresh one (cleanest reload)
    exec zsh
}

# Aliases for common variations
alias reload='zshreboot'
alias zshreload='zshreboot'
alias editconfig='zshconfig'

echo "✅ utils loaded"


