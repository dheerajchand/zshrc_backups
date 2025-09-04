#!/usr/bin/env zsh

# =====================================================
# APACHE SPARK MODULE
# =====================================================
# 
# Cross-platform Apache Spark configuration and utilities
# Supports local, distributed, and YARN execution modes
# Optimized for different workload types (ML, API-heavy, etc.)
# =====================================================

# Module identification
export SPARK_MODULE_LOADED="true"

# =====================================================
# SPARK CONFIGURATION & DETECTION
# =====================================================

setup_spark_environment() {
    # Auto-detect and configure Spark
    local spark_candidates=()
    
    # Platform-specific Spark locations
    case "$ZSH_PLATFORM" in
        "macos")
            spark_candidates=(
                "/opt/homebrew/opt/apache-spark/libexec"
                "/usr/local/opt/apache-spark/libexec"
                "$HOME/spark"
                "$HOME/apache-spark"
            )
            ;;
        "linux")
            spark_candidates=(
                "/opt/spark"
                "/usr/local/spark"
                "/opt/apache-spark"
                "/usr/local/apache-spark"
                "$HOME/spark"
                "$HOME/apache-spark"
            )
            ;;
    esac
    
    # Check SDKMAN installations
    if [[ -n "$SDKMAN_DIR" ]]; then
        local sdkman_spark="$SDKMAN_DIR/candidates/spark/current"
        [[ -d "$sdkman_spark" ]] && spark_candidates=("$sdkman_spark" "${spark_candidates[@]}")
    fi
    
    # Find Spark installation
    for candidate in "${spark_candidates[@]}"; do
        if [[ -d "$candidate" && -f "$candidate/bin/spark-submit" ]]; then
            export SPARK_HOME="$candidate"
            break
        fi
    done
    
    if [[ -z "$SPARK_HOME" ]]; then
        [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⚠️  Apache Spark not found - functions will be limited"
        return 1
    fi
    
    # Configure Spark environment
    export SPARK_CONF_DIR="$SPARK_HOME/conf"
    export PYSPARK_PYTHON=python3
    export PYSPARK_DRIVER_PYTHON=python3
    
    # Add Spark to PATH
    path_add "$SPARK_HOME/bin"
    path_add "$SPARK_HOME/sbin"
    
    # Default configurations
    export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
    export SPARK_EXECUTOR_MEMORY="${SPARK_EXECUTOR_MEMORY:-1g}"
    export SPARK_MASTER_URL="${SPARK_MASTER_URL:-spark://localhost:7077}"
    
    # Container-specific adjustments
    if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
        # Reduce memory requirements for containers
        export SPARK_DRIVER_MEMORY="1g"
        export SPARK_EXECUTOR_MEMORY="512m"
    fi
}

# =====================================================
# SPARK DEPENDENCY MANAGEMENT
# =====================================================

get_spark_dependencies() {
    # Generate common Spark dependencies string
    local deps=()
    
    # Check for common JAR directories
    local jar_dirs=(
        "$HOME/spark-jars"
        "$HOME/.spark/jars"
        "$SPARK_HOME/jars"
        "$HOME/local-jars"
    )
    
    # Add JARs if directories exist
    for jar_dir in "${jar_dirs[@]}"; do
        if [[ -d "$jar_dir" ]] && [[ -n "$(find "$jar_dir" -name "*.jar" 2>/dev/null)" ]]; then
            deps+="--jars $(find "$jar_dir" -name "*.jar" | paste -sd ',')"
            break  # Use first available JAR directory
        fi
    done
    
    # Common packages for different use cases
    local common_packages=(
        "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0"
        "org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0"
        "com.databricks:spark-csv_2.12:1.5.0"
    )
    
    # Check if packages should be included (only if not in container to save bandwidth)
    if [[ "$ZSH_IS_DOCKER" != "true" ]]; then
        deps+="--packages $(IFS=,; echo "${common_packages[*]}")"
    fi
    
    echo "${deps[*]}"
}

# =====================================================
# SPARK CLUSTER MANAGEMENT
# =====================================================

