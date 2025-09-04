#!/usr/bin/env zsh

# =====================================================
# MODULAR HELP SYSTEM
# =====================================================
# 
# Comprehensive help system for the modular zsh configuration
# Provides documentation for all modules, functions, and features
# Integrates with the new modular architecture
# =====================================================

export HELP_MODULE_LOADED=true
export HELP_MODULE_VERSION="2.0.0"

# Help system colors
readonly HELP_COLOR_HEADER='\033[1;36m'    # Cyan bold
readonly HELP_COLOR_MODULE='\033[1;34m'     # Blue bold  
readonly HELP_COLOR_FUNCTION='\033[1;32m'   # Green bold
readonly HELP_COLOR_EXAMPLE='\033[0;33m'    # Yellow
readonly HELP_COLOR_RESET='\033[0m'         # Reset

# =====================================================
# MAIN HELP INTERFACE
# =====================================================

zsh_help() {
    # Main help function for the modular zsh configuration system
    #
    # Provides comprehensive assistance for all modules and functions.
    # Updated for the new modular architecture.
    #
    # Args:
    #     module (str, optional): Module name or help topic
    #                           Valid: core, credentials, database, jetbrains,
    #                                 modules, status, quick-start, all
    #     subcommand (str, optional): Specific function or topic within module
    #
    # Examples:
    #     zsh_help                    # Main help overview
    #     zsh_help modules            # List all modules
    #     zsh_help core               # Core module help
    #     zsh_help credentials        # Credential management help
    #     zsh_help database           # Database configuration help
    #     zsh_help jetbrains          # JetBrains IDE help
    #     zsh_help status             # System status
    #     zsh_help quick-start        # Quick start guide
    local module="${1:-all}"
    local subcommand="${2:-}"
    
    case "$module" in
        "all"|"")
            show_main_help
            ;;
        "modules"|"list")
            show_modules_help
            ;;
        "status"|"info")
            show_system_status_help
            ;;
        "quick-start"|"quickstart"|"start")
            show_quick_start_help
            ;;
        "core")
            show_core_help "$subcommand"
            ;;
        "credentials"|"creds")
            show_credentials_help "$subcommand"
            ;;
        "database"|"db")
            show_database_help "$subcommand"
            ;;
        "jetbrains"|"jb"|"ide")
            show_jetbrains_help "$subcommand"
            ;;
        "modular"|"architecture")
            show_architecture_help
            ;;
        "search")
            search_help "$subcommand"
            ;;
        *)
            echo "${HELP_COLOR_HEADER}❓ Unknown help topic: $module${HELP_COLOR_RESET}"
            echo "Try: zsh_help modules (to see available topics)"
            return 1
            ;;
    esac
}

# =====================================================
# MAIN HELP DISPLAY
# =====================================================

show_main_help() {
    cat << EOF
${HELP_COLOR_HEADER}🚀 Enhanced Modular ZSH Configuration System v${MODULAR_ZSHRC_VERSION:-1.0.0}${HELP_COLOR_RESET}
================================================================

${HELP_COLOR_MODULE}📦 MODULAR ARCHITECTURE${HELP_COLOR_RESET}
Your shell configuration is now organized into focused modules:

${HELP_COLOR_FUNCTION}Core Modules (Always Loaded):${HELP_COLOR_RESET}
  🏗️  core          - Essential shell settings, aliases, utilities
  🔐 credentials   - Secure credential management (1Password, Keychain, env)
  🗄️  database      - Database connections (PostgreSQL, MySQL, Snowflake)
  🛠️  jetbrains     - JetBrains IDE integration (PyCharm, IntelliJ, etc.)

${HELP_COLOR_FUNCTION}Optional Modules (Conditionally Loaded):${HELP_COLOR_RESET}
  ⚡ spark         - Apache Spark configuration
  🐘 hadoop        - Hadoop/YARN setup
  🐳 docker        - Docker integration
  💾 backup        - Backup system integration

${HELP_COLOR_MODULE}🎯 QUICK COMMANDS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}zsh_help quick-start${HELP_COLOR_RESET}      # Get started quickly
  ${HELP_COLOR_EXAMPLE}zsh_help modules${HELP_COLOR_RESET}          # List all modules
  ${HELP_COLOR_EXAMPLE}zsh_help status${HELP_COLOR_RESET}           # System status
  ${HELP_COLOR_EXAMPLE}modular_zsh_status${HELP_COLOR_RESET}        # Detailed system status

