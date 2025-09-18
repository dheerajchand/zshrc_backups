#!/usr/bin/env zsh

# =====================================================
# CORE SHELL CONFIGURATION - REFACTORED
# =====================================================
# 
# Essential shell settings, aliases, and basic functionality
# This module contains the fundamental configuration that should
# load first and is required by other modules
# 
# REFACTORED: Improved error handling, performance, and modularity
# =====================================================

# REMOVED: Over-engineered dependency checking system
# These functions (_check_dependency, _safe_math, _compare_float) were never used
# and added unnecessary complexity. Simple inline checks are better.

# =====================================================
# SHELL OPTIONS & BEHAVIOR
# =====================================================

# Disable auto-correction (can be annoying with technical terms)
unsetopt correct

# Apply centralized shell configuration
# Note: CASE_SENSITIVE, DISABLE_AUTO_TITLE are defined in main zshrc
if [[ "$CASE_SENSITIVE" == "true" ]]; then
    # Apply case-sensitive completion settings
    zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
fi

# =====================================================
# EDITOR CONFIGURATION
# =====================================================
# Note: EDITOR and VISUAL are defined in main zshrc centralized section

# Terminal editor aliases (nvim as fallback)
alias vim="nvim"
alias edit="nvim"

# Open config directory shortcut using centralized EDITOR
edit-config() {
    local editor="${VISUAL:-${EDITOR:-zed}}"
    $editor "$ZSH_CONFIG_DIR"
}

# =====================================================
# BASIC SYSTEM CONFIGURATION
# =====================================================

# macOS-specific settings (only set if needed)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Enable diacritical marks (ä, ö, ü, etc.) instead of key repeat
    if [[ "$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null)" != "1" ]]; then
        defaults write -g ApplePressAndHoldEnabled -bool true
    fi
    
    # Note: WORKING_ON_LAPTOP is now defined in main zshrc centralized section
fi

# =====================================================
# ZSH COMPLETION SYSTEM SETUP
# =====================================================

# Load required completion modules early (before oh-my-zsh compinit)
zmodload -i zsh/computil 2>/dev/null
zmodload -i zsh/complete 2>/dev/null
zmodload -i zsh/complist 2>/dev/null

# =====================================================
# CORE ALIASES
# =====================================================

# Shell management
# Unset any existing alias before defining function
unalias zshreboot 2>/dev/null
zshreboot() {
    # Restart zsh shell completely (clears cached functions and reloads config)
    echo "🔄 Restarting zsh shell..."
    exec zsh
}
# Enhanced zshconfig function - opens entire config directory
function zshconfig() {
    local editor="${VISUAL:-${EDITOR:-zed}}"
    echo "Opening ZSH configuration directory with $editor..."
    "$editor" ~/.config/zsh
}

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ls enhancements
alias ll='ls -alF'
alias la='ls -A' 
alias l='ls -CF'

# Git shortcuts (basic)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# =====================================================
# UTILITY FUNCTIONS
# =====================================================

is_online() {
    # Check if internet connection is available
    #
    # Returns:
    #     0: Online
    #     1: Offline
    #
    # Examples:
    #     if is_online; then echo "Connected"; fi
    #     [[ "$(is_online_status)" == "online" ]] && do_something
    ping -c 1 google.com &> /dev/null
}

is_online_status() {
    # Get online status as string
    #
    # Returns:
    #     str: "online" or "offline"
    if is_online; then
        echo "online"
    else
        echo "offline"
    fi
}

command_exists() {
    # Check if a command exists
    #
    # Args:
    #     command (str): Command to check
    #
    # Returns:
    #     0: Command exists
    #     1: Command not found
    #
    # Examples:
    #     command_exists git && echo "Git is available"
    #     if command_exists python3; then python3 --version; fi
    command -v "$1" >/dev/null 2>&1
}

path_add() {
    # Add directory to PATH if not already present
    #
    # Args:
    #     path (str): Directory to add to PATH
    #     position (str, optional): "prepend" or "append" (default: prepend)
    #
    # Examples:
    #     path_add "/usr/local/bin"
    #     path_add "/opt/local/bin" "append"
    local new_path="$1"
    local position="${2:-prepend}"
    
    if [[ -d "$new_path" && ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            "prepend")
                export PATH="$new_path:$PATH"
                ;;
            "append")
                export PATH="$PATH:$new_path"
                ;;
        esac
    fi
}

mkcd() {
    # Create directory and cd into it
    #
    # Args:
    #     directory (str): Directory name to create
    #
    # Examples:
    #     mkcd new_project
    #     mkcd ~/projects/my_app
    mkdir -p "$1" && cd "$1"
}

extract() {
    # Universal extraction function
    #
    # Args:
    #     file (str): Archive file to extract
    #
    # Examples:
    #     extract archive.tar.gz
    #     extract package.zip
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
            *)           echo "Don't know how to extract '$1'" ;;
        esac
    else
        echo "File '$1' not found"
    fi
}

findtext() {
    # Search for text in files recursively
    #
    # Args:
    #     text (str): Text to search for
    #     path (str, optional): Path to search in (default: current directory)
    #
    # Examples:
    #     findtext "TODO"
    #     findtext "function.*python" ~/projects
    local text="$1"
    local path="${2:-.}"

    if command_exists rg; then
        rg "$text" "$path"
    elif command_exists ag; then
        ag "$text" "$path"
    else
        grep -r "$text" "$path"
    fi
}

restart_finder() {
    # Restart Finder to resolve file dialog and browsing issues
    #
    # This function is useful when experiencing:
    #   - Slow file dialogs in applications
    #   - File browser navigation issues
    #   - Stale file system caches
    #   - Problems with file creation/saving dialogs
    #
    # Examples:
    #     restart_finder
    #     restart_finder && echo "Finder restarted successfully"
    echo "🔄 Restarting Finder..."
    killall Finder 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ Finder restarted successfully"
        echo "💡 This should resolve file dialog and navigation issues"
    else
        echo "⚠️  Finder may not have been running, but it will start automatically"
    fi
}

# =====================================================
# PERFORMANCE HELPERS
# =====================================================

