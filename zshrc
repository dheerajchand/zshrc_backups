#!/usr/bin/env zsh
# =================================================================
# CLEAN ZSHRC - Focused Shell Configuration
# =================================================================
# Purpose: Python, Spark/Hadoop, Docker, Database, Git management
# No security theater, just useful functionality
# =================================================================

# Basic environment
export EDITOR="zed"
export VISUAL="$EDITOR"
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Minimal init for non-TTY interactive shells (prevents GUI app timeouts)
# Set ZSH_FORCE_FULL_INIT=1 to override.
if [[ -o interactive && ! -t 0 && ! -t 1 && -z "${ZSH_FORCE_FULL_INIT:-}" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    else
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    fi
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
    [[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
    return 0
fi

# Set base PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
else
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
if [[ -d "$HOME/.pyenv/bin" && ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
    export PATH="$HOME/.pyenv/bin:$PATH"
fi

# Initialize SDKMAN (sets HADOOP_HOME, SPARK_HOME, JAVA_HOME)
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# Set *_HOME variables if not set by SDKMAN
[[ -z "$HADOOP_HOME" && -d "$SDKMAN_DIR/candidates/hadoop/current" ]] && export HADOOP_HOME="$SDKMAN_DIR/candidates/hadoop/current"
[[ -z "$SPARK_HOME" && -d "$SDKMAN_DIR/candidates/spark/current" ]] && export SPARK_HOME="$SDKMAN_DIR/candidates/spark/current"
[[ -z "$JAVA_HOME" && -d "$SDKMAN_DIR/candidates/java/current" ]] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"

# Oh-My-Zsh setup
export ZSH="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

# Initialize completion system
autoload -Uz compinit && compinit
zmodload zsh/compctl 2>/dev/null

# Load Oh-My-Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# =================================================================
# STAGGERED LOADING - Performance Optimization for IDEs
# =================================================================
# IDEs take longer to load zsh, so we load modules progressively
# Regular terminals get everything immediately
# =================================================================

# Detect if running in an IDE
detect_ide() {
    # Check for common IDE environment variables
    [[ -n "$PYCHARM_HOSTED" ]] && return 0
    [[ -n "$DATASPELL_HOSTED" ]] && return 0
    [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]] && return 0
    [[ -n "$JETBRAINS_IDE" ]] && return 0
    [[ "$TERM_PROGRAM" == "vscode" ]] && return 0
    
    # Check process tree for IDE
    local parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
    [[ "$parent_proc" =~ (pycharm|idea|webstorm|goland|datagrip|dataspell|code) ]] && return 0
    
    return 1
}

# Module loader
load_module() {
    local module="$1"
    if [[ -f "$ZSH_CONFIG_DIR/modules/$module.zsh" ]]; then
        source "$ZSH_CONFIG_DIR/modules/$module.zsh"
    else
        echo "❌ Module not found: $module"
        return 1
    fi
}

# =================================================================
# ESSENTIAL ALIASES & CONSTANTS - Load First
# =================================================================

# Basic aliases (always available immediately)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts (in addition to Oh-My-Zsh)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# =================================================================
# MODULE LOADING - Staggered for IDEs, Immediate for Terminals
# =================================================================

# Load modules based on environment
if detect_ide; then
    echo "🖥️  IDE detected - using staggered loading for faster startup"
    
    # Tier 1: Essential (load immediately - IDE needs Python right away)
    load_module utils       # Provides is_online, mkcd, extract, path_add
    load_module secrets     # Local + 1Password env vars
    load_module python      # Python environment (geo31111 auto-activated)
    load_module system_diagnostics  # iCloud/Dropbox helpers
    load_module screen      # GNU screen helpers
    
    # Tier 2: Credentials & paths (load in background after brief delay)
    {
        sleep 0.1
        load_module credentials  # 1Password/Keychain
        load_module database     # PostgreSQL with credentials
        load_module backup       # Git self-backup
    } &
    
    # Tier 3: Heavy tools (load in background - Spark/Hadoop/Docker)
    {
        sleep 0.5
        load_module docker       # Docker management
        load_module spark        # Spark cluster (uses is_online!)
        load_module hadoop       # Hadoop/YARN/HDFS
        echo "✅ All modules loaded" >&2
    } &
    
    echo "💡 Python ready now, Spark/Hadoop loading in background"
    
else
    # Regular terminal - load everything immediately (fast enough)
    echo "🚀 Loading modules..."
    
    load_module utils
    load_module secrets
    load_module python
    load_module system_diagnostics
    load_module screen
    load_module credentials
    load_module database
    load_module backup
    load_module docker
    load_module spark
    load_module hadoop
fi

# =================================================================
# FIX PATH - Ensure Hadoop/Spark bins are in PATH after all loading
# =================================================================
# Problem: pyenv init and other tools may reorganize PATH
# Solution: Explicitly ensure SDKMAN tools are in PATH after everything loads

if [[ -n "$HADOOP_HOME" && -d "$HADOOP_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$HADOOP_HOME/bin:"* ]] && export PATH="$HADOOP_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$HADOOP_HOME/sbin:"* ]] && export PATH="$HADOOP_HOME/sbin:$PATH"
fi

if [[ -n "$SPARK_HOME" && -d "$SPARK_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$SPARK_HOME/bin:"* ]] && export PATH="$SPARK_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$SPARK_HOME/sbin:"* ]] && export PATH="$SPARK_HOME/sbin:$PATH"
fi

# Rehash command table after PATH changes
rehash

# Help
help() {
    echo "🚀 ZSH Quick Reference"
    echo "===================="
    echo ""
    echo "🐍 Python:"
    echo "  py_env_switch [env]    - Switch Python environment"
    echo "  python_status          - Show current environment"
    echo "  ds_project_init <name> - Create data science project"
    echo ""
    echo "⚡ Spark:"
    echo "  spark_start            - Start Spark cluster"
    echo "  spark_stop             - Stop cluster"
    echo "  spark_status           - Show status"
    echo "  smart_spark_submit <file> - Submit job (auto-detects cluster)"
    echo "  spark_yarn_submit <file> - Submit to YARN"
    echo "  pyspark_shell          - Interactive PySpark"
    echo ""
    echo "🐘 Hadoop:"
    echo "  start_hadoop           - Start HDFS + YARN"
    echo "  stop_hadoop            - Stop services"
    echo "  hadoop_status          - Show status"
    echo "  yarn_application_list  - List YARN apps"
    echo "  hdfs_ls [path]         - List HDFS files"
    echo ""
    echo "🐳 Docker:"
    echo "  docker_status          - System status"
    echo "  docker_cleanup         - Remove stopped containers"
    echo "  docker_shell <container> - Shell into container"
    echo "  docker_logs <container> - View logs"
    echo ""
    echo "🗄️  Database:"
    echo "  pg_connect [db]        - Connect to PostgreSQL"
    echo "  pg_test_connection     - Test connection"
    echo "  setup_postgres_credentials - Setup passwords"
    echo ""
    echo "🔐 Credentials:"
    echo "  get_credential <service> <user> - Retrieve from 1Password/Keychain"
    echo "  store_credential <service> <user> <pass> - Store securely"
    echo "  ga_store_service_account <file.json> - Store GA credentials"
    echo ""
    echo "🔐 Secrets:"
    echo "  secrets_status          - Show secrets loader status"
    echo "  secrets_edit            - Edit secrets.env (chmod 600)"
    echo "  secrets_init            - Create secrets.env from example"
    echo "  secrets_init_map        - Create secrets.1p from example"
    echo "  secrets_init_profile    - Interactive profile setup"
    echo "  secrets_profile_switch  - Set profile (persists) and reload"
    echo "  secrets_validate_setup  - Validate 1Password setup"
    echo "  secrets_profiles        - List profiles and colors"
    echo "  secrets_bootstrap_from_1p - Pull secrets files from 1Password"
    echo "  secrets_sync_to_1p      - Sync secrets.env to 1Password"
    echo "  secrets_pull_from_1p    - Pull secrets.env from 1Password"
    echo "  op_accounts_edit        - Edit 1Password account aliases"
    echo "  op_accounts_set_alias   - Set alias in op-accounts.env"
    echo "  op_accounts_seed        - Prompt to seed aliases from op CLI"
    echo "  op_verify_accounts      - Sign in + verify secrets per alias"
    echo "  op_set_default          - Set default 1Password account/vault"
    echo "  op_list_accounts_vaults - List accounts and vaults"
    echo "  op_list_items           - List items in account/vault"
    echo "  op_signin_account       - Sign in to an account alias"
    echo "  op_signin_all           - Sign in to all account aliases"
    echo "  op_signin_account_uuid  - Sign in using alias UUID"
    echo "  op_set_default_alias    - Set default using alias"
    echo "  secrets_rsync_to_host   - Rsync secrets files to host"
    echo "  secrets_rsync_from_host - Rsync secrets files from host"
    echo "  secrets_rsync_to_cyberpower   - Rsync secrets to cyberpower"
    echo "  secrets_rsync_from_cyberpower - Rsync secrets from cyberpower"
    echo "  secrets_rsync_verify    - Verify secrets files locally/remote"
    echo ""
    echo "🩺 Diagnostics:"
    echo "  icloud_status           - macOS-only iCloud status"
    echo "  icloud_preflight        - macOS-only iCloud preflight"
    echo "  dropbox_status          - macOS-only Dropbox status"
    echo "  dropbox_restart         - macOS-only Dropbox restart"
    echo "  linux_system_status     - Linux-only system overview"
    echo "  data_platform_health    - Spark/Hadoop/YARN health suite"
    echo "  spark_health            - Spark master/worker health"
    echo "  hadoop_health           - HDFS/YARN health overview"
    echo "  yarn_health             - YARN health overview"
    echo ""
    echo "📦 Backup:"
    echo "  backup ['message']     - Commit and push to GitHub"
    echo "  pushmain               - Quick push"
    echo "  sync                   - Sync repository"
    echo ""
    echo "🛠️  Utilities:"
    echo "  zshconfig              - Edit zsh configuration"
    echo "  zshreboot              - Start a fresh shell"
    echo "  zshreload              - Alias for zshreboot"
    echo "  is_online              - Check internet (used by Spark)"
    echo "  mkcd <dir>             - Create and cd"
    echo "  extract <file>         - Universal archive extraction"
    echo "  path_clean             - Remove duplicate PATH entries"
    echo ""
    echo "📚 Full docs: $ZSH_CONFIG_DIR/README.md"
}

# Show loaded modules
modules() {
    echo "📦 Loaded Modules"
    echo "================"
    echo "✅ utils       - Core utilities (is_online, mkcd, extract)"
    echo "✅ python      - Python/pyenv management"
    echo "✅ spark       - Spark cluster operations"
    echo "✅ hadoop      - Hadoop/YARN management"
    echo "✅ docker      - Container management"
    echo "✅ database    - PostgreSQL connections"
    echo "✅ credentials - Secure credential storage"
    echo "✅ secrets     - Local + 1Password secrets"
    echo "✅ system_diagnostics - iCloud/Dropbox/Linux diagnostics"
    echo "✅ backup      - Git self-backup system"
}

# Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Profile-aware palette (banner + prompt accents)
typeset -gA ZSH_PROFILE_CONFIGS
ZSH_PROFILE_CONFIGS=(
    dev "Development workstation (green)"
    staging "Staging environment (yellow)"
    prod "Production environment (red)"
    laptop "Personal laptop (cyan)"
    cyberpower "Cyberpower host (dark green)"
)
typeset -gA ZSH_PROFILE_COLORS
ZSH_PROFILE_COLORS=(
    dev "32;1 32"
    staging "33;1 33"
    prod "31;1 31"
    laptop "36;1 36"
    cyberpower "32;2 32"
    default "35;1 35"
)
typeset -ga ZSH_PROFILE_ORDER
ZSH_PROFILE_ORDER=(dev staging prod laptop cyberpower)

_profile_palette() {
    local profile="${ZSH_ENV_PROFILE:-}"
    if typeset -p ZSH_PROFILE_COLORS >/dev/null 2>&1; then
        if [[ -n "$profile" && -n "${ZSH_PROFILE_COLORS[$profile]-}" ]]; then
            echo "${ZSH_PROFILE_COLORS[$profile]}"
            return 0
        fi
        if [[ -n "${ZSH_PROFILE_COLORS[default]-}" ]]; then
            echo "${ZSH_PROFILE_COLORS[default]}"
            return 0
        fi
    fi
    echo "35;1 35"
}

apply_profile_theme() {
    local palette header accent
    palette="$(_profile_palette)"
    header="${palette%% *}"
    accent="${palette##* }"
    export ZSH_PROFILE_HEADER_COLOR="$header"
    export ZSH_PROFILE_ACCENT_COLOR="$accent"

    if command -v p10k >/dev/null 2>&1; then
        typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND="$accent"
        typeset -g POWERLEVEL9K_DIR_FOREGROUND="$accent"
        typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND="$accent"
        p10k reload >/dev/null 2>&1 || true
    fi
}

# Welcome message - show useful context
zsh_status_banner() {
    local header_color="${ZSH_PROFILE_HEADER_COLOR:-34}"
    local accent_color="${ZSH_PROFILE_ACCENT_COLOR:-36}"
    local reset_color="0"
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"
    printf "\033[%sm%s\033[%sm\n" "$header_color" "🚀 ZSH Configuration Loaded" "$reset_color"
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"

    # Python environment
    local pyenv_version="system"
    if command -v pyenv >/dev/null 2>&1; then
        pyenv_version="$(pyenv version-name 2>/dev/null || echo 'system')"
    fi
    local py_bin="python"
    command -v python >/dev/null 2>&1 || py_bin="python3"
    local py_version="not found"
    if command -v "$py_bin" >/dev/null 2>&1; then
        py_version="$("$py_bin" --version 2>&1 | head -1)"
    fi
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🐍 Python:" "$reset_color" "$pyenv_version (${py_version})"

    # Machine profile (env/role/host)
    if command -v machine_profile >/dev/null 2>&1; then
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🧭 Profile:" "$reset_color" "$(machine_profile)"
    fi

    # Spark / Hadoop / Java (lightweight checks only)
    local spark_state="missing"
    local hadoop_state="missing"
    local scala_state="missing"
    if command -v spark-submit >/dev/null 2>&1 || [[ -n "${SPARK_HOME:-}" ]]; then
        spark_state="available"
    fi
    if command -v hadoop >/dev/null 2>&1 || [[ -n "${HADOOP_HOME:-}" ]]; then
        hadoop_state="available"
    fi
    if command -v scala >/dev/null 2>&1; then
        scala_state="available"
    fi
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "⚡ Spark:" "$reset_color" "$spark_state  🐘 Hadoop: $hadoop_state  🧠 Scala: $scala_state"
    [[ -n "${JAVA_HOME:-}" ]] && printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "☕ Java:" "$reset_color" "$JAVA_HOME"

    # Current directory
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "📁 Location:" "$reset_color" "$(pwd)"

    # Key services status
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🐳 Docker:" "$reset_color" "running"
    fi

    # Quick tips
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$accent_color" "💡 Quick Commands:" "$reset_color"
    echo "   help          - Show all available commands"
    echo "   modules       - List loaded modules"
    echo "   python_status - Check Python environment"
    echo "   spark_status  - Check Spark status"
    echo "   hadoop_status - Check Hadoop status"
    echo "   data_platform_health - Spark/Hadoop/YARN health"
    echo "   backup        - Commit and push config to GitHub"
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"
    echo ""
}

if [[ -o interactive ]]; then
    apply_profile_theme
    zsh_status_banner
fi

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
if [[ "$OSTYPE" == "darwin"* && -d "/Users/dheerajchand/.rd/bin" ]]; then
    export PATH="/Users/dheerajchand/.rd/bin:$PATH"
fi
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