${HELP_COLOR_MODULE}🔍 MODULE-SPECIFIC HELP${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}zsh_help core${HELP_COLOR_RESET}             # Core shell functionality
  ${HELP_COLOR_EXAMPLE}zsh_help credentials${HELP_COLOR_RESET}      # Credential management
  ${HELP_COLOR_EXAMPLE}zsh_help database${HELP_COLOR_RESET}         # Database configuration
  ${HELP_COLOR_EXAMPLE}zsh_help jetbrains${HELP_COLOR_RESET}        # IDE integration

${HELP_COLOR_MODULE}🛠️  SYSTEM MANAGEMENT${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}zsh-status${HELP_COLOR_RESET}                # Show module status
  ${HELP_COLOR_EXAMPLE}zsh-reload${HELP_COLOR_RESET}                # Reload configuration
  ${HELP_COLOR_EXAMPLE}zsh-verbose${HELP_COLOR_RESET}               # Enable verbose loading

${HELP_COLOR_MODULE}💡 WHAT'S NEW${HELP_COLOR_RESET}
• 87% reduction in main config file size (2400+ → 300 lines)
• Dynamic loading - only loads what you have installed
• Secure credential management with multiple backends
• Fixed PyCharm file dialog issues
• Better error handling and diagnostics

Type ${HELP_COLOR_EXAMPLE}zsh_help <topic>${HELP_COLOR_RESET} for detailed help on any topic.
EOF
}

show_modules_help() {
    cat << EOF
${HELP_COLOR_HEADER}📦 Available Configuration Modules${HELP_COLOR_RESET}
========================================

${HELP_COLOR_MODULE}✅ LOADED MODULES${HELP_COLOR_RESET}
EOF
    
    # Show loaded modules from the global tracking
    for module module_status in ${(kv)LOADED_MODULES}; do
        case "$module_status" in
            "success")
                echo "  ${HELP_COLOR_FUNCTION}✅ $module${HELP_COLOR_RESET} - Loaded successfully"
                ;;
            "error")
                echo "  ${HELP_COLOR_EXAMPLE}❌ $module${HELP_COLOR_RESET} - Failed to load"
                ;;
        esac
    done
    
    cat << EOF

${HELP_COLOR_MODULE}📄 MODULE DESCRIPTIONS${HELP_COLOR_RESET}

${HELP_COLOR_FUNCTION}🏗️  core${HELP_COLOR_RESET}
   Essential shell configuration, aliases, and utility functions
   ${HELP_COLOR_EXAMPLE}zsh_help core${HELP_COLOR_RESET} - View detailed help

${HELP_COLOR_FUNCTION}🔐 credentials${HELP_COLOR_RESET}
   Multi-backend credential management (1Password, Keychain, environment)
   ${HELP_COLOR_EXAMPLE}zsh_help credentials${HELP_COLOR_RESET} - View credential help
   ${HELP_COLOR_EXAMPLE}creds-status${HELP_COLOR_RESET} - Check credential backends

${HELP_COLOR_FUNCTION}🗄️  database${HELP_COLOR_RESET}
   Database connection management with secure credential integration
   ${HELP_COLOR_EXAMPLE}zsh_help database${HELP_COLOR_RESET} - View database help
   ${HELP_COLOR_EXAMPLE}db-status${HELP_COLOR_RESET} - Check database configuration