spark_start() {
    # Start local Spark cluster
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set. Run setup first."
        return 1
    fi
    
    echo "🚀 Starting Spark cluster..."
    
    # Start master
    if ! pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "   Starting Spark master..."
        "$SPARK_HOME/sbin/start-master.sh"
        
        # Wait for master to start
        local max_wait=30
        local wait_count=0
        while ! nc -z localhost 7077 2>/dev/null && [[ $wait_count -lt $max_wait ]]; do
            sleep 1
            ((wait_count++))
        done
        
        if [[ $wait_count -ge $max_wait ]]; then
            echo "❌ Master failed to start within ${max_wait}s"
            return 1
        fi
        
        echo "   ✅ Master started at $SPARK_MASTER_URL"
    else
        echo "   ✅ Master already running"
    fi
    
    # Start worker
    if ! pgrep -f "spark.deploy.worker.Worker" >/dev/null; then
        echo "   Starting Spark worker..."
        "$SPARK_HOME/sbin/start-worker.sh" "$SPARK_MASTER_URL"
        
        # Wait a bit for worker to register
        sleep 3
        echo "   ✅ Worker started"
    else
        echo "   ✅ Worker already running"
    fi
    
    echo "🎯 Spark cluster ready!"
    echo "   Master URL: $SPARK_MASTER_URL"
    echo "   Web UI: http://localhost:8080"
    
    # Export updated URL
    export SPARK_MASTER_URL="spark://localhost:7077"
}

spark_stop() {
    # Stop local Spark cluster
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set"
        return 1
    fi
    
    echo "🛑 Stopping Spark cluster..."
    
    # Stop worker first
    if pgrep -f "spark.deploy.worker.Worker" >/dev/null; then
        echo "   Stopping worker..."
        "$SPARK_HOME/sbin/stop-worker.sh" 2>/dev/null
        echo "   ✅ Worker stopped"
    fi
    
    # Stop master
    if pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "   Stopping master..."
        "$SPARK_HOME/sbin/stop-master.sh" 2>/dev/null
        echo "   ✅ Master stopped"
    fi
    
    echo "✅ Spark cluster stopped"
}

spark_status() {
    # Show Spark cluster status
    echo "⚡ Apache Spark Status"
    echo "===================="
    echo ""
    
    echo "Configuration:"
    echo "  SPARK_HOME: ${SPARK_HOME:-Not set}"
    echo "  Driver Memory: $SPARK_DRIVER_MEMORY"
    echo "  Executor Memory: $SPARK_EXECUTOR_MEMORY"
    echo "  Master URL: $SPARK_MASTER_URL"
    echo ""
    
    # Check if Spark processes are running
    echo "Cluster Status:"
    if pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "  ✅ Master: Running (PID: $(pgrep -f "spark.deploy.master.Master"))"
        echo "     Web UI: http://localhost:8080"
    else
        echo "  ❌ Master: Not running"
    fi
    
    if pgrep -f "spark.deploy.worker.Worker" >/dev/null; then
        echo "  ✅ Worker: Running (PID: $(pgrep -f "spark.deploy.worker.Worker"))"
        echo "     Web UI: http://localhost:8081"
    else
        echo "  ❌ Worker: Not running"
    fi
    
    echo ""
    
    # Check connectivity
    echo "Connectivity:"
    if nc -z localhost 7077 2>/dev/null; then
        echo "  ✅ Master port (7077): Accessible"
    else
        echo "  ❌ Master port (7077): Not accessible"
    fi
    
    if nc -z localhost 8080 2>/dev/null; then
        echo "  ✅ Master Web UI (8080): Accessible"
    else
        echo "  ❌ Master Web UI (8080): Not accessible"
    fi
}

# =====================================================
# SPARK SUBMIT FUNCTIONS
# =====================================================

default_spark_submit() {
    # Standard local Spark submit with optimizations
    local py_file="$1"
    
    if [[ -z "$py_file" ]]; then
        echo "Usage: default_spark_submit <python_file>"
        return 1
    fi
    
    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi
    
    echo "🏠 Local Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)
    
    # Use local mode with all available cores
    spark-submit \
        --master "local[*]" \
        --driver-memory "$SPARK_DRIVER_MEMORY" \
        --executor-memory "$SPARK_EXECUTOR_MEMORY" \
        --conf "spark.sql.adaptive.enabled=true" \
        --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" \
        ${=dependencies} \
        "$py_file"
}