reload_shell() {
    # Reload shell configuration
    echo "🔄 Reloading shell configuration..."
    source ~/.zshrc
    echo "✅ Shell configuration reloaded"
}

# REMOVED: shell_startup_time() function - Major performance killer
# This function was recursively spawning shell instances during startup
# and using external bc processes, causing massive performance degradation.
#
# Replacement for testing: Use external timing tools like hyperfine:
#   hyperfine 'zsh -i -c exit'

# =====================================================
# SYSTEM INFORMATION
# =====================================================

system_info() {
    # Display system information
    echo "🖥️  System Information"
    echo "===================="
    echo "OS: $OSTYPE"
    echo "Shell: $SHELL"
    echo "User: $USER"
    echo "Home: $HOME"
    echo "Hostname: $(hostname)"
    
    if command_exists uname; then
        echo "Kernel: $(uname -r)"
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS Version: $(sw_vers -productVersion)"
    fi
    
    echo ""
    echo "Shell Configuration:"
    echo "Editor: $EDITOR"
    echo "Working on laptop: ${WORKING_ON_LAPTOP:-No}"
    echo "Case sensitive: ${CASE_SENSITIVE:-No}"
    echo "Auto title: ${DISABLE_AUTO_TITLE:-Enabled}"
}

# =====================================================
# PYTHON/UV ENVIRONMENT HELPERS
# =====================================================

py_env_switch() {
    # Quick switch between Python environments
    #
    # Usage:
    #   py_env_switch list           # List all environments
    #   py_env_switch myenv          # Switch to pyenv environment
    #   py_env_switch uv             # Use UV in current directory
    local target="${1:-list}"
    
    case "$target" in
        "list"|"-l"|"--list")
            echo "🐍 Available Python Environments:"
            echo ""
            echo "📦 Pyenv Environments:"
            if command_exists pyenv; then
                pyenv versions | sed 's/^/  /'
            else
                echo "  ❌ Pyenv not installed"
            fi
            echo ""
            echo "⚡ UV Projects:"
            if [[ -f "pyproject.toml" ]]; then
                echo "  ✅ Current directory has UV project"
            else
                echo "  ❌ No UV project in current directory"
            fi
            echo ""
            echo "Usage:"
            echo "  py_env_switch <env_name>    # Switch to pyenv environment"
            echo "  py_env_switch uv            # Activate UV project here"
            ;;
        "uv")
            if [[ -f "pyproject.toml" ]]; then
                if [[ -d ".venv" ]]; then
                    echo "⚡ Activating UV project: $(basename $PWD)"
                    source .venv/bin/activate
                else
                    echo "🔨 Setting up UV project..."
                    uv sync && source .venv/bin/activate
                fi
            else
                echo "❌ No pyproject.toml found. Run 'uv init' to create a UV project."
            fi
            ;;
        *)
            if command_exists pyenv; then
                echo "🐍 Switching to pyenv environment: $target"
                pyenv activate "$target" 2>/dev/null || {
                    echo "❌ Environment '$target' not found. Available:"
                    pyenv versions
                }
            else
                echo "❌ Pyenv not available"
            fi
            ;;
    esac
}

# Purpose: Get dependency list for project type
# Arguments: $1 - project_type (basic|spark|geo)
# Returns: 0 always, outputs dependencies to stdout
# Usage: _get_project_dependencies "spark"
_get_project_dependencies() {
    local project_type="$1"

    case "$project_type" in
        "basic")
            echo "pandas numpy matplotlib seaborn jupyter ipykernel"
            ;;
        "spark")
            echo "pandas numpy matplotlib seaborn jupyter ipykernel pyspark findspark"
            ;;
        "geo")
            echo "pandas numpy matplotlib seaborn jupyter ipykernel geopandas folium contextily"
            ;;
        *)
            echo "pandas numpy matplotlib seaborn jupyter ipykernel"
            ;;
    esac
}

# Purpose: Create standard data science project directory structure
# Arguments: None
# Returns: 0 on success, 1 on error
# Usage: _create_project_structure
_create_project_structure() {
    local dirs=(
        "notebooks"
        "data/raw"
        "data/processed"
        "src"
        "tests"
    )

    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir"; then
            echo "❌ Failed to create directory: $dir"
            return 1
        fi
    done

    return 0
}

# Purpose: Install dependencies with error handling
# Arguments: $1 - space-separated dependency list
# Returns: 0 on success, 1 on error
# Usage: _install_dependencies "pandas numpy matplotlib"
_install_dependencies() {
    local dependencies="$1"

    if ! command -v uv >/dev/null 2>&1; then
        echo "❌ UV not found. Install with: pip install uv"
        return 1
    fi

    echo "📦 Installing dependencies: $dependencies"

    # Install dependencies one by one for better error reporting
    for dep in $dependencies; do
        echo "   Installing $dep..."
        if ! uv add "$dep"; then
            echo "❌ Failed to install $dep"
            return 1
        fi
    done

    return 0
}

# Purpose: Initialize a data science project with UV and proper error handling
# Arguments: $1 - project_name, $2 - project_type (optional)
# Returns: 0 on success, 1 on error
# Usage: ds_project_init myproject [basic|spark|geo]
ds_project_init() {
    local project_name="$1"
    local project_type="${2:-basic}"

    # Validation
    if [[ -z "$project_name" ]]; then
        echo "❌ Project name required"
        echo "💡 Usage: ds_project_init <project_name> [basic|spark|geo]"
        return 1
    fi

    if [[ -d "$project_name" ]]; then
        echo "❌ Directory '$project_name' already exists"
        return 1
    fi

    if ! command -v uv >/dev/null 2>&1; then
        echo "❌ UV not found. Install with: pip install uv"
        return 1
    fi

    echo "🔬 Creating data science project: $project_name ($project_type)"

    # Create and enter project directory
    if ! mkdir -p "$project_name"; then
        echo "❌ Failed to create project directory"
        return 1
    fi

    cd "$project_name" || {
        echo "❌ Failed to enter project directory"
        return 1
    }

    # Initialize UV project
    echo "🔧 Initializing UV project..."
    if ! uv init --name "$project_name" --python 3.11; then
        echo "❌ Failed to initialize UV project"
        return 1
    fi

    # Install dependencies
    local dependencies
    dependencies=$(_get_project_dependencies "$project_type")

    if ! _install_dependencies "$dependencies"; then
        echo "❌ Failed to install dependencies"
        return 1
    fi

    # Create project structure
    echo "📁 Creating project structure..."
    if ! _create_project_structure; then
        echo "❌ Failed to create project structure"
        return 1
    fi

    echo ""
    echo "✅ Data science project '$project_name' created successfully!"
    echo "📋 Project type: $project_type"
    echo "📦 Dependencies installed: $dependencies"
    echo ""
    echo "🚀 Next steps:"
    echo "   source .venv/bin/activate"
    echo "   jupyter lab"
}