${HELP_COLOR_FUNCTION}🛠️  jetbrains${HELP_COLOR_RESET}
   JetBrains IDE integration with project auto-detection
   ${HELP_COLOR_EXAMPLE}zsh_help jetbrains${HELP_COLOR_RESET} - View IDE help
   ${HELP_COLOR_EXAMPLE}jb-status${HELP_COLOR_RESET} - Check JetBrains tools

${HELP_COLOR_MODULE}💡 CREATING CUSTOM MODULES${HELP_COLOR_RESET}
Place custom modules in: ${HELP_COLOR_EXAMPLE}~/.config/zsh/config/my-module.zsh${HELP_COLOR_RESET}
They will be automatically detected and can be loaded with:
${HELP_COLOR_EXAMPLE}load_config_module "my-module"${HELP_COLOR_RESET}
EOF
}

show_quick_start_help() {
    cat << EOF
${HELP_COLOR_HEADER}🚀 Quick Start Guide${HELP_COLOR_RESET}
=====================

${HELP_COLOR_MODULE}1. CHECK SYSTEM STATUS${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}modular_zsh_status${HELP_COLOR_RESET}           # See what's loaded
   ${HELP_COLOR_EXAMPLE}creds-status${HELP_COLOR_RESET}                 # Check credential backends
   ${HELP_COLOR_EXAMPLE}db-status${HELP_COLOR_RESET}                    # Check database config

${HELP_COLOR_MODULE}2. CORE FUNCTIONALITY${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}ll${HELP_COLOR_RESET}                           # Enhanced ls
   ${HELP_COLOR_EXAMPLE}mkcd new_dir${HELP_COLOR_RESET}                 # Create and enter directory
   ${HELP_COLOR_EXAMPLE}findtext "search term"${HELP_COLOR_RESET}       # Search in files
   ${HELP_COLOR_EXAMPLE}extract archive.tar.gz${HELP_COLOR_RESET}       # Universal extraction

${HELP_COLOR_MODULE}3. DATABASE CONNECTIONS${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}pg${HELP_COLOR_RESET}                           # Quick PostgreSQL connection
   ${HELP_COLOR_EXAMPLE}pgtest${HELP_COLOR_RESET}                       # Test PostgreSQL connection
   ${HELP_COLOR_EXAMPLE}pgsetup${HELP_COLOR_RESET}                      # Interactive PostgreSQL setup

${HELP_COLOR_MODULE}4. JETBRAINS IDES${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}py project_dir${HELP_COLOR_RESET}               # Open in PyCharm
   ${HELP_COLOR_EXAMPLE}idea project_dir${HELP_COLOR_RESET}             # Open in IntelliJ
   ${HELP_COLOR_EXAMPLE}open_project .${HELP_COLOR_RESET}               # Auto-detect IDE for current project

${HELP_COLOR_MODULE}5. CREDENTIAL MANAGEMENT${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}get_credential postgres dheerajchand${HELP_COLOR_RESET}  # Get password
   ${HELP_COLOR_EXAMPLE}store_credential service user pass${HELP_COLOR_RESET}     # Store securely

${HELP_COLOR_MODULE}6. TROUBLESHOOTING${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}zsh-reload${HELP_COLOR_RESET}                   # Reload configuration
   ${HELP_COLOR_EXAMPLE}zsh-verbose${HELP_COLOR_RESET}                  # Reload with verbose output
   ${HELP_COLOR_EXAMPLE}jetbrains_diagnose_env${HELP_COLOR_RESET}       # Diagnose IDE issues

${HELP_COLOR_MODULE}💡 GETTING MORE HELP${HELP_COLOR_RESET}
   ${HELP_COLOR_EXAMPLE}zsh_help modules${HELP_COLOR_RESET}             # See all modules
   ${HELP_COLOR_EXAMPLE}zsh_help <module>${HELP_COLOR_RESET}            # Module-specific help
   ${HELP_COLOR_EXAMPLE}zsh_help search <term>${HELP_COLOR_RESET}       # Search help topics
EOF
}

# =====================================================
# MODULE-SPECIFIC HELP
# =====================================================