distributed_spark_submit() {
    # Submit to distributed Spark cluster
    local py_file="$1"
    local master_url="${2:-$SPARK_MASTER_URL}"
    
    if [[ -z "$py_file" ]]; then
        echo "Usage: distributed_spark_submit <python_file> [master_url]"
        return 1
    fi
    
    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi
    
    if [[ -z "$master_url" ]]; then
        echo "❌ No master URL. Run: spark_start"
        return 1
    fi
    
    echo "🌐 Distributed Spark submit..."
    local dependencies=$(get_spark_dependencies)
    
    spark-submit \
        --master "$master_url" \
        --deploy-mode client \
        --driver-memory "$SPARK_DRIVER_MEMORY" \
        --executor-memory "$SPARK_EXECUTOR_MEMORY" \
        --executor-cores 1 \
        --num-executors 4 \
        --conf "spark.sql.adaptive.enabled=true" \
        --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" \
        --conf "spark.network.timeout=300s" \
        ${=dependencies} \
        "$py_file"
}

smart_spark_submit() {
    # Automatically choose best execution mode
    local py_file="$1"
    
    if [[ -z "$py_file" ]]; then
        echo "Usage: smart_spark_submit <python_file>"
        return 1
    fi
    
    echo "🤖 Smart environment detection..."
    
    # Check for running cluster
    if [[ -n "$SPARK_MASTER_URL" ]] && pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "✅ Local Spark cluster detected - using distributed mode"
        distributed_spark_submit "$py_file"
        return
    fi
    
    # Check if we can start a cluster
    if [[ -n "$SPARK_HOME" ]] && [[ -f "$SPARK_HOME/sbin/start-master.sh" ]] && [[ "$ZSH_IS_DOCKER" != "true" ]]; then
        echo "ℹ️  No running cluster found - would you like to start one? (y/n)"
        read "start_cluster?"
        if [[ "$start_cluster" == "y" ]]; then
            spark_start
            sleep 2
            distributed_spark_submit "$py_file"
            return
        fi
    fi
    
    # Fall back to local mode
    echo "ℹ️  Using local mode"
    default_spark_submit "$py_file"
}

spark_yarn_submit() {
    # Submit to YARN cluster
    local script_file="$1"
    local deploy_mode="${2:-client}"
    
    if [[ -z "$script_file" ]]; then
        echo "Usage: spark_yarn_submit <script_file> [client|cluster]"
        return 1
    fi
    
    # Check if YARN is available (requires Hadoop module)
    if ! command -v yarn >/dev/null 2>&1; then
        echo "❌ YARN not available. Install Hadoop first."
        return 1
    fi
    
    echo "🚀 Submitting Spark job to YARN..."
    local dependencies=$(get_spark_dependencies)
    
    spark-submit \
        --master yarn \
        --deploy-mode "$deploy_mode" \
        --driver-memory 2g \
        --executor-memory 1g \
        --executor-cores 2 \
        --num-executors 2 \
        --conf "spark.sql.adaptive.enabled=true" \
        --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" \
        ${=dependencies} \
        "$script_file"
}