python_info() {
    # Show Python environment information
    echo "🐍 Python Environment Status"
    echo "============================"
    echo ""
    
    echo "Current Python:"
    echo "  Version: $(python --version 2>&1)"
    echo "  Location: $(which python)"
    echo "  Virtual Env: ${VIRTUAL_ENV:-'None'}"
    
    if command_exists pyenv; then
        echo "  Pyenv: $(pyenv version | cut -d' ' -f1)"
    fi
    
    if command_exists uv; then
        echo "  UV: $(uv --version)"
    fi
    
    echo ""
    if [[ -f "pyproject.toml" ]]; then
        echo "📦 Current Project:"
        echo "  UV Project: ✅ $(basename $PWD)"
        if [[ -d ".venv" ]]; then
            echo "  Virtual Env: ✅ Ready"
        else
            echo "  Virtual Env: ❌ Run 'uv sync'"
        fi
    else
        echo "📦 No UV project in current directory"
    fi
}

# =====================================================
# MODULE LOADING HELPERS
# =====================================================

load_module() {
    # Load a configuration module if it exists
    #
    # Args:
    #     module_name (str): Name of the module (without .zsh extension)
    #
    # Returns:
    #     0: Module loaded successfully
    #     1: Module not found or failed to load
    #
    # Examples:
    #     load_module "database"
    #     load_module "jetbrains"
    local module_name="$1"
    local module_path="$HOME/.config/zsh/config/${module_name}.zsh"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        echo "✅ Loaded module: $module_name"
        return 0
    else
        echo "⚠️  Module not found: $module_name ($module_path)"
        return 1
    fi
}