show_core_help() {
    cat << EOF
${HELP_COLOR_HEADER}🏗️  Core Module Help${HELP_COLOR_RESET}
===================

${HELP_COLOR_MODULE}SHELL CONFIGURATION${HELP_COLOR_RESET}
• Case-sensitive completion enabled
• Auto-correction disabled (better for technical terms)
• Editor set to Zed (GUI) and nvim (terminal)

${HELP_COLOR_MODULE}KEY ALIASES${HELP_COLOR_RESET}
${HELP_COLOR_FUNCTION}Navigation:${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}..${HELP_COLOR_RESET}, ${HELP_COLOR_EXAMPLE}...${HELP_COLOR_RESET}, ${HELP_COLOR_EXAMPLE}....${HELP_COLOR_RESET}              # Go up directories
  ${HELP_COLOR_EXAMPLE}ll${HELP_COLOR_RESET}, ${HELP_COLOR_EXAMPLE}la${HELP_COLOR_RESET}, ${HELP_COLOR_EXAMPLE}l${HELP_COLOR_RESET}                 # Enhanced ls variations

${HELP_COLOR_FUNCTION}Git Shortcuts:${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}gs${HELP_COLOR_RESET}                          # git status
  ${HELP_COLOR_EXAMPLE}ga <file>${HELP_COLOR_RESET}                   # git add
  ${HELP_COLOR_EXAMPLE}gc -m "message"${HELP_COLOR_RESET}             # git commit
  ${HELP_COLOR_EXAMPLE}gl${HELP_COLOR_RESET}                          # git log --oneline

${HELP_COLOR_MODULE}UTILITY FUNCTIONS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}mkcd directory${HELP_COLOR_RESET}              # Create and enter directory
  ${HELP_COLOR_EXAMPLE}extract file.tar.gz${HELP_COLOR_RESET}         # Universal extraction
  ${HELP_COLOR_EXAMPLE}findtext "pattern" [path]${HELP_COLOR_RESET}   # Search text in files
  ${HELP_COLOR_EXAMPLE}is_online${HELP_COLOR_RESET}                   # Check internet connection
  ${HELP_COLOR_EXAMPLE}command_exists cmd${HELP_COLOR_RESET}          # Check if command exists
  ${HELP_COLOR_EXAMPLE}path_add /new/path${HELP_COLOR_RESET}          # Add to PATH safely

${HELP_COLOR_MODULE}SYSTEM INFO${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}system_info${HELP_COLOR_RESET}                 # Display system information
  ${HELP_COLOR_EXAMPLE}shell_startup_time${HELP_COLOR_RESET}          # Measure startup performance
  ${HELP_COLOR_EXAMPLE}list_modules${HELP_COLOR_RESET}                # Show available modules

${HELP_COLOR_MODULE}MODULE MANAGEMENT${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}load_module name${HELP_COLOR_RESET}            # Load a configuration module
  ${HELP_COLOR_EXAMPLE}list_modules${HELP_COLOR_RESET}                # List available modules
EOF
}

show_credentials_help() {
    cat << EOF
${HELP_COLOR_HEADER}🔐 Credentials Module Help${HELP_COLOR_RESET}
========================

${HELP_COLOR_MODULE}SUPPORTED BACKENDS${HELP_COLOR_RESET}
  ${HELP_COLOR_FUNCTION}✅ Environment Variables${HELP_COLOR_RESET}   - Your current workflow (maintained)
  ${HELP_COLOR_FUNCTION}✅ 1Password CLI${HELP_COLOR_RESET}           - Secure credential storage
  ${HELP_COLOR_FUNCTION}✅ Apple Keychain${HELP_COLOR_RESET}          - macOS system keychain
  ${HELP_COLOR_FUNCTION}✅ Interactive Prompts${HELP_COLOR_RESET}     - Fallback option

${HELP_COLOR_MODULE}CREDENTIAL PRIORITY${HELP_COLOR_RESET}
1. Environment variables (preserves current workflow)
2. 1Password CLI (if signed in)
3. Apple Keychain (macOS)
4. Interactive prompt (fallback)

${HELP_COLOR_MODULE}KEY FUNCTIONS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}creds-status${HELP_COLOR_RESET}                       # Show backend availability
  ${HELP_COLOR_EXAMPLE}get_credential service user [field]${HELP_COLOR_RESET}   # Retrieve credential
  ${HELP_COLOR_EXAMPLE}store_credential service user pass${HELP_COLOR_RESET}     # Store securely
  ${HELP_COLOR_EXAMPLE}set_credential_backend env-first${HELP_COLOR_RESET}       # Change backend priority