heavy_api_submit() {
    # Optimized submit for API-heavy workloads
    local py_file="$1"
    local mode="${2:-auto}"
    
    if [[ -z "$py_file" ]]; then
        echo "Usage: heavy_api_submit <python_file> [mode]"
        echo "Modes: auto (default), local, distributed, yarn"
        return 1
    fi
    
    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi
    
    echo "🚀 Heavy API Workload Submit - Optimized for API-intensive processing..."
    
    # Heavy API workload optimizations
    local heavy_api_configs=(
        "--conf spark.sql.adaptive.enabled=true"
        "--conf spark.sql.adaptive.coalescePartitions.enabled=true"
        "--conf spark.serializer=org.apache.spark.serializer.KryoSerializer"
        "--conf spark.network.timeout=600s"
        "--conf spark.executor.heartbeatInterval=60s"
        "--conf spark.sql.execution.arrow.pyspark.enabled=true"
        "--conf spark.sql.adaptive.skewJoin.enabled=true"
        "--conf spark.dynamicAllocation.enabled=false"
        "--conf spark.python.worker.reuse=true"
        "--conf spark.sql.adaptive.localShuffleReader.enabled=true"
    )
    
    local dependencies=$(get_spark_dependencies)
    
    # Auto-detect mode
    case "$mode" in
        auto)
            echo "   🤖 Auto-detecting best execution environment..."
            if command -v yarn >/dev/null 2>&1 && pgrep -f ResourceManager >/dev/null; then
                echo "   ✅ YARN available - using YARN mode"
                mode="yarn"
            elif [[ -n "$SPARK_MASTER_URL" ]] && pgrep -f "spark.deploy.master.Master" >/dev/null; then
                echo "   ✅ Spark cluster available - using distributed mode"
                mode="distributed"
            else
                echo "   ℹ️  Using local mode with heavy API optimizations"
                mode="local"
            fi
            ;;
    esac
    
    # Execute based on mode
    case "$mode" in
        local)
            echo "   🏠 Local mode with API-heavy optimizations..."
            spark-submit \
                --master "local[*]" \
                --driver-memory 4g \
                --conf "spark.driver.maxResultSize=2g" \
                ${heavy_api_configs[*]} \
                ${=dependencies} \
                "$py_file"
            ;;
        distributed)
            if [[ -z "$SPARK_MASTER_URL" ]] || ! pgrep -f "spark.deploy.master.Master" >/dev/null; then
                echo "❌ No Spark cluster running. Run: spark_start"
                return 1
            fi
            echo "   🌐 Distributed mode with API-heavy optimizations..."
            spark-submit \
                --master "$SPARK_MASTER_URL" \
                --deploy-mode client \
                --driver-memory 4g \
                --executor-memory 2g \
                --executor-cores 2 \
                --num-executors 4 \
                --conf "spark.driver.maxResultSize=2g" \
                ${heavy_api_configs[*]} \
                ${=dependencies} \
                "$py_file"
            ;;
        yarn)
            if ! command -v yarn >/dev/null 2>&1 || ! pgrep -f ResourceManager >/dev/null; then
                echo "❌ YARN not running. Install and start Hadoop."
                return 1
            fi
            echo "   🎯 YARN mode with API-heavy optimizations..."
            spark-submit \
                --master yarn \
                --deploy-mode client \
                --driver-memory 4g \
                --executor-memory 2g \
                --executor-cores 2 \
                --num-executors 4 \
                --conf "spark.driver.maxResultSize=2g" \
                ${heavy_api_configs[*]} \
                ${=dependencies} \
                "$py_file"
            ;;
        *)
            echo "❌ Invalid mode: $mode"
            return 1
            ;;
    esac
}

# =====================================================
# SPARK UTILITIES
# =====================================================

spark_shell() {
    # Start Spark shell with common configurations
    echo "🐚 Starting Spark shell..."
    local dependencies=$(get_spark_dependencies)
    
    spark-shell \
        --conf "spark.sql.adaptive.enabled=true" \
        --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" \
        ${=dependencies}
}

pyspark_shell() {
    # Start PySpark shell with common configurations
    echo "🐍 Starting PySpark shell..."
    local dependencies=$(get_spark_dependencies)
    
    pyspark \
        --conf "spark.sql.adaptive.enabled=true" \
        --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" \
        ${=dependencies}
}

spark_history_server() {
    # Start Spark history server
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set"
        return 1
    fi
    
    echo "📊 Starting Spark History Server..."
    "$SPARK_HOME/sbin/start-history-server.sh"
    echo "✅ History server started at http://localhost:18080"
}

# =====================================================
# SPARK ALIASES
# =====================================================

alias spark-start='spark_start'
alias spark-stop='spark_stop'
alias spark-status='spark_status'
alias spark-restart='spark_stop && sleep 2 && spark_start'
alias spark-submit-local='default_spark_submit'
alias spark-submit-distributed='distributed_spark_submit'
alias spark-submit-smart='smart_spark_submit'
alias spark-submit-yarn='spark_yarn_submit'
alias spark-submit-heavy='heavy_api_submit'
alias spark-shell-start='spark_shell'
alias pyspark-start='pyspark_shell'
alias spark-history='spark_history_server'
alias spark-logs='ls -la $SPARK_HOME/logs/'

# =====================================================
# INITIALIZATION
# =====================================================

# Setup Spark environment
setup_spark_environment

# Show setup status if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && [[ -n "$SPARK_HOME" ]]; then
    echo "⚡ Spark: $(spark-submit --version 2>&1 | head -n1 | cut -d' ' -f5) at $SPARK_HOME"
fi