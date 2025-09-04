# 🚀 Modular ZSH Configuration System

<div align="center">

![Siege Analytics](https://www.siegeanalytics.com/wp-content/uploads/2019/10/logo.png)

# Enhanced Modular ZSH Configuration System
### Cross-Platform Shell Environment with Dynamic Module Loading

**Spatial Intelligence • Data Science • Advanced Analytics**

[![Main Repository](https://img.shields.io/badge/Main%20Repo-siege__analytics__zshrc-blue?style=for-the-badge&logo=github)](https://github.com/dheerajchand/siege_analytics_zshrc)
[![Backup Repository](https://img.shields.io/badge/Backup%20Repo-zshrc__backups-green?style=for-the-badge&logo=github)](https://github.com/dheerajchand/zshrc_backups)
[![Website](https://img.shields.io/badge/Website-siegeanalytics.com-orange?style=for-the-badge&logo=globe)](https://www.siegeanalytics.com)

</div>

---

## 🎉 **NEW: Cross-Shell & Cross-Platform Architecture Complete!**

### 📊 **System Achievements:**
- **86% size reduction**: 2,435 lines → 350 lines in main config
- **Cross-shell compatibility**: Works in both **bash** and **zsh**
- **9 focused modules** replacing monolithic configuration
- **Full cross-platform support**: macOS, Linux, Docker, WSL
- **<2 second startup time** with dynamic loading
- **Enterprise-grade data science stack**: Spark, Hadoop, Python/UV integration
- **Complete security overhaul** with multi-backend credential management

---

## 🚀 Quick Start

### **One-Command Setup** (New Users)
```bash
# Clone and setup the modular system
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
cd ~/.config/zsh

# Works with both bash and zsh!
source zshrc

# Check system status
modular_zsh_status
```

### **Experienced Users** (Migration from Old System)
```bash
# Your existing setup will be preserved
cd ~/.config/zsh
git pull origin main

# The new modular system is active
# Your original zshrc is backed up as zshrc.original
source zshrc

# Verify all modules loaded
zsh-status
```

### **Cross-Platform Installation** (Linux/Docker/WSL)
```bash
# Works identically across all platforms
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
cd ~/.config/zsh && source zshrc

# System automatically detects platform and adapts
echo $ZSH_PLATFORM  # Shows: macos, linux, docker, etc.
environment_info    # Full platform details
```

---

## 📦 **Modular System Architecture**

### **9 Core Modules**
```
📁 ~/.config/zsh/config/               # Module directory
├── 🔧 core.zsh           # Essential shell configuration
├── 🌍 environment.zsh    # Cross-platform detection & paths  
├── 🔐 credentials.zsh    # Multi-backend security system
├── 🗄️  database.zsh      # PostgreSQL, MySQL, Snowflake
├── 💻 jetbrains.zsh      # IDE integration & project detection
├── ⚡ spark.zsh          # Apache Spark (all submit modes)
├── 🐘 hadoop.zsh         # HDFS, YARN, MapReduce
├── 🐳 docker.zsh         # Container management
└── ❓ help.zsh           # Interactive documentation system
```

### **Dynamic Loading System**
```bash
# Modules only load if tools are available
✅ Core module: Always loads (essential functions)
🌍 Environment: Always loads (platform detection)
🔐 Credentials: Always loads (security system)
🗄️  Database: Loads if PostgreSQL/MySQL detected
💻 JetBrains: Loads if JetBrains tools found
⚡ Spark: Loads if SDKMAN + Spark available  
🐘 Hadoop: Loads if SDKMAN + Hadoop available
🐳 Docker: Loads if Docker command available
```

---

## 🎯 **Key Features**

### 🔄 **Dynamic Module Loading**
- **Conditional loading** - Only loads modules for available tools
- **Fast startup** - No overhead from unused functionality
- **Graceful degradation** - Missing tools don't break the system
- **Status monitoring** - `modular_zsh_status` shows what's loaded

### 🌍 **Cross-Shell & Cross-Platform Support**
```bash
# Works seamlessly across shells and platforms
Shell Compatibility:
  ✅ ZSH (primary target)
  ✅ Bash (full compatibility layer)
  ✅ Mixed environments (development teams)
  ✅ CI/CD systems (any shell)

Platform Detection:
  ✅ macOS (Intel + Apple Silicon)
  ✅ Linux (Ubuntu, RHEL, Debian, Arch, Alpine)
  ✅ Docker containers (all base images)
  ✅ WSL (Windows Subsystem for Linux)
  ✅ Remote servers via SSH

# Cross-platform utilities work everywhere
platform_open file.txt    # Opens with system default
platform_copy < data.txt  # System clipboard integration
platform_paste > out.txt  # Cross-platform paste
platform_browser url      # Default browser opening
```

### 🔐 **Enterprise-Grade Security**
```bash
# Multi-backend credential management
Credential Priority Chain:
  1. Environment variables (preserves existing workflow)
  2. 1Password CLI integration 
  3. macOS Keychain (Apple platforms)
  4. Interactive prompts (fallback)

# Security improvements
✅ All plaintext passwords removed
✅ Secure credential storage options
✅ Backward compatible with env vars
✅ Easy migration to secure backends
```

### 🚀 **Performance & Reliability**
```bash
Performance Metrics:
  📊 86% reduction in main config size
  ⚡ <2 second startup time
  🎯 Conditional loading (only needed modules)
  🔄 Error handling with graceful fallbacks
  📈 Memory optimizations for containers
```

---

## 🛠️ **Module Documentation**

### **Core Module** (`config/core.zsh`)
Essential shell configuration that always loads:
```bash
# Utility functions
mkcd /path/to/new/dir          # Create and enter directory
extract archive.tar.gz         # Universal archive extraction
is_online                      # Check internet connectivity
command_exists docker          # Check if command available

# Path management  
path_add /custom/bin           # Add to PATH safely
path_remove /old/path          # Remove from PATH

# Enhanced aliases
ll, la, l                      # Enhanced ls with colors
gs, gp, gc                     # Git shortcuts
```

### **Environment Module** (`config/environment.zsh`)
Cross-platform detection and path management:
```bash
# Platform detection
echo $ZSH_PLATFORM            # macos, linux, unknown
echo $ZSH_IS_DOCKER           # true/false for containers
echo $IS_WSL                  # true/false for WSL

# Cross-platform utilities  
platform_open file.txt        # Open with default app
platform_copy < file.txt      # Copy to system clipboard
platform_paste > output.txt   # Paste from clipboard
environment_info              # Comprehensive system info
```

### **Credentials Module** (`config/credentials.zsh`)
Secure credential management across backends:
```bash
# Get credentials (tries all backends automatically)
get_credential "postgres" "myuser" "PASSWORD"

# Backend management
credential_backend_status      # Show available backends
detect_credential_backends     # Scan for available systems

# Usage examples
export PGPASSWORD=$(get_credential "postgres" "$PGUSER" "PASSWORD")
```

### **Database Module** (`config/database.zsh`)
Database connection management:
```bash
# Automatic credential setup
setup_postgres_credentials     # Uses secure credential system
setup_mysql_credentials       

# Connection testing
pg_test_connection            # Test PostgreSQL connection
database_status              # Show all database configs

# Aliases
pg                           # PostgreSQL with auto-credentials
mysql-local                  # MySQL with auto-credentials
```

### **Docker Module** (`config/docker.zsh`)
Container management and development utilities:
```bash
# Status and management
docker_status                # Comprehensive Docker status
docker_cleanup              # Clean unused containers/images
docker_deep_clean           # Aggressive cleanup (with confirmation)

# Development utilities
docker_dev_env python       # Quick dev environment
docker_shell myapp          # Interactive shell in container  
docker_logs myapp 50 true   # Follow logs with line limit

# Aliases
d, dc, dps, di              # Docker shortcuts
dcup, dcdown, dcrestart     # Docker Compose shortcuts
```

### **Spark Module** (`config/spark.zsh`)
Apache Spark with all execution modes:
```bash
# Cluster management
spark_start                 # Start local Spark cluster
spark_stop                  # Stop cluster
spark_status               # Show cluster status

# Submission modes
smart_spark_submit script.py        # Auto-detect best mode
default_spark_submit script.py      # Local mode
distributed_spark_submit script.py  # Cluster mode
heavy_api_submit script.py          # Optimized for API workloads
spark_yarn_submit script.py         # YARN integration

# Utilities
spark_shell                 # Scala shell with dependencies
pyspark_shell              # Python shell with dependencies
```

---

## 📋 **Quick Commands**

### **System Management**
```bash
# Module status and management
modular_zsh_status         # Show all module status
zsh-reload                 # Reload entire configuration
zsh-verbose                # Enable verbose loading
zsh-status                 # Alias for modular_zsh_status

# Environment information
environment_info           # Full system information  
env-info                  # Alias for environment_info
platform-info             # Platform detection details
container-info            # Container environment details
```

### **Data Science Workflow**
```bash
# Python environment management
py-switch list             # List all Python environments
py-switch myenv            # Switch to pyenv environment  
py-switch uv              # Activate UV project in current dir
py-info                   # Show Python environment status

# Data science project creation
ds-init myproject         # Basic data science project
ds-init myproject spark   # Project with Spark dependencies
ds-init myproject geo     # Project with geospatial tools

# UV integration (auto-activates on directory change)
uv init                   # Create new UV project
uv sync                   # Install dependencies
# Environment automatically activates when you cd into project
```

### **Cross-Platform Testing**
```bash
# Test system compatibility (bash + zsh)
./test-cross-platform-enhanced.sh  # Comprehensive test suite
```

### **Credential Management**
```bash
# Check credential system
credential_backend_status  # Show available backends
creds-status              # Alias for backend status

# Database credentials
database_status           # Show database config status
db-status                 # Alias for database status
```

---

## 🧪 **Testing & Validation**

### **Built-In Test Suite**
The system includes comprehensive testing:

```bash
# Cross-platform compatibility test
./test-cross-platform.sh

Test Results:
✅ Platform detection (macos)
✅ All 9 modules load successfully  
✅ All core functions available
✅ All status functions working
✅ All aliases configured
✅ Cross-platform utilities functional
✅ Credential system working
✅ Startup time <2 seconds
```

### **Module Testing** 
```bash
# Test individual modules
zsh -c 'source zshrc && echo $CORE_MODULE_LOADED'           # Core
zsh -c 'source zshrc && echo $ENVIRONMENT_MODULE_LOADED'    # Environment  
zsh -c 'source zshrc && echo $DOCKER_MODULE_LOADED'         # Docker
zsh -c 'source zshrc && echo $SPARK_MODULE_LOADED'          # Spark

# Test functions
zsh -c 'source zshrc && command -v docker_status'           # Function exists
zsh -c 'source zshrc && docker_status' | head -5            # Function works
```

---

## 🔧 **Configuration & Customization**

### **User Customizations**
```bash
# Add your customizations here
~/.config/zsh/user.zsh     # User-specific config (gitignored)
~/.config/zsh/local.zsh    # Machine-specific config (gitignored)

# Example user.zsh
export PREFERRED_VENV="myproject"
export CUSTOM_PATH="/my/custom/path"
alias myalias="my command"
```

### **Environment Variables**
```bash
# Control module behavior
export MODULAR_ZSHRC_VERBOSE="true"      # Show loading messages
export ZSH_STARTUP_TIMING="true"         # Show startup time
export SPARK_DRIVER_MEMORY="4g"          # Spark configuration
export HADOOP_HEAPSIZE="1024"            # Hadoop configuration
```

---

## 🐳 **Docker & Container Support**

### **Container Detection**
The system automatically detects and adapts to container environments:

```bash
# Automatic container optimizations
Memory Settings:
  🐳 Container: Reduced memory limits for Spark/Hadoop
  🖥️  Host: Full memory utilization

Path Detection:
  🐳 Container: Minimal PATH assumptions
  🖥️  Host: Standard system paths

Package Managers:
  🐳 Container: apk, apt (minimal)
  🖥️  Host: brew, apt, yum, dnf (full)
```

### **Docker Integration**
```bash
# Container utilities (from docker.zsh module)
is_in_container           # Check if running in container
container_host_info       # Show container details
docker_dev_env python     # Quick development environments

# Container-specific aliases
drun ubuntu:22.04         # Quick container run
ddev                      # Development environment
```

---

## 🚨 **Migration from Old System**

### **What Changed**
```bash
Before (Old System):
  📄 zshrc: 2,435 lines (monolithic)
  🔧 Maintenance: Difficult, one giant file
  🐛 Debugging: Hard to isolate issues
  🔒 Security: Plaintext passwords
  🌍 Platform: macOS-focused

After (New Modular System):
  📦 zshrc: 350 lines (loader only)
  📁 Modules: 9 focused, single-purpose modules
  🔧 Maintenance: Easy, modular design
  🐛 Debugging: Module isolation
  🔒 Security: Multi-backend credential system
  🌍 Platform: True cross-platform support
```

### **Backward Compatibility**
```bash
✅ All existing environment variables preserved
✅ All existing functions available
✅ All existing aliases work
✅ PGPASSWORD workflow maintained
✅ Snowflake credentials preserved
✅ Git configurations unchanged
✅ Tool paths (SDKMAN, Homebrew) preserved
```

### **What's New**
```bash
🆕 Cross-platform support (Linux, Docker, WSL)
🆕 Dynamic module loading
🆕 Multi-backend credential system
🆕 Container environment detection
🆕 Performance optimizations
🆕 Comprehensive error handling
🆕 Built-in testing framework
🆕 Enhanced status monitoring
```

---

## 📁 **Repository Structure**

```
~/.config/zsh/                          # Main configuration directory
├── zshrc                               # Main loader (350 lines)
├── zshrc.original                      # Backup of original (2,435 lines)
├── config/                             # Module directory
│   ├── core.zsh                        # Essential configuration
│   ├── environment.zsh                 # Platform detection
│   ├── credentials.zsh                 # Security system
│   ├── database.zsh                    # Database integration
│   ├── jetbrains.zsh                   # IDE integration
│   ├── spark.zsh                       # Apache Spark
│   ├── hadoop.zsh                      # Hadoop ecosystem
│   ├── docker.zsh                      # Container management
│   └── help.zsh                        # Documentation system
├── functions/                          # Additional functions
├── tests/                              # Test framework
│   ├── test-framework.zsh             # Testing utilities
│   └── test-modular-system.zsh        # Module tests
├── test-cross-platform.sh             # Cross-platform test suite
├── README.md                           # This file
├── REFACTORING_PLAN.md                # Complete refactoring log
├── CLAUDE.md                          # AI assistant documentation
└── IDIOT_LEVEL_GUIDE.md               # Beginner-friendly guide
```

---

## 🔄 **Getting Help**

### **Interactive Help System**
```bash
# Main help (from help.zsh module)
zsh_help                    # Main help overview
zsh_help core              # Core module help
zsh_help credentials       # Credentials module help
zsh_help docker            # Docker module help
zsh_help search spark      # Search for Spark-related functions

# Quick help aliases
help                       # Alias for zsh_help
```

### **Status and Diagnostics**
```bash
# System status
modular_zsh_status         # Complete module status
environment_info           # Platform and environment details
credential_backend_status  # Security system status
docker_status             # Docker system status  
spark_status              # Spark cluster status
hadoop_status             # Hadoop cluster status
```

---

## 🌟 **Key Benefits of New System**

### **For Developers**
- ✅ **Faster Development**: Quick module reloads without full restart
- ✅ **Better Debugging**: Module isolation makes issues easier to find
- ✅ **Easy Customization**: Add/remove modules as needed
- ✅ **Cross-Platform**: Same config works on all platforms

### **For DevOps/Infrastructure**
- ✅ **Container Ready**: Optimized for Docker environments
- ✅ **Cloud Compatible**: Works on any Linux distribution
- ✅ **Resource Efficient**: Loads only needed functionality
- ✅ **Secure**: No plaintext credentials in config

### **For Data Scientists**
- ✅ **Spark Integration**: All execution modes supported
- ✅ **Hadoop Support**: Complete HDFS/YARN management
- ✅ **Database Tools**: Secure credential management
- ✅ **IDE Integration**: Smart project detection

---

## 🚨 **Troubleshooting**

### **Common Issues**

**Modules Not Loading**
```bash
# Check module status
modular_zsh_status

# Reload with verbose output
MODULAR_ZSHRC_VERBOSE=true source zshrc

# Check specific module
echo $DOCKER_MODULE_LOADED
```

**Functions Not Available**
```bash
# Make sure you've sourced the new config
source ~/.config/zsh/zshrc

# Check if function exists
command -v docker_status
type docker_status
```

**Platform Detection Issues**
```bash
# Check platform detection
echo $ZSH_PLATFORM
echo $IS_DOCKER
environment_info
```

**Performance Issues**
```bash
# Check startup time
time zsh -c 'source ~/.config/zsh/zshrc'

# Enable timing
export ZSH_STARTUP_TIMING="true"
source zshrc
```

---

## 📖 **Additional Documentation**

### **Quick References**
- **[IDIOT_LEVEL_GUIDE.md](IDIOT_LEVEL_GUIDE.md)**: Step-by-step setup guide
- **[REFACTORING_PLAN.md](REFACTORING_PLAN.md)**: Complete refactoring history
- **[CLAUDE.md](CLAUDE.md)**: AI assistant integration guide

### **Module-Specific Help**
```bash
# Get help for any module
zsh_help core              # Core functionality
zsh_help environment       # Platform detection
zsh_help credentials       # Security system
zsh_help database          # Database integration
zsh_help docker            # Container management
zsh_help spark             # Apache Spark
zsh_help hadoop            # Hadoop ecosystem
```

---

## 🎉 **What's Next**

The modular system is complete and production-ready! Future enhancements will focus on:

1. **Additional Modules**: Add modules for specific tools as needed
2. **Enhanced Testing**: Expand cross-platform test coverage  
3. **Performance Tuning**: Further optimize startup times
4. **Documentation**: Expand module-specific documentation
5. **Community Features**: Templates for custom modules

---

<div align="center">

---

### 🚀 **Powered by Siege Analytics**

*The enhanced modular ZSH configuration system provides enterprise-grade shell environment management with cross-platform support, dynamic loading, and comprehensive security features. Built for data scientists, developers, and DevOps professionals who need reliable, fast, and secure shell environments.*

**Spatial Intelligence • Data Science • Advanced Analytics**

[![Siege Analytics](https://www.siegeanalytics.com/wp-content/uploads/2019/10/logo.png)](https://www.siegeanalytics.com)

</div>