${HELP_COLOR_MODULE}DATABASE HELPERS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}get_postgres_password${HELP_COLOR_RESET}               # Get PostgreSQL password
  ${HELP_COLOR_EXAMPLE}get_snowflake_password${HELP_COLOR_RESET}              # Get Snowflake password
  ${HELP_COLOR_EXAMPLE}get_mysql_password${HELP_COLOR_RESET}                  # Get MySQL password

${HELP_COLOR_MODULE}BACKEND OPTIONS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}env-first${HELP_COLOR_RESET}      - Environment variables first (current)
  ${HELP_COLOR_EXAMPLE}1password-first${HELP_COLOR_RESET} - 1Password first, env fallback
  ${HELP_COLOR_EXAMPLE}apple-first${HELP_COLOR_RESET}    - Apple Keychain first, env fallback
  ${HELP_COLOR_EXAMPLE}env-only${HELP_COLOR_RESET}       - Environment variables only

${HELP_COLOR_MODULE}EXAMPLES${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}# Check what backends are available${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}creds-status${HELP_COLOR_RESET}

  ${HELP_COLOR_EXAMPLE}# Get a password (tries env vars first)${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}PGPASSWORD=\$(get_credential postgres dheerajchand)${HELP_COLOR_RESET}

  ${HELP_COLOR_EXAMPLE}# Store password securely in 1Password/Keychain${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}store_credential myservice myuser mypassword${HELP_COLOR_RESET}
EOF
}

show_database_help() {
    cat << EOF
${HELP_COLOR_HEADER}🗄️  Database Module Help${HELP_COLOR_RESET}
======================

${HELP_COLOR_MODULE}SUPPORTED DATABASES${HELP_COLOR_RESET}
  ${HELP_COLOR_FUNCTION}🐘 PostgreSQL${HELP_COLOR_RESET}    - Full integration with credential system
  ${HELP_COLOR_FUNCTION}🐬 MySQL${HELP_COLOR_RESET}         - Connection helpers and testing
  ${HELP_COLOR_FUNCTION}❄️  Snowflake${HELP_COLOR_RESET}     - Enterprise data warehouse
  ${HELP_COLOR_FUNCTION}🌍 GeoDjango${HELP_COLOR_RESET}     - PostGIS template database

${HELP_COLOR_MODULE}POSTGRESQL${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}pg${HELP_COLOR_RESET}                                 # Quick connection
  ${HELP_COLOR_EXAMPLE}pgtest${HELP_COLOR_RESET}                             # Test connection
  ${HELP_COLOR_EXAMPLE}pgsetup${HELP_COLOR_RESET}                            # Interactive setup
  ${HELP_COLOR_EXAMPLE}setup_postgres_credentials${HELP_COLOR_RESET}         # Configure credentials

${HELP_COLOR_MODULE}MYSQL${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}mytest${HELP_COLOR_RESET}                             # Quick MySQL connection
  ${HELP_COLOR_EXAMPLE}mysetup${HELP_COLOR_RESET}                            # MySQL credential setup

${HELP_COLOR_MODULE}SNOWFLAKE${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}sfsetup${HELP_COLOR_RESET}                            # Interactive Snowflake setup
  ${HELP_COLOR_EXAMPLE}setup_snowflake_credentials --interactive${HELP_COLOR_RESET}

${HELP_COLOR_MODULE}GENERAL COMMANDS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}db-status${HELP_COLOR_RESET}                          # Show all database configurations
  ${HELP_COLOR_EXAMPLE}db-test${HELP_COLOR_RESET}                            # Test all database connections
  ${HELP_COLOR_EXAMPLE}db-migrate${HELP_COLOR_RESET}                         # Migrate to secure credentials