list_modules() {
    # List available configuration modules
    echo "📦 Available Configuration Modules:"
    echo ""
    
    local config_dir="$HOME/.config/zsh/config"
    if [[ -d "$config_dir" ]]; then
        for module in "$config_dir"/*.zsh; do
            if [[ -f "$module" ]]; then
                local module_name=$(basename "$module" .zsh)
                echo "  📄 $module_name"
                
                # Try to extract description from module file
                local description=$(grep -m 1 "^# .*" "$module" | sed 's/^# //' | head -1)
                if [[ -n "$description" && "$description" != "#!/usr/bin/env zsh" ]]; then
                    echo "     💡 $description"
                fi
            fi
        done
    else
        echo "  ❌ Config directory not found: $config_dir"
    fi
}

# =====================================================
# INITIALIZATION
# =====================================================

# Core module loaded indicator
export CORE_MODULE_LOADED=true

# Ensure basic directories exist
mkdir -p "$HOME/.config/zsh/config"
mkdir -p "$HOME/.config/zsh/functions"

# Set up basic PATH additions (if directories exist)
path_add "/usr/local/bin"
path_add "/opt/homebrew/bin"
path_add "$HOME/.local/bin"
path_add "$HOME/.jetbrains/bin"

# Load hook system
autoload -U add-zsh-hook

# =====================================================
# ALIASES FOR DATA SCIENCE WORKFLOW
# =====================================================

# Python environment aliases
alias py-switch='py_env_switch'
alias py-list='py_env_switch list'
alias py-info='python_info'
alias py-uv='py_env_switch uv'

# Data science project aliases
alias ds-init='ds_project_init'
alias ds-basic='ds_project_init'
alias ds-spark='ds_project_init'
alias ds-geo='ds_project_init'

# UV aliases
alias uv-init='uv init'
alias uv-add='uv add'
alias uv-sync='uv sync'
alias uv-run='uv run'

# =====================================================
# REPOSITORY PATH FUNCTIONS
# =====================================================

repo_paths() {
    # Display repository paths for the dual repository system
    #
    # Usage:
    #   repo_paths                    # Show all repository paths
    #   repo_paths active             # Show active repo path only
    #   repo_paths archive            # Show archive repo path only
    #
    # Examples:
    #   repo_paths                    # Display all paths
    #   cd "$(repo_paths active)"     # Navigate to active repo
    #   ls -la "$(repo_paths archive)" # List archive repo contents
    
    local target="${1:-all}"
    
    case "$target" in
        "active"|"dev"|"development")
            echo "$ZSH_ACTIVE_REPO"
            ;;
        "archive"|"backup")
            echo "$ZSH_ARCHIVE_REPO"
            ;;
        "all"|"")
            echo "🏠 Repository Paths:"
            echo "  📝 Active (Development): $ZSH_ACTIVE_REPO"
            echo "  📦 Archive (Backup):     $ZSH_ARCHIVE_REPO"
            echo ""
            echo "💡 Usage:"
            echo "  cd \"\$(repo_paths active)\"   # Navigate to active repo"
            echo "  cd \"\$(repo_paths archive)\"  # Navigate to archive repo"
            ;;
        *)
            echo "❌ Invalid option: $target"
            echo "Usage: repo_paths [active|archive|all]"
            return 1
            ;;
    esac
}

# Purpose: Get git repository information for a directory
# Arguments: $1 - repository path
# Returns: 0 if git repo, 1 if not, outputs info to stdout
# Usage: _get_git_info "/path/to/repo"
_get_git_info() {
    local repo_path="$1"

    if [[ ! -d "$repo_path/.git" ]]; then
        return 1
    fi

    cd "$repo_path" || return 1

    local branch=$(git branch --show-current 2>/dev/null || echo 'unknown')
    local last_commit=$(git log -1 --format='%h %s' 2>/dev/null || echo 'unknown')
    local remote=$(git remote get-url origin 2>/dev/null || echo 'none')

    echo "$branch|$last_commit|$remote"
    return 0
}

# Purpose: Display repository status information
# Arguments: $1 - repo_path, $2 - repo_name, $3 - repo_icon
# Returns: 0 always
# Usage: _show_repo_status "$ZSH_ACTIVE_REPO" "Active Repository" "📝"
_show_repo_status() {
    local repo_path="$1"
    local repo_name="$2"
    local repo_icon="$3"

    echo "$repo_icon $repo_name:"
    echo "   Path: $repo_path"

    local git_info
    if git_info=$(_get_git_info "$repo_path"); then
        IFS='|' read -r branch last_commit remote <<< "$git_info"
        echo "   Status: ✅ Git repository"
        echo "   Branch: $branch"
        echo "   Last Commit: $last_commit"
        echo "   Remote: $remote"

        # Repository-specific metrics
        if [[ "$repo_name" == *"Active"* ]]; then
            local file_count=$(find "$repo_path" -name "*.zsh" -o -name "*.sh" -o -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            echo "   Files: $file_count configuration files"
        elif [[ "$repo_name" == *"Archive"* ]]; then
            local backup_count=$(find "$repo_path" -name "config_*" -type d 2>/dev/null | wc -l | tr -d ' ')
            echo "   Backups: $backup_count timestamped backups"
        fi
    elif [[ -d "$repo_path" ]]; then
        echo "   Status: ⚠️  Directory exists but not a git repository"
    else
        echo "   Status: ❌ Directory not found"
    fi
}

# Purpose: Check synchronization status between two git repositories
# Arguments: $1 - active_repo_path, $2 - archive_repo_path
# Returns: 0 if synced, 1 if not synced, 2 if cannot determine
# Usage: _check_sync_status "$ZSH_ACTIVE_REPO" "$ZSH_ARCHIVE_REPO"
_check_sync_status() {
    local active_repo="$1"
    local archive_repo="$2"

    if [[ -d "$active_repo/.git" && -d "$archive_repo/.git" ]]; then
        local active_commit=$(cd "$active_repo" && git rev-parse HEAD 2>/dev/null)
        local archive_commit=$(cd "$archive_repo" && git rev-parse HEAD 2>/dev/null)

        if [[ "$active_commit" == "$archive_commit" ]]; then
            echo "   ✅ Repositories are synchronized"
            return 0
        else
            echo "   ⚠️  Repositories are out of sync"
            echo "   💡 Run: ./sync-repos.sh to synchronize"
            return 1
        fi
    else
        echo "   ❓ Cannot determine sync status"
        return 2
    fi
}

# Purpose: Show detailed repository status for both active and archive repos
# Arguments: None
# Returns: 0 always
# Usage: repo_status
repo_status() {
    echo "📊 Dual Repository System Status"
    echo "================================="
    echo ""

    # Show both repositories
    _show_repo_status "$ZSH_ACTIVE_REPO" "Active Repository (Development)" "📝"
    echo ""
    _show_repo_status "$ZSH_ARCHIVE_REPO" "Archive Repository (Backup)" "📦"

    echo ""
    echo "🔄 Sync Status:"
    _check_sync_status "$ZSH_ACTIVE_REPO" "$ZSH_ARCHIVE_REPO"
}

# Convenience aliases for repository navigation
alias repo-active='cd "$ZSH_ACTIVE_REPO"'
alias repo-archive='cd "$ZSH_ARCHIVE_REPO"'
alias repo-dev='cd "$ZSH_ACTIVE_REPO"'
alias repo-backup='cd "$ZSH_ARCHIVE_REPO"'

# =====================================================
# PATH MONITORING & MANAGEMENT FUNCTIONS
# =====================================================

path_status() {
    # Show comprehensive PATH status and health
    #
    # Usage:
    #   path_status                 # Full PATH analysis
    #   path_status --length        # Show only length info
    #   path_status --duplicates    # Show only duplicates
    #
    # Examples:
    #   path_status
    #   path_status --duplicates | head -10

    local mode="${1:-full}"

    case "$mode" in
        "--length"|"-l")
            echo "📏 PATH Length Analysis:"
            echo "   Total characters: ${#PATH}"
            echo "   Total entries: $(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')"
            echo "   Status: $(path_health_status)"
            ;;
        "--duplicates"|"-d")
            echo "🔄 PATH Duplicate Analysis:"
            local duplicates=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d)
            if [[ -n "$duplicates" ]]; then
                while IFS= read -r dup; do
                    local count=$(echo "$PATH" | tr ':' '\n' | grep -c "^$dup$")
                    echo "   ❌ $dup (appears $count times)"
                done < <(echo "$duplicates")
            else
                echo "   ✅ No duplicates found"
            fi
            ;;
        *)
            echo "🛤️  PATH Status Report"
            echo "====================="
            echo ""
            echo "📊 Statistics:"
            echo "   Total characters: ${#PATH}"
            echo "   Total entries: $(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')"
            echo "   Health status: $(path_health_status)"
            echo ""

            # Check for duplicates
            local duplicate_count=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d | wc -l | tr -d ' ')
            if [[ "$duplicate_count" -gt 0 ]]; then
                echo "⚠️  Found $duplicate_count duplicate paths"
                echo "   Run 'path_status --duplicates' to see details"
            else
                echo "✅ No duplicate paths found"
            fi

            # Check for non-existent paths
            local missing_count=0
            while IFS= read -r dir; do
                [[ -n "$dir" && ! -d "$dir" ]] && ((missing_count++))
            done < <(echo "$PATH" | tr ':' '\n') 2>/dev/null

            echo ""
            echo "🔧 Available commands:"
            echo "   path_clean               # Remove duplicates and invalid paths"
            echo "   path_monitor on          # Enable automatic PATH monitoring"
            echo "   path_backup              # Create PATH backup"
            echo "   path_restore             # Restore from backup"
            ;;
    esac
}

path_health_status() {
    # Return PATH health status based on length and content
    local length=${#PATH}

    if [[ $length -lt $PATH_OPTIMAL_THRESHOLD ]]; then
        echo "✅ HEALTHY"
    elif [[ $length -lt $PATH_WARNING_THRESHOLD ]]; then
        echo "⚡ MODERATE"
    elif [[ $length -lt $PATH_CRITICAL_THRESHOLD ]]; then
        echo "⚠️  CONCERNING"
    else
        echo "❌ CRITICAL"
    fi
}

# Purpose: Analyze PATH and return cleaning statistics
# Arguments: None
# Returns: 0 always, outputs stats to stdout
# Usage: _path_analyze_issues
_path_analyze_issues() {
    local duplicate_count=0
    local missing_count=0
    local empty_count=0
    local seen_paths=""

    while IFS= read -r dir; do
        if [[ -z "$dir" ]]; then
            ((empty_count++))
        elif [[ ":$seen_paths:" == *":$dir:"* ]]; then
            ((duplicate_count++))
        elif [[ ! -d "$dir" ]]; then
            ((missing_count++))
        else
            seen_paths="${seen_paths:+$seen_paths:}$dir"
        fi
    done < <(echo "$PATH" | tr ':' '\n')

    echo "$duplicate_count $missing_count $empty_count"
}

# Purpose: Clean PATH by removing duplicates and invalid entries
# Arguments: $1 - new_path variable name, $2 - mode (optional)
# Returns: 0 on success
# Usage: _path_clean_entries new_path_var "--dry-run"
_path_clean_entries() {
    local -n path_result=$1
    local mode="$2"
    local seen_paths=""

    path_result=""

    while IFS= read -r dir; do
        # Skip empty, duplicate, or non-existent directories
        if [[ -z "$dir" || ":$seen_paths:" == *":$dir:"* || ! -d "$dir" ]]; then
            [[ "$mode" != "--dry-run" && -n "$dir" ]] && {
                [[ ":$seen_paths:" == *":$dir:"* ]] && echo "   🔄 Removing duplicate: $dir"
                [[ ! -d "$dir" ]] && echo "   ❌ Removing non-existent: $dir"
            }
            continue
        fi

        # Add valid, unique directory
        seen_paths="${seen_paths:+$seen_paths:}$dir"
        path_result="${path_result:+$path_result:}$dir"
    done < <(echo "$PATH" | tr ':' '\n')
}

# Purpose: Report PATH cleaning results
# Arguments: $1 - original_length, $2 - new_length, $3 - original_count, $4 - new_count
# Returns: 0 always
# Usage: _path_report_results 2000 1500 50 40
_path_report_results() {
    local original_length=$1 new_length=$2 original_count=$3 new_count=$4
    local saved_chars=$((original_length - new_length))
    local saved_entries=$((original_count - new_count))

    echo ""
    echo "✅ PATH cleaned successfully!"
    echo "📊 Results:"
    echo "   Length: $original_length → $new_length characters (-$saved_chars)"
    echo "   Entries: $original_count → $new_count paths (-$saved_entries)"
    echo "   Health: $(path_health_status)"
    echo ""
    echo "💡 Changes have been backed up. Use 'path_restore' if needed."
}

# Purpose: Clean and optimize PATH by removing duplicates and invalid entries
# Arguments: $1 - mode (optional: --auto, --dry-run)
# Returns: 0 on success, 1 on error
# Usage: path_clean [--dry-run|--auto]
path_clean() {
    local mode="${1:-interactive}"

    echo "🧹 PATH Cleaning Utility"
    echo "========================"
    echo ""

    # Create backup first
    path_backup

    # Get original stats
    local original_length=${#PATH}
    local original_count=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')

    echo "📊 Before cleaning:"
    echo "   Length: $original_length characters"
    echo "   Entries: $original_count paths"
    echo ""

    # Analyze issues
    read -r duplicate_count missing_count empty_count < <(_path_analyze_issues)

    if [[ "$mode" == "--dry-run" ]]; then
        echo "🔍 DRY RUN - No changes made"
        echo "Would remove:"
        echo "   Duplicates: $duplicate_count"
        echo "   Missing paths: $missing_count"
        echo "   Empty entries: $empty_count"
        return 0
    fi

    # Clean PATH
    local new_path
    _path_clean_entries new_path "$mode"
    export PATH="$new_path"

    # Report results
    local new_length=${#PATH}
    local new_count=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')
    _path_report_results "$original_length" "$new_length" "$original_count" "$new_count"
}

path_monitor() {
    # Enable/disable automatic PATH monitoring
    #
    # Usage:
    #   path_monitor on            # Enable monitoring
    #   path_monitor off           # Disable monitoring
    #   path_monitor status        # Show monitoring status
    #
    # Examples:
    #   path_monitor on            # Start monitoring PATH changes
    #   path_monitor status        # Check if monitoring is active

    local action="${1:-status}"

    case "$action" in
        "on"|"enable")
            export PATH_MONITORING_ENABLED=true
            echo "✅ PATH monitoring enabled"
            echo "   PATH will be automatically cleaned when it exceeds $PATH_CRITICAL_THRESHOLD characters"
            echo "   Monitoring status stored in \$PATH_MONITORING_ENABLED"
            ;;
        "off"|"disable")
            unset PATH_MONITORING_ENABLED
            echo "❌ PATH monitoring disabled"
            ;;
        "status"|*)
            if [[ "$PATH_MONITORING_ENABLED" == "true" ]]; then
                echo "✅ PATH monitoring is ACTIVE"
                echo "   Current PATH length: ${#PATH} characters"
                echo "   Status: $(path_health_status)"
            else
                echo "❌ PATH monitoring is INACTIVE"
                echo "   Enable with: path_monitor on"
            fi
            ;;
    esac
}

path_backup() {
    # Create backup of current PATH
    local backup_file="$HOME/.config/zsh/.path_backup_$(date +%Y%m%d_%H%M%S)"
    echo "$PATH" > "$backup_file"
    export PATH_BACKUP_FILE="$backup_file"
    echo "💾 PATH backed up to: $backup_file"
}

path_restore() {
    # Restore PATH from most recent backup
    if [[ -n "$PATH_BACKUP_FILE" && -f "$PATH_BACKUP_FILE" ]]; then
        export PATH=$(cat "$PATH_BACKUP_FILE")
        echo "🔄 PATH restored from: $PATH_BACKUP_FILE"
        echo "📊 Restored PATH length: ${#PATH} characters"
    else
        echo "❌ No backup file found. PATH_BACKUP_FILE: ${PATH_BACKUP_FILE:-'not set'}"
        echo "💡 Use 'path_backup' to create a backup first"
    fi
}

# DISABLED: auto_path_cleanup() precmd hook - Major performance killer
# This hook was running before every prompt, checking PATH length on every command.
# This caused noticeable shell responsiveness issues.
#
# auto_path_cleanup() {
#     # Automatic PATH cleanup when monitoring is enabled
#     if [[ "$PATH_MONITORING_ENABLED" == "true" && ${#PATH} -gt $PATH_CRITICAL_THRESHOLD ]]; then
#         echo "⚠️  PATH length (${#PATH}) exceeds threshold, auto-cleaning..."
#         path_clean --auto
#     fi
# }
#
# Manual PATH cleanup function (use when needed):
path_cleanup_manual() {
    if [[ ${#PATH} -gt $PATH_CRITICAL_THRESHOLD ]]; then
        echo "⚠️  PATH length (${#PATH}) exceeds threshold"
        echo "🔧 Run 'path_clean --auto' to clean up duplicates"
        return 1
    else
        echo "✅ PATH length (${#PATH}) is healthy"
        return 0
    fi
}

# DISABLED: PATH monitoring hook that was causing performance issues
# if [[ -n "$ZSH_VERSION" ]]; then
#     autoload -U add-zsh-hook
#     add-zsh-hook precmd auto_path_cleanup
# fi

# =====================================================
# ENHANCED PATH ADD FUNCTION (REPLACES EXISTING)
# =====================================================

# Override the existing path_add function with smart deduplication
path_add() {
    # Enhanced path_add with automatic deduplication and monitoring
    #
    # Args:
    #     path (str): Directory to add to PATH
    #     position (str, optional): "prepend" or "append" (default: prepend)
    #
    # Examples:
    #     path_add "/usr/local/bin"
    #     path_add "/opt/local/bin" "append"
    local new_path="$1"
    local position="${2:-prepend}"

    # Only add if directory exists and not already in PATH
    if [[ -d "$new_path" && ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            "prepend")
                export PATH="$new_path:$PATH"
                ;;
            "append")
                export PATH="$PATH:$new_path"
                ;;
        esac

        # Manual PATH cleanup if needed (auto_path_cleanup was disabled for performance)
        if [[ ${#PATH} -gt $PATH_CRITICAL_THRESHOLD ]]; then
            echo "⚠️  PATH length (${#PATH}) is getting long. Consider running: path_cleanup_manual"
        fi
    fi
}

# =====================================================
# ICLOUD DIAGNOSTICS & CLEANUP FUNCTIONS
# =====================================================

# Constants for iCloud management
readonly ICLOUD_CPU_WARNING_THRESHOLD=50
readonly ICLOUD_CPU_MODERATE_THRESHOLD=10

# Constants for PATH management
readonly PATH_WARNING_THRESHOLD=1000
readonly PATH_CRITICAL_THRESHOLD=1500
readonly PATH_OPTIMAL_THRESHOLD=500

_check_brctl_available() {
    # Centralized brctl dependency check with comprehensive error handling
    #
    # Returns:
    #   0: brctl is available
    #   1: brctl not found
    #
    # Outputs appropriate error messages and suggestions
    if ! command -v brctl >/dev/null 2>&1; then
        cat << 'EOF'
❌ brctl not found. Install iCloud sync tools:
   This function requires brctl (part of iCloud/CloudKit tools)
   On macOS, ensure iCloud Drive is enabled in System Preferences

   If brctl is still missing:
   1. Check System Preferences > Apple ID > iCloud > iCloud Drive
   2. Restart the system if iCloud Drive was just enabled
   3. Try running: sudo xcode-select --install
EOF
        return 1
    fi
    return 0
}

_get_fileproviderd_cpu() {
    # Get fileproviderd CPU usage efficiently without multiple pipes
    #
    # Returns:
    #   CPU percentage as integer (e.g., "25" for 25.5%)
    #   Empty string if process not found
    local cpu_info
    cpu_info=$(ps -o pid,pcpu,comm -e | awk '/fileproviderd$/ {print int($2); exit}')
    echo "${cpu_info:-0}"
}

_validate_container_name() {
    # Secure container name validation to prevent directory traversal
    #
    # Args:
    #   container_name (str): Container name to validate
    #
    # Returns:
    #   0: Valid container name
    #   1: Invalid or dangerous container name
    local container_name="$1"

    # Check for empty name
    if [[ -z "$container_name" ]]; then
        echo "❌ Container name cannot be empty"
        return 1
    fi

    # Check for dangerous patterns
    if [[ "$container_name" =~ (\.\./|^/|^-|^~) ]]; then
        echo "❌ Container name contains dangerous path elements: $container_name"
        return 1
    fi

    # Allow only safe characters: letters, numbers, dots, hyphens, underscores
    if [[ ! "$container_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "❌ Container name contains invalid characters: $container_name"
        echo "   Only letters, numbers, dots, hyphens, and underscores allowed"
        return 1
    fi

    # Check length (reasonable limit)
    if [[ ${#container_name} -gt 100 ]]; then
        echo "❌ Container name too long (max 100 characters): ${#container_name}"
        return 1
    fi

    return 0
}

_analyze_container_issues() {
    # Helper function to analyze container issues and avoid code duplication
    #
    # Description:
    #   Searches brctl output for specific patterns and provides consistent
    #   formatting and reporting. Eliminates code duplication between
    #   different analysis modes in icloud_diagnose().
    #
    # Args:
    #   brctl_output (str): Output from brctl status command
    #   pattern (str): Grep pattern to match (e.g., "blocked|error|failed")
    #   description (str): Human-readable description of what we're searching for
    #   max_results (int, optional): Maximum results to show (default: 10)
    #
    # Returns:
    #   Number of issues found (via stdout)
    #
    # Examples:
    #   issues=$(_analyze_container_issues "$output" "blocked" "Showing blocked containers" 10)
    #   perf_issues=$(_analyze_container_issues "$output" "(error|failed)" "Performance issues" 5)
    #
    # Output Format:
    #   Prints formatted issue list with proper indentation
    #   Returns count as last line for capture
    local brctl_output="$1"
    local pattern="$2"
    local description="$3"
    local max_results="${4:-10}"

    echo "   🔍 $description..."
    local issues
    issues=$(echo "$brctl_output" | grep -E "$pattern" | head -"$max_results")

    if [[ -n "$issues" ]]; then
        echo "$issues" | sed 's/^/     /'
        echo "$issues" | wc -l | tr -d ' '
    else
        echo "   ✅ No issues detected"
        echo "0"
    fi
}

icloud_diagnose() {
    # Diagnose iCloud sync issues and identify problematic containers
    _check_brctl_available || return 1

    # This function identifies containers that are:
    #   - Stuck in sync loops (high CPU usage)
    #   - Blocked due to uninstalled apps
    #   - Failed sync operations
    #   - Consuming excessive system resources
    #
    # Usage:
    #     icloud_diagnose                # Full diagnostic report
    #     icloud_diagnose --cpu          # Focus on CPU-intensive containers
    #     icloud_diagnose --blocked      # Show only blocked containers
    #
    # Examples:
    #     icloud_diagnose
    #     icloud_diagnose --blocked | grep uninstalled

    local focus_mode="${1:-}"

    echo "🔍 iCloud Drive Diagnostic Report"
    echo "================================="
    echo ""

    # Check fileproviderd CPU usage efficiently
    echo "📊 File Provider Daemon Status:"
    local fileproviderd_cpu
    fileproviderd_cpu=$(_get_fileproviderd_cpu)

    if [[ "$fileproviderd_cpu" -gt 0 ]]; then
        echo "   CPU Usage: ${fileproviderd_cpu}%"
        if (( fileproviderd_cpu > ICLOUD_CPU_WARNING_THRESHOLD )); then
            echo "   ⚠️  HIGH CPU USAGE - Investigating sync issues..."
        elif (( fileproviderd_cpu > ICLOUD_CPU_MODERATE_THRESHOLD )); then
            echo "   ⚡ Moderate activity"
        else
            echo "   ✅ Normal operation"
        fi
    else
        echo "   ❓ fileproviderd not running or idle"
    fi
    echo ""

    # Analyze container sync status with proper error handling
    echo "📦 Container Sync Analysis:"

    local brctl_output
    if ! brctl_output=$(brctl status 2>&1); then
        echo "   ❌ Failed to get container status from brctl"
        echo "   Error: $brctl_output"
        return 1
    fi

    local issues_found=0
    case "$focus_mode" in
        "--performance")
            issues_found=$(_analyze_container_issues "$brctl_output" "(blocked|error|failed|needs-sync)" "Focusing on performance issues" 10)
            ;;
        "--blocked")
            issues_found=$(_analyze_container_issues "$brctl_output" "blocked-app-uninstalled" "Showing blocked containers" 10)
            ;;
        # Deprecated alias for backwards compatibility
        "--cpu")
            echo "⚠️  --cpu is deprecated, use --performance instead"
            issues_found=$(_analyze_container_issues "$brctl_output" "(blocked|error|failed|needs-sync)" "Focusing on performance issues" 10)
            ;;
        ""|"--all")
            echo "   📋 Full container status (showing issues only):"
            issues_found=$(_analyze_container_issues "$brctl_output" "(blocked|error|failed|needs-sync|uninstalled)" "" 15)
            ;;
        *)
            echo "❌ Invalid option: $focus_mode"
            echo "Usage: icloud_diagnose [--performance|--blocked|--all]"
            return 1
            ;;
    esac

    [[ $issues_found -gt 0 ]] && echo "   Found $issues_found container issues"

    echo ""
    echo "🔧 Quick Actions Available:"
    echo "   icloud_cleanup                 # Interactive cleanup of problematic containers"
    echo "   icloud_cleanup --uninstalled   # Remove all uninstalled app containers"
    echo "   icloud_cleanup --force <name>  # Force remove specific container"
    echo ""
    echo "💡 If fileproviderd CPU > 50%, run icloud_cleanup to resolve sync issues"
}

_restart_fileproviderd() {
    # Safely restart fileproviderd with error handling
    echo "🔄 Restarting fileproviderd to apply changes..."
    if pkill -f fileproviderd 2>/dev/null; then
        sleep 2
        echo "✅ fileproviderd restarted successfully"
    else
        echo "⚠️  fileproviderd may not have been running"
    fi
}

_disable_container_sync() {
    # Disable sync for a specific container with error handling
    #
    # Args:
    #   container_name (str): Container to disable sync for
    #
    # Returns:
    #   0: Success
    #   1: Failed to disable sync
    local container_name="$1"

    if ! _validate_container_name "$container_name"; then
        return 1
    fi

    echo "🔧 Disabling sync for: $container_name"
    if defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$container_name" 2>/dev/null; then
        _restart_fileproviderd
        echo "✅ Sync disabled successfully"
        return 0
    else
        echo "❌ Failed to disable sync for $container_name"
        return 1
    fi
}

_cleanup_uninstalled_containers() {
    # Remove containers for uninstalled apps
    echo "🔍 Finding containers for uninstalled apps..."

    local brctl_output
    if ! brctl_output=$(brctl status 2>&1); then
        echo "❌ Failed to get container status: $brctl_output"
        return 1
    fi

    local blocked_containers
    blocked_containers=($(echo "$brctl_output" | grep "blocked-app-uninstalled" | cut -d'<' -f2 | cut -d'[' -f1))

    if [[ ${#blocked_containers[@]} -eq 0 ]]; then
        echo "✅ No blocked containers found!"
        return 0
    fi

    echo "Found ${#blocked_containers[@]} problematic containers:"
    printf "   📦 %s\n" "${blocked_containers[@]}"
    echo ""

    echo "🔧 Disabling sync for these containers..."
    local containers_disabled=0
    for container in "${blocked_containers[@]}"; do
        echo "   Disabling: $container"
        if defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$container" 2>/dev/null; then
            ((containers_disabled++))
        else
            echo "   ⚠️  Could not disable sync for $container"
        fi
    done

    _restart_fileproviderd
    echo "✅ Cleanup completed! Disabled sync for $containers_disabled containers."
    echo "💡 Run 'icloud_diagnose' to verify the fix."
}

_find_container_paths() {
    # Securely find container paths with validation
    #
    # Args:
    #   container_name (str): Container name to search for
    #
    # Returns:
    #   Array of matching paths (via stdout)
    local container_name="$1"
    local mobile_docs="$HOME/Library/Mobile Documents"

    if [[ ! -d "$mobile_docs" ]]; then
        echo "❌ Mobile Documents directory not found: $mobile_docs" >&2
        return 1
    fi

    # Use find with strict safety options to prevent traversal attacks
    find "$mobile_docs" -maxdepth 1 -type d -name "*${container_name}*" -print0 2>/dev/null
}

_force_remove_container() {
    # Force remove a container with extensive safety checks
    #
    # Description:
    #   Performs secure removal of iCloud containers with multi-step validation
    #   and confirmation process. Uses safe path finding and validation to
    #   prevent directory traversal attacks and accidental deletions.
    #
    # Args:
    #   container_name (str): Container to remove
    #
    # Returns:
    #   0: Success
    #   1: Failed or cancelled
    #
    # Security:
    #   Input validation: Full container name validation
    #   Path safety: Secure path finding with maxdepth limits
    #   Double confirmation: Two separate user confirmations required
    #   Sudo validation: Only removes validated, existing directories
    local container_name="$1"

    # First safety check: validate container name format
    if ! _validate_container_name "$container_name"; then
        return 1
    fi

    # Initial warning and first confirmation
    echo "⚠️  Force removing container: $container_name"
    echo "This will permanently delete all data for this container."
    echo -n "Are you sure? (y/N): "
    read -r confirmation

    # Exit early if user cancels at first prompt
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        return 1
    fi

    echo "🗑️  Removing container files..."

    # Second safety check: find exact container paths using secure method
    # This prevents glob expansion attacks and validates paths exist
    local container_paths=()
    while IFS= read -r -d '' path; do
        container_paths+=("$path")
    done < <(_find_container_paths "$container_name")

    # Validate that we found actual containers to remove
    if [[ ${#container_paths[@]} -eq 0 ]]; then
        echo "❌ No containers found matching: $container_name"
        return 1
    fi

    # Show user exactly what will be deleted and get final confirmation
    echo "Found ${#container_paths[@]} container(s) to remove:"
    printf "  %s\n" "${container_paths[@]}"
    echo -n "Proceed with deletion? (y/N): "
    read -r final_confirmation

    # Exit if user cancels at final prompt
    if [[ ! "$final_confirmation" =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        return 1
    fi

    # Perform actual removal with individual path validation
    local containers_removed=0
    for path in "${container_paths[@]}"; do
        # Additional safety: verify path exists and is a directory before removal
        if [[ -d "$path" ]] && sudo rm -rf "$path" 2>/dev/null; then
            ((containers_removed++))
            echo "✅ Removed: $(basename "$path")"
        else
            echo "❌ Failed to remove: $(basename "$path")"
        fi
    done

    # Report results and restart daemon if any containers were removed
    if [[ $containers_removed -gt 0 ]]; then
        _restart_fileproviderd
        echo "✅ Successfully removed $containers_removed containers"
    else
        echo "❌ No containers were removed"
        return 1
    fi
}

_show_cleanup_menu() {
    # Interactive cleanup menu
    cat << 'EOF'
🛠️  Available cleanup options:

1. 📱 Remove containers for uninstalled apps (RECOMMENDED)
   icloud_cleanup --uninstalled

2. 🚫 Disable sync for specific container
   icloud_cleanup --disable <container-name>

3. 🗑️  Force remove container (permanent deletion)
   icloud_cleanup --force <container-name>

💡 Run 'icloud_diagnose' first to identify problematic containers

EOF

    echo -n "Choose option (1-3) or press Enter to exit: "
    read -r choice

    case "$choice" in
        "1")
            _cleanup_uninstalled_containers
            ;;
        "2")
            echo -n "Enter container name: "
            read -r container_name
            _disable_container_sync "$container_name"
            ;;
        "3")
            echo -n "Enter container name: "
            read -r container_name
            _force_remove_container "$container_name"
            ;;
        *)
            echo "👋 Cleanup cancelled"
            ;;
    esac
}

icloud_cleanup() {
    # Clean up problematic iCloud containers (now modular and secure)
    #
    # Usage:
    #   icloud_cleanup                    # Interactive mode
    #   icloud_cleanup --uninstalled     # Remove uninstalled app containers
    #   icloud_cleanup --disable <name>  # Disable sync for container
    #   icloud_cleanup --force <name>    # Force remove container (requires sudo)

    # Use centralized dependency check
    _check_brctl_available || return 1

    local action="${1:-interactive}"
    local target_container="$2"

    echo "🧹 iCloud Container Cleanup Utility"
    echo "==================================="
    echo ""

    case "$action" in
        "--uninstalled")
            _cleanup_uninstalled_containers
            ;;
        "--disable")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --disable <container-name>"
                return 1
            fi
            _disable_container_sync "$target_container"
            ;;
        "--force")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --force <container-name>"
                return 1
            fi
            _force_remove_container "$target_container"
            ;;
        # Deprecated alias for backwards compatibility
        "--blocked")
            echo "⚠️  --blocked is deprecated, use --uninstalled instead"
            _cleanup_uninstalled_containers
            ;;
        *)
            _show_cleanup_menu
            ;;
    esac
}