# Enhanced zshrc Configuration

A comprehensive zsh configuration with advanced Spark, Hadoop, and big data development features.

## 🚀 Key Features

### **Core Development Stack**
- **Java 17.0.12-tem** - LTS version optimized for Spark/Hadoop
- **Scala 2.12.18 + 3.3.4** - Dual version setup (Spark compatibility + modern development)
- **Spark 3.5.3** - Pinned stable version with enhanced dependency management
- **Hadoop 3.3.6** - Integrated HDFS and YARN for distributed computing
- **Maven 3.9.6** - Build system with JAR management

### **Smart Auto-Setup System**
- Automatically installs and configures optimal versions
- Online/offline detection with graceful fallbacks
- Background execution to avoid shell startup delays
- Pinned known-good versions to prevent breaking changes
- Unified environment variable management

### **Advanced Spark + Hadoop Integration**
- **HDFS Storage** - Distributed file system for large datasets
- **YARN Resource Management** - Cluster resource scheduling
- **Intelligent dependency resolution** - Online packages vs local JARs
- **Multiple execution modes** - Local, distributed, Kubernetes, HDFS-backed
- **Sedona 1.7.1** - Modern spatial data processing with HDFS integration
- **GraphFrames** - Graph analytics with distributed storage

### **Unified Configuration Management**
- Single source of truth for all environment variables
- Consistent pattern across Java, Spark, and Hadoop
- Environment variable inheritance from zshrc to all services
- Centralized data directory management

### **Function Backup System**
- Automatic backup of critical functions on startup
- Emergency restore capabilities
- Version-controlled backup history
- Protection against configuration corruption

## 📋 Available Functions

### **Core Spark Functions**
```bash
default_spark_submit <file>         # Local execution with dependency resolution
distributed_spark_submit <file>     # Cluster execution with optimization
smart_spark_submit <file>           # Auto-detect best execution environment
heavy_api_submit <file> [mode]     # Optimized for API-heavy workloads
flexible_spark_submit <file> [mode] # Multi-mode execution (local/distributed/k8s/smart)
```

### **Hadoop Cluster Management**
```bash
start_hadoop                       # Start complete Hadoop cluster (HDFS + YARN)
stop_hadoop                        # Stop all Hadoop services
restart_hadoop                     # Restart Hadoop cluster with fresh state
hadoop_status                      # Check Hadoop service health and status
init_hadoop_dirs                   # Create Hadoop data directories
```

### **Spark Cluster Management**
```bash
spark_start                        # Start local Spark cluster
spark_stop                         # Stop Spark cluster
spark_restart                      # Restart cluster with fresh state
spark_status                       # Check cluster health and status
```

### **HDFS Operations**
```bash
hdfs_format                        # Format HDFS namenode (destructive)
hdfs_safe_mode                     # Check/manage HDFS safe mode
hdfs_report                        # HDFS cluster health report
hdfs_ls [path]                     # List HDFS directory contents
hdfs_put <local> <hdfs>           # Upload file to HDFS
hdfs_get <hdfs> <local>           # Download file from HDFS
```

### **Testing & Diagnostics**
```bash
test_spark_comprehensive           # Full Sedona + GraphFrames functionality test
test_spark_dependencies            # Test dependency resolution system
test_hadoop_integration            # Test Spark + HDFS integration
spark_test_simple                  # Quick cluster connectivity test
hadoop_test_simple                 # Quick HDFS connectivity test
```

### **Dependency Management**
```bash
download_maven_jars <coords> <path> # Download Maven JAR dependencies
download_hadoop_slf4j_jars         # Download SLF4J JARs for Hadoop logging
```

### **Auto-Setup System**
```bash
enable_auto_setup                  # Enable automatic version management
disable_auto_setup                 # Disable auto-setup
auto_setup_environment             # Run version setup manually
setup_environment_status           # Check current setup status
show_version_strategy              # Display pinned version strategy
verify_version_compatibility       # Check installed version compatibility
```

### **Individual Component Setup**
```bash
setup_java_version                 # Install/configure Java 17
setup_scala_version                # Install dual Scala versions
setup_spark_version                # Install Spark 3.5.3
setup_hadoop_version               # Install Hadoop 3.3.6
setup_maven                        # Install Maven
```

### **Function Backup System**
```bash
backup_critical_functions          # Create backup of important functions
restore_critical_functions         # Restore functions from backup
emergency_restore_test_function    # Emergency inline restore
list_function_backups              # Show available backups
```

### **zshrc Management**
```bash
backup_zshrc                       # Create versioned zshrc backup with git
zshreboot                          # Reload zshrc configuration
zshconfig                          # Open zshrc in editor
```

## 🔧 Configuration Variables

### **Core Environment Variables**
```bash
export JAVA_HOME="/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current"
export HADOOP_HOME="/path/to/hadoop"
export SPARK_HOME="/path/to/spark"
export HADOOP_DATA_DIR="$HOME/hadoop-data"    # Unified data directory
export HADOOP_LOCAL_JARS="$HADOOP_HOME/share/hadoop/common/lib/"
```

### **Auto-Setup Control**
```bash
export AUTO_SETUP_ON_STARTUP="false"    # Enable/disable auto-setup
export AUTO_SETUP_CHECK_ONLINE="true"   # Check connectivity before setup
export AUTO_SETUP_VERBOSE="false"       # Detailed setup output
```

### **Spark Configuration**
```bash
export SPARK_DRIVER_MEMORY="2g"         # Driver memory allocation
export SPARK_EXECUTOR_MEMORY="1g"       # Executor memory allocation
export SPARK_WORKER_MEMORY="2g"         # Worker memory allocation
export SPARK_WORKER_INSTANCES="4"       # Number of worker instances
```

### **Hadoop Configuration**
```bash
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export YARN_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HDFS_NAMENODE_USER="$USER"       # Namenode process user
export HDFS_DATANODE_USER="$USER"       # Datanode process user
export HDFS_SECONDARYNAMENODE_USER="$USER"  # Secondary namenode user
export YARN_RESOURCEMANAGER_USER="$USER"    # YARN resource manager user
export YARN_NODEMANAGER_USER="$USER"        # YARN node manager user
```

### **Dependency Management**
```bash
export DEFAULT_SPARK_JARS="..."         # Online JAR dependencies
export LOCAL_SPARK_JAR_PATH="$HOME/local_jars"  # Local JAR storage
```

## 🏗️ Architecture

### **Pinned Version Strategy**
This configuration uses a "pinned known-good versions" approach:

- **Java 17.0.12-tem** - Proven LTS version with full Spark/Hadoop support
- **Scala 2.12.18** - Required for Spark 3.5.3 compatibility (default)
- **Scala 3.3.4** - Available for modern development (`sdk use scala 3.3.4`)
- **Spark 3.5.3** - Your current working version (no surprise upgrades)
- **Hadoop 3.3.6** - Stable integration with Spark ecosystem, HDFS + YARN

### **Unified Environment Variable Pattern**
All configuration follows a consistent pattern:
```bash
# In zshrc (single source of truth)
export HADOOP_DATA_DIR="$HOME/hadoop-data"

# In service config files (hadoop-env.sh, spark-env.sh)
export HADOOP_DATA_DIR=${HADOOP_DATA_DIR:-$HOME/hadoop-data}

# In XML config files (hdfs-site.xml, core-site.xml)
<value>file://${env.HADOOP_DATA_DIR}/hdfs/namenode</value>
```

### **Spark + Hadoop Integration Architecture**
```mermaid
graph TD
    A[Spark Application] --> B[Spark Driver]
    B --> C[Spark Executors]
    B --> D[HDFS Client]
    D --> E[HDFS NameNode]
    E --> F[HDFS DataNodes]
    C --> G[Local Processing]
    C --> H[HDFS Read/Write]
    H --> F
    B --> I[YARN ResourceManager]
    I --> J[YARN NodeManagers]
    J --> C
```

### **Dependency Resolution Logic**
```mermaid
graph TD
    A[Spark Submit] --> B{Online?}
    B -->|Yes| C[Use --packages with Maven repos]
    B -->|No| D[Check local JARs]
    D -->|Found| E[Use --jars with local files]
    D -->|Missing| F[Download essential JARs]
    F --> E
    E --> G{HDFS Available?}
    G -->|Yes| H[Use HDFS for input/output]
    G -->|No| I[Use local filesystem]
```

### **Smart Environment Detection**
The `smart_spark_submit` function automatically detects:
1. **Kubernetes** - If kubectl available and K8s master configured
2. **YARN Cluster** - If Hadoop YARN is running
3. **Local Cluster** - If Spark master/workers running
4. **HDFS Storage** - If HDFS is available for data storage
5. **Cluster Startup** - Offers to start local cluster if available
6. **Fallback** - Local mode as safe default

## 🧪 Testing Strategy

### **Comprehensive Testing**
The `test_spark_comprehensive` function validates:
- ✅ Core Spark functionality (RDD, DataFrame, SQL)
- ✅ Sedona spatial operations (modern 1.7.1+ initialization)
- ✅ GraphFrames graph analytics
- ✅ Dependency resolution (online/offline modes)
- ✅ HDFS integration and file operations
- ✅ Cross-component integration

### **Hadoop Integration Testing**
The `test_hadoop_integration` function validates:
- ✅ HDFS connectivity and file operations
- ✅ Spark reading/writing to HDFS
- ✅ YARN resource management
- ✅ Distributed processing across cluster

### **Development Workflow**
```bash
# 1. Check current setup
setup_environment_status

# 2. Start Hadoop cluster
start_hadoop

# 3. Start Spark cluster
spark_start

# 4. Run comprehensive test
test_spark_comprehensive

# 5. Test Hadoop integration
test_hadoop_integration

# 6. If issues, verify versions
verify_version_compatibility

# 7. Auto-fix if needed
auto_setup_environment
```

## 🚨 Emergency Procedures

### **If Functions Break**
```bash
# Emergency restore critical functions
emergency_restore_test_function

# Or restore from backup
restore_critical_functions

# Check available backups
list_function_backups
```

### **If zshrc Corrupts**
```bash
# Manual restoration (this README's parent directory)
cp .zshrc_YYYY-MM-DD_HH-MM-SS.txt ~/.zshrc
source ~/.zshrc
```

### **If Spark Breaks**
```bash
# Reset to known-good versions
auto_setup_environment

# Test basic functionality
spark_test_simple

# Full diagnostic
test_spark_comprehensive
```

### **If Hadoop Breaks**
```bash
# Stop all services
stop_hadoop

# Reinitialize data directories
init_hadoop_dirs

# Format namenode (DESTRUCTIVE)
hdfs_format

# Restart services
start_hadoop

# Test basic functionality
hadoop_test_simple
```

## 🔄 Maintenance Tasks

### **Regular Updates**
```bash
# Check for component updates (manual)
setup_environment_status

# Update Python packages
pip install --upgrade apache-sedona pyspark

# Backup before major changes
backup_zshrc
backup_critical_functions
```

### **HDFS Maintenance**
```bash
# Check HDFS health
hdfs_report

# Clean up HDFS trash
hdfs dfs -expunge

# Check disk usage
hdfs dfs -df -h

# Rebalance HDFS blocks
hdfs balancer
```

### **Performance Tuning**
```bash
# For API-heavy workloads
heavy_api_submit your_script.py

# For large datasets with HDFS
export SPARK_DRIVER_MEMORY="4g"
export SPARK_EXECUTOR_MEMORY="2g"
flexible_spark_submit your_script.py distributed
```

## 📊 Compatibility Matrix

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| Java      | 17.0.12-tem | ✅ | LTS, Spark/Hadoop compatible |
| Scala     | 2.12.18 | ✅ | Spark 3.5.3 required |
| Scala     | 3.3.4   | ✅ | Modern development |
| Spark     | 3.5.3   | ✅ | Your current stable version |
| Hadoop    | 3.3.6   | ✅ | HDFS + YARN integrated |
| Sedona    | 1.7.1   | ✅ | Spatial processing with HDFS |
| GraphFrames | 0.8.3 | ✅ | Graph analytics with HDFS |

## 🛠️ Customization

### **Adding New Functions**
1. Add function to zshrc
2. Run `backup_critical_functions`
3. Test with `zsh -n ~/.zshrc`
4. Reload with `zshreboot`

### **Modifying Versions**
1. Edit target versions in setup functions
2. Run `auto_setup_environment`
3. Verify with `verify_version_compatibility`

### **Environment-Specific Settings**
```bash
# Add to your zshrc for customization
export SPARK_DRIVER_MEMORY="4g"        # Increase for your workload
export HADOOP_DATA_DIR="$HOME/big-data" # Custom data directory
export AUTO_SETUP_VERBOSE="true"       # Debug setup issues
export SPARK_WORKER_INSTANCES="8"      # More workers for large datasets
```

### **Custom Hadoop Configuration**
```bash
# Custom HDFS settings in hdfs-site.xml
<property>
    <name>dfs.replication</name>
    <value>3</value>  <!-- Increase for production -->
</property>
```

## 🎯 Use Cases

### **Large-Scale Data Processing**
- **HDFS Storage**: Store TB+ datasets across distributed nodes
- **Spark + HDFS**: Process large files without local storage limits
- **YARN Scheduling**: Efficiently share cluster resources

### **Geospatial Analytics**
- **Sedona + HDFS**: Process massive spatial datasets
- **Distributed Joins**: Spatial joins across partitioned data
- **Scalable Processing**: Handle continent-scale geographic data

### **Graph Analytics**
- **GraphFrames + HDFS**: Analyze large graph structures
- **Distributed Algorithms**: PageRank, connected components
- **Persistent Storage**: Store graph results in HDFS

## 📝 Changelog

- **v4.0** - Full Hadoop integration with HDFS and YARN
- **v3.0** - Enhanced auto-setup system with pinned versions
- **v2.0** - Function backup system and emergency restore
- **v1.0** - Advanced Spark integration with Sedona + GraphFrames

## 🤝 Contributing

To contribute improvements:
1. `backup_zshrc` before changes
2. Test thoroughly with `test_spark_comprehensive` and `test_hadoop_integration`
3. Update this README
4. Share your enhancements!

---

*Generated for enhanced zshrc configuration with enterprise-grade big data development features including full Hadoop ecosystem integration.*