${HELP_COLOR_MODULE}ENVIRONMENT VARIABLES${HELP_COLOR_RESET}
${HELP_COLOR_FUNCTION}PostgreSQL:${HELP_COLOR_RESET}
  PGHOST, PGUSER, PGPORT, PGDATABASE - Connection settings
  PGPASSWORD - Retrieved from credential system

${HELP_COLOR_FUNCTION}MySQL:${HELP_COLOR_RESET}
  MYSQL_HOST, MYSQL_USER, MYSQL_PORT - Connection settings
  MYSQL_PASSWORD - Retrieved from credential system

${HELP_COLOR_MODULE}SECURITY FEATURES${HELP_COLOR_RESET}
• No plaintext passwords in configuration files
• Integration with secure credential backends
• Migration helpers for existing plaintext credentials
• Backward compatibility with environment variables
EOF
}

show_jetbrains_help() {
    cat << EOF
${HELP_COLOR_HEADER}🛠️  JetBrains Module Help${HELP_COLOR_RESET}
========================

${HELP_COLOR_MODULE}SUPPORTED IDES${HELP_COLOR_RESET}
  ${HELP_COLOR_FUNCTION}🐍 PyCharm${HELP_COLOR_RESET}        - Python development
  ${HELP_COLOR_FUNCTION}💡 IntelliJ IDEA${HELP_COLOR_RESET}  - Java/Scala development  
  ${HELP_COLOR_FUNCTION}🗄️  DataGrip${HELP_COLOR_RESET}      - Database management
  ${HELP_COLOR_FUNCTION}📊 DataSpell${HELP_COLOR_RESET}     - Data science
  ${HELP_COLOR_FUNCTION}🌐 WebStorm${HELP_COLOR_RESET}      - Web development

${HELP_COLOR_MODULE}QUICK SHORTCUTS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}py [project]${HELP_COLOR_RESET}                      # Open in PyCharm
  ${HELP_COLOR_EXAMPLE}idea [project]${HELP_COLOR_RESET}                    # Open in IntelliJ IDEA
  ${HELP_COLOR_EXAMPLE}ws [project]${HELP_COLOR_RESET}                      # Open in WebStorm
  ${HELP_COLOR_EXAMPLE}dg${HELP_COLOR_RESET}                                # Launch DataGrip
  ${HELP_COLOR_EXAMPLE}ds [project]${HELP_COLOR_RESET}                      # Open in DataSpell

${HELP_COLOR_MODULE}SMART PROJECT DETECTION${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}open_project .${HELP_COLOR_RESET}                    # Auto-detect project type and open in right IDE
  ${HELP_COLOR_EXAMPLE}project ~/my_app${HELP_COLOR_RESET}                  # Same as open_project

${HELP_COLOR_MODULE}SYSTEM STATUS${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}jb-status${HELP_COLOR_RESET}                         # Show JetBrains tool availability
  ${HELP_COLOR_EXAMPLE}jb-diagnose${HELP_COLOR_RESET}                       # Diagnose environment issues

${HELP_COLOR_MODULE}TROUBLESHOOTING${HELP_COLOR_RESET}
  ${HELP_COLOR_EXAMPLE}jb-clean${HELP_COLOR_RESET}                          # Launch PyCharm with clean environment
  ${HELP_COLOR_EXAMPLE}pycharm_clean_launch [project]${HELP_COLOR_RESET}    # Debug file dialog issues
  ${HELP_COLOR_EXAMPLE}jetbrains_diagnose_env${HELP_COLOR_RESET}            # Check for environment conflicts

${HELP_COLOR_MODULE}AUTO-DETECTION LOGIC${HELP_COLOR_RESET}
• Python projects (requirements.txt, setup.py) → PyCharm
• Data science (notebooks/, pandas/jupyter deps) → DataSpell  
• Java/Scala (pom.xml, build.gradle, build.sbt) → IntelliJ IDEA
• Web projects (package.json, angular.json) → WebStorm
• Default/mixed projects → PyCharm

${HELP_COLOR_MODULE}FILE DIALOG FIX${HELP_COLOR_RESET}
✅ Fixed PyCharm file dialog hanging issues by removing LD_LIBRARY_PATH conflicts
EOF
}

show_architecture_help() {
    cat << EOF
${HELP_COLOR_HEADER}🏗️  Modular Architecture${HELP_COLOR_RESET}
========================

${HELP_COLOR_MODULE}BEFORE vs AFTER${HELP_COLOR_RESET}
${HELP_COLOR_FUNCTION}Before:${HELP_COLOR_RESET} Single monolithic file (2400+ lines)
${HELP_COLOR_FUNCTION}After:${HELP_COLOR_RESET}  Modular system (300 line loader + focused modules)
${HELP_COLOR_FUNCTION}Improvement:${HELP_COLOR_RESET} 87% reduction in main file size

${HELP_COLOR_MODULE}DIRECTORY STRUCTURE${HELP_COLOR_RESET}
~/.config/zsh/
├── zshrc                    # Main loader (~300 lines)
├── zshrc.original          # Backup of old system
├── config/                 # New modular configuration
│   ├── core.zsh           # Essential shell setup
│   ├── credentials.zsh    # Multi-backend credentials
│   ├── database.zsh       # Database connections
│   ├── jetbrains.zsh      # IDE integration
│   └── help.zsh           # This help system
└── functions/              # Function libraries

${HELP_COLOR_MODULE}LOADING STRATEGY${HELP_COLOR_RESET}
1. ${HELP_COLOR_FUNCTION}Core modules${HELP_COLOR_RESET} (always loaded): core, credentials, database, jetbrains
2. ${HELP_COLOR_FUNCTION}Conditional modules${HELP_COLOR_RESET} (only if tools available): spark, hadoop, docker
3. ${HELP_COLOR_FUNCTION}Legacy modules${HELP_COLOR_RESET} (temporary): utilities.zsh, help-module.zsh
4. ${HELP_COLOR_FUNCTION}User modules${HELP_COLOR_RESET} (optional): user.zsh, local.zsh

${HELP_COLOR_MODULE}KEY BENEFITS${HELP_COLOR_RESET}
• 🚀 Faster startup (conditional loading)
• 🛠️  Easier maintenance (focused modules)  
• 🔒 Better security (credential management)
• 🧪 Improved testing (isolated components)
• 📦 Extensible (easy to add modules)

${HELP_COLOR_MODULE}MODULE STATUS TRACKING${HELP_COLOR_RESET}
Each module load is tracked in LOADED_MODULES array:
• "success" - Module loaded without errors
• "error" - Module failed to load
• "missing" - Module file not found (optional modules)

${HELP_COLOR_MODULE}PERFORMANCE${HELP_COLOR_RESET}
Set ${HELP_COLOR_EXAMPLE}ZSH_STARTUP_TIMING=true${HELP_COLOR_RESET} to see startup time metrics
EOF
}

# =====================================================
# SEARCH FUNCTIONALITY
# =====================================================

search_help() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo "${HELP_COLOR_HEADER}🔍 Help Search${HELP_COLOR_RESET}"
        echo "Usage: zsh_help search <term>"
        echo ""
        echo "Examples:"
        echo "  ${HELP_COLOR_EXAMPLE}zsh_help search password${HELP_COLOR_RESET}    # Find credential-related help"
        echo "  ${HELP_COLOR_EXAMPLE}zsh_help search database${HELP_COLOR_RESET}    # Find database-related help"
        echo "  ${HELP_COLOR_EXAMPLE}zsh_help search pycharm${HELP_COLOR_RESET}     # Find PyCharm-related help"
        return 1
    fi
    
    echo "${HELP_COLOR_HEADER}🔍 Search results for: $search_term${HELP_COLOR_RESET}"
    echo ""
    
    # Search through help content
    local found=0
    
    case "$search_term" in
        *password*|*credential*|*auth*)
            echo "${HELP_COLOR_FUNCTION}📋 Credential Management:${HELP_COLOR_RESET} zsh_help credentials"
            echo "${HELP_COLOR_FUNCTION}📋 Database Passwords:${HELP_COLOR_RESET} zsh_help database"
            ((found++))
            ;;
    esac
    
    case "$search_term" in
        *database*|*postgres*|*mysql*|*sql*)
            echo "${HELP_COLOR_FUNCTION}🗄️  Database Help:${HELP_COLOR_RESET} zsh_help database"
            ((found++))
            ;;
    esac
    
    case "$search_term" in
        *pycharm*|*intellij*|*jetbrains*|*ide*)
            echo "${HELP_COLOR_FUNCTION}🛠️  JetBrains IDEs:${HELP_COLOR_RESET} zsh_help jetbrains"
            ((found++))
            ;;
    esac
    
    case "$search_term" in
        *module*|*config*|*load*)
            echo "${HELP_COLOR_FUNCTION}📦 Module System:${HELP_COLOR_RESET} zsh_help modules"
            echo "${HELP_COLOR_FUNCTION}🏗️  Architecture:${HELP_COLOR_RESET} zsh_help architecture"
            ((found++))
            ;;
    esac
    
    if [[ $found -eq 0 ]]; then
        echo "No specific help found for '$search_term'"
        echo "Try: ${HELP_COLOR_EXAMPLE}zsh_help modules${HELP_COLOR_RESET} to see all available topics"
    fi
}

show_system_status_help() {
    echo "${HELP_COLOR_HEADER}📊 System Status Commands${HELP_COLOR_RESET}"
    echo "=========================="
    echo ""
    echo "Use these commands to check your system status:"
    echo ""
    echo "${HELP_COLOR_FUNCTION}General System:${HELP_COLOR_RESET}"
    echo "  ${HELP_COLOR_EXAMPLE}modular_zsh_status${HELP_COLOR_RESET}        # Complete module status"
    echo "  ${HELP_COLOR_EXAMPLE}zsh-status${HELP_COLOR_RESET}                # Same as above (alias)"
    echo "  ${HELP_COLOR_EXAMPLE}system_info${HELP_COLOR_RESET}               # System information"
    echo ""
    echo "${HELP_COLOR_FUNCTION}Credentials:${HELP_COLOR_RESET}"
    echo "  ${HELP_COLOR_EXAMPLE}creds-status${HELP_COLOR_RESET}              # Credential backend status"
    echo ""
    echo "${HELP_COLOR_FUNCTION}Database:${HELP_COLOR_RESET}"
    echo "  ${HELP_COLOR_EXAMPLE}db-status${HELP_COLOR_RESET}                 # Database configuration status"
    echo "  ${HELP_COLOR_EXAMPLE}db-test${HELP_COLOR_RESET}                   # Test database connections"
    echo ""
    echo "${HELP_COLOR_FUNCTION}JetBrains:${HELP_COLOR_RESET}"
    echo "  ${HELP_COLOR_EXAMPLE}jb-status${HELP_COLOR_RESET}                 # JetBrains tools status"
    echo "  ${HELP_COLOR_EXAMPLE}jb-diagnose${HELP_COLOR_RESET}               # Environment diagnosis"
}

# =====================================================
# ALIASES & SHORTCUTS
# =====================================================

alias help='zsh_help'
alias h='zsh_help'
alias help-modules='zsh_help modules'
alias help-status='zsh_help status'
alias help-search='zsh_help search'

# =====================================================
# INITIALIZATION
# =====================================================

# Update legacy help function for backward compatibility
if ! command -v show_main_help >/dev/null 2>&1; then
    show_main_help() { zsh_help; }
fi