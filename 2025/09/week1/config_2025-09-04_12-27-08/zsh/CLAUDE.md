# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 MODULAR ARCHITECTURE (v2.0)

**MAJOR UPDATE**: This repository has been completely refactored from a monolithic 2400+ line zshrc to a clean modular system with 87% size reduction.

### Quick Status Check
```bash
# Check what's loaded and working
modular_zsh_status

# Get help on the new system  
zsh_help
```

## Commands

### New Modular System
```bash
# System status and management
modular_zsh_status          # Show module loading status
zsh-status                  # Alias for above
zsh-reload                  # Reload configuration
zsh-verbose                 # Reload with verbose output

# Module management
list_modules                # Show available modules
load_config_module name     # Load specific module
```

### Testing
```bash
# Run all tests (updated for modular system)
zsh run-tests.zsh

# Test specific modules
zsh run-tests.zsh --test "test_credentials"
zsh run-tests.zsh --test "test_database"

# Run with verbose output and coverage
zsh run-tests.zsh --verbose --coverage
```

### Help System (Completely Rewritten)
```bash
# New modular help system
zsh_help                    # Main help overview
zsh_help modules            # List all modules
zsh_help quick-start        # Get started quickly
zsh_help status             # System status commands

# Module-specific help
zsh_help core               # Core shell functionality
zsh_help credentials        # Credential management
zsh_help database           # Database configuration  
zsh_help jetbrains          # IDE integration

# Search functionality
zsh_help search password    # Find credential help
zsh_help search pycharm     # Find IDE help
```

### Credential Management (NEW)
```bash
# Check credential backends
creds-status

# Get credentials (tries env vars first, then secure storage)
get_credential postgres dheerajchand
get_postgres_password

# Store credentials securely
store_credential service user password

# Migration from plaintext
db-migrate
```

### Database Management (NEW)
```bash
# Database status and testing
db-status                   # Show all database configurations
db-test                     # Test all database connections

# Quick connections
pg                          # PostgreSQL
pgtest                      # Test PostgreSQL connection
pgsetup                     # Interactive PostgreSQL setup

# MySQL
mytest                      # MySQL connection
mysetup                     # MySQL setup

# Snowflake
sfsetup                     # Snowflake setup
```

### JetBrains IDE Integration (NEW)
```bash
# IDE shortcuts
py project_dir              # PyCharm
idea project_dir            # IntelliJ IDEA
ws project_dir              # WebStorm
dg                          # DataGrip
ds project_dir              # DataSpell

# Smart project detection
open_project .              # Auto-detect project type and open in right IDE
project ~/my_app            # Same as above

# Diagnostics (fixes file dialog issues)
jb-status                   # Show JetBrains tool status
jb-diagnose                 # Diagnose environment issues
jb-clean                    # Launch PyCharm with clean environment
```

## Architecture (Completely Redesigned)

### New Modular Structure
```
~/.config/zsh/
├── zshrc                   # Main loader (300 lines vs 2400+)
├── zshrc.original         # Backup of old monolithic file
├── config/                # NEW: Modular configuration
│   ├── core.zsh          # Essential shell settings
│   ├── credentials.zsh   # Multi-backend credential management
│   ├── database.zsh      # Database connections with security
│   ├── jetbrains.zsh     # IDE integration
│   └── help.zsh          # Updated help system
├── functions/             # Function libraries
└── legacy/                # Old modules being phased out
```

### Core Modules (Always Loaded)
1. **Core Module** (`config/core.zsh`)
   - Essential shell settings, aliases, utilities
   - No external dependencies
   - Module loading system

2. **Credentials Module** (`config/credentials.zsh`) 
   - Multi-backend: Environment vars → 1Password → Apple Keychain → Prompt
   - Backward compatible with existing PGPASSWORD workflow
   - Secure credential storage and retrieval

3. **Database Module** (`config/database.zsh`)
   - PostgreSQL, MySQL, Snowflake support
   - Integration with credential system
   - Connection testing and diagnostics

4. **JetBrains Module** (`config/jetbrains.zsh`)
   - All JetBrains IDEs (PyCharm, IntelliJ, DataGrip, etc.)
   - Project type auto-detection
   - Environment diagnosis (fixes file dialog issues)

### Loading Strategy
- **Dynamic Loading**: Only loads modules for installed tools
- **Error Handling**: Graceful degradation for missing modules
- **Performance**: Conditional loading improves startup time
- **Status Tracking**: Each module load tracked for diagnostics

### Key Improvements
- **87% Size Reduction**: 2400+ lines → 300 line loader + focused modules
- **Security**: No plaintext passwords, secure credential management
- **Maintainability**: Focused modules vs monolithic file
- **Performance**: Faster startup through conditional loading
- **Diagnostics**: Comprehensive status and error reporting

## Development Workflow (Updated)

### 1. Check System Status
```bash
modular_zsh_status          # See what's loaded
creds-status               # Check credential backends
db-status                  # Check database config
jb-status                  # Check IDE integration
```

### 2. Make Changes to Modules
```bash
# Edit specific modules
$EDITOR ~/.config/zsh/config/core.zsh
$EDITOR ~/.config/zsh/config/credentials.zsh
```

### 3. Test Changes
```bash
zsh run-tests.zsh          # Run updated tests
zsh-reload                 # Reload configuration
zsh-verbose                # Reload with debugging
```

### 4. Validate and Commit
```bash
# Test functionality
pgtest                     # Test database connections
py .                       # Test IDE integration

# Create backup and commit (if using backup system)
backup "description of changes"
```

## Key Features (Updated)

### ✅ NEW: Secure Credential Management
- **Multi-backend support**: 1Password, Apple Keychain, environment variables
- **Backward compatibility**: Existing env vars continue to work
- **Migration tools**: Move from plaintext to secure storage

### ✅ NEW: Database Integration
- **Secure connections**: No more plaintext passwords in config
- **Multiple databases**: PostgreSQL, MySQL, Snowflake
- **Connection testing**: Built-in diagnostics

### ✅ NEW: JetBrains IDE Integration
- **All IDEs supported**: PyCharm, IntelliJ, DataGrip, DataSpell, WebStorm
- **Smart detection**: Auto-opens right IDE based on project type
- **File dialog fix**: Resolved PyCharm file dialog hanging issues

### ✅ IMPROVED: Performance & Maintainability
- **Dynamic loading**: Only loads what's installed
- **Error handling**: Graceful degradation
- **Modular design**: Easy to maintain and extend
- **Comprehensive help**: New interactive help system

### 🔄 PRESERVED: Backward Compatibility
- **Environment variables**: All existing workflows preserved
- **Legacy support**: Old functions still work during transition
- **SDKMAN integration**: All big data tools still supported

## Migration Notes

The original 2400+ line zshrc is backed up as `zshrc.original`. The new modular system is fully backward compatible - all your existing environment variables and workflows continue to work unchanged.