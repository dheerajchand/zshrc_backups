# 🚀 Enterprise Spark + Hadoop + YARN Development Environment

A comprehensive, production-ready zshrc configuration for big data development with Apache Spark, Hadoop, and YARN integration.

## 🎯 Overview

This zshrc provides a complete enterprise-grade development environment with:
- **Apache Spark 3.5.3** with Sedona (geospatial) and GraphFrames support
- **Hadoop 3.3.6** with HDFS and YARN cluster management
- **Java 17** optimized for Spark/Hadoop compatibility
- **Dual Scala support** (2.12.18 for Spark + 3.3.4 for modern development)
- **Intelligent dependency management** with online/offline JAR handling
- **Comprehensive backup/restore system** for configuration management
- **Auto-setup system** for seamless environment initialization

## ✨ Key Features

### 🔥 Spark Capabilities
- **Multiple execution modes**: Local, distributed, YARN, Kubernetes
- **Smart environment detection** and automatic optimization
- **Heavy API workload optimization** for geocoding, web scraping, etc.
- **Advanced spatial analytics** with Apache Sedona
- **Graph processing** with GraphFrames
- **Comprehensive testing framework**

### 🏗️ Hadoop + YARN Integration
- **Full HDFS cluster** with web monitoring
- **YARN resource management** with application tracking
- **Java 17 compatibility fixes** for modern JVM support
- **Automated service management** (start/stop/restart)
- **Health monitoring** and diagnostics

### 🛠️ Developer Experience
- **Pinned known-good versions** to prevent breakage
- **Automatic dependency resolution** (online/offline)
- **Rich logging and diagnostics**
- **Backup/restore system** with Git integration
- **Emergency recovery functions**

## 📦 Installation

### Prerequisites
- macOS with Homebrew
- SDKMAN for Java/Scala/Spark/Hadoop management
- Oh My Zsh with Powerlevel9k theme

### Setup
1. Replace your `~/.zshrc` with this configuration
2. Run the setup functions:
   ```bash
   # Enable auto-setup (runs on shell startup)
   enable_auto_setup

   # Or run setup manually
   auto_setup_environment
   ```

## 🎮 Usage Examples

### Basic Spark Operations
```bash
# Run a Spark script with smart environment detection
smart_spark_submit my_script.py

# Run with specific mode
default_spark_submit my_script.py           # Local mode
distributed_spark_submit my_script.py       # Distributed cluster
spark_yarn_submit my_script.py              # YARN mode
heavy_api_submit my_script.py yarn          # API-heavy workloads
```

### Hadoop + YARN Management
```bash
# Start the full Hadoop stack
start_hadoop

# Check cluster status
hadoop_status
yarn_cluster_info

# Stop services
stop_hadoop
```

### Testing and Diagnostics
```bash
# Comprehensive functionality test
test_spark_comprehensive

# Test Hadoop + Spark integration
test_hadoop_spark_integration

# Run demo with 100K records
hadoop_spark_demo
```

## 💾 Backup/Restore System

### Creating Backups
```bash
# Create a backup (saved as visible file for easy sharing)
backup_zshrc

# List available backups
list_zshrc_backups
```

### Restoring Configuration
```bash
# Restore from latest backup
restore_zshrc

# Restore specific backup
restore_zshrc 2023-05-29_11-24-59

# Emergency restore (no confirmation)
restore_zshrc_emergency
```

**Note**: Backup files are saved as **visible files** (no leading dot) making them easy to:
- Attach to emails
- Upload to cloud storage
- Share with team members
- Copy between systems

## 🔧 Configuration Management

### Version Strategy
The configuration uses a **pinned known-good version strategy**:

| Component | Version | Purpose |
|-----------|---------|---------|
| Java | 17.0.12-tem | LTS with Spark/Hadoop support |
| Scala | 2.12.18 | Spark 3.5.3 compatibility |
| Scala | 3.3.4 | Modern Scala development |
| Spark | 3.5.3 | Current stable release |
| Hadoop | 3.3.6 | Stable with Spark integration |
| Maven | 3.9.6 | Latest stable |

### Auto-Setup System
```bash
# Check setup status
setup_environment_status

# Verify version compatibility
verify_version_compatibility

# Show version strategy
show_version_strategy
```

## 🌐 Web Interfaces

When Hadoop services are running, access these web UIs:

| Service | URL | Purpose |
|---------|-----|---------|
| HDFS NameNode | http://localhost:9870 | HDFS cluster management |
| YARN ResourceManager | http://localhost:8088 | YARN job management |
| HDFS DataNode | http://localhost:9864 | HDFS data node status |

## 🚀 Key Functions Reference

### Spark Functions
- `default_spark_submit` - Local execution with dependency resolution
- `distributed_spark_submit` - Cluster execution
- `smart_spark_submit` - Auto-detect best execution mode
- `heavy_api_submit` - Optimized for API-heavy workloads
- `flexible_spark_submit` - Multi-mode execution (local/distributed/yarn/k8s)

### Hadoop Functions
- `start_hadoop` - Start HDFS + YARN services
- `stop_hadoop` - Stop all Hadoop services
- `hadoop_status` - Check service status
- `yarn_application_list` - List YARN applications
- `yarn_cluster_info` - Show cluster information

### Testing Functions
- `test_spark_comprehensive` - Full Sedona + GraphFrames test
- `test_hadoop_spark_integration` - Integration test
- `hadoop_spark_demo` - Demo with large dataset

### Setup Functions
- `auto_setup_environment` - Initialize all components
- `setup_hadoop_spark_integration` - Configure integration
- `verify_version_compatibility` - Check version compatibility

### Backup Functions
- `backup_zshrc` - Create configuration backup
- `restore_zshrc` - Restore from backup
- `backup_critical_functions` - Backup important functions

## 🔍 Troubleshooting

### Common Issues

**XML Configuration Errors**
If you see XML parsing errors, ensure all `<name>` tags are correct:
```bash
# Fix XML tags (macOS)
sed -i '' 's/<n>/<name>/g' ~/.dotfiles/homedir/.zshrc
sed -i '' 's/<\/n>/<\/name>/g' ~/.dotfiles/homedir/.zshrc
```

**YARN Startup Issues**
Java 17 compatibility is automatically handled, but if you see module access errors:
```bash
setup_java17_hadoop_compatibility
```

**Dependency Resolution**
The system handles both online (Maven) and offline (local JARs) dependency resolution:
```bash
# Test dependency resolution
test_spark_dependencies

# Download JARs for offline use
download_spark_jars_if_needed
```

### Emergency Recovery
```bash
# If functions are lost/corrupted
emergency_restore_test_function

# If entire config is broken
restore_zshrc_emergency
```

## 🎯 Performance Optimizations

### Heavy API Workloads
For geocoding, web scraping, or API-intensive tasks:
```bash
heavy_api_submit my_script.py auto
```

Includes optimizations:
- Increased timeouts for slow API responses
- Enhanced serialization for complex data
- Python worker reuse for faster initialization
- Adaptive query execution

### Memory Configuration
Default memory settings are optimized for development:
- Driver: 2GB
- Executor: 1GB
- Can be adjusted via environment variables

## 📚 Advanced Usage

### Custom Spark Configurations
```bash
# Set custom memory before running
export SPARK_DRIVER_MEMORY="4g"
export SPARK_EXECUTOR_MEMORY="2g"

# Run with custom settings
default_spark_submit my_script.py
```

### YARN Job Management
```bash
# List all applications
yarn_application_list

# View logs for specific application
yarn_logs application_12345

# Kill all running applications
yarn_kill_all_apps
```

## 🛡️ Safety Features

- **Automatic backups** before any restore operation
- **Confirmation prompts** for destructive operations
- **Version compatibility checks** before setup
- **Emergency recovery functions** for crisis situations
- **Git integration** for backup versioning

## 🌟 Enterprise Features

- **Pinned versions** prevent unexpected breakage
- **Comprehensive logging** for debugging
- **Health monitoring** and diagnostics
- **Multi-mode execution** for different environments
- **Scalable architecture** from laptop to cluster

---

**Ready to process big data like a pro!** 🚀

For questions or issues, check the function documentation or run the built-in diagnostic tools.
