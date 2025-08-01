# =====================================================
# COMPLETE ADVANCED SPARK CONFIGURATION MODULE
# =====================================================
# Only loaded when SPARK_HOME exists - ALL original features included

# Spark environment
export SPARK_HOME="${SPARK_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/spark/current}"
export SPARK_LOCAL_IP="127.0.0.1"
export SPARK_MASTER_HOST="127.0.0.1"
export SPARK_MASTER_PORT="7077"
export SPARK_WORKER_INSTANCES="4"
export SPARK_DRIVER_MEMORY="2g"
export SPARK_EXECUTOR_MEMORY="1g"
export SPARK_WORKER_MEMORY="2g"
export SPARK_CONF_DIR="$SPARK_HOME/conf"
export SPARK_CLIENT_CONFIG="$HOME/.spark-client-defaults.properties"

# Python paths
export PYSPARK_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"
export PYSPARK_DRIVER_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"

# Add Spark to PATH
export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"

# Additional environment variables for distributed mode
export SPARK_NUM_EXECUTORS="${SPARK_NUM_EXECUTORS:-4}"
export SPARK_EXECUTOR_CORES="${SPARK_EXECUTOR_CORES:-1}"
export SPARK_DRIVER_MAX_RESULT_SIZE="${SPARK_DRIVER_MAX_RESULT_SIZE:-2g}"

# =====================================================
# ENHANCED DEPENDENCY MANAGEMENT
# =====================================================
export DEFAULT_SPARK_JARS="org.apache.sedona:sedona-spark-shaded-3.5_2.12:1.7.1,org.datasyslab:geotools-wrapper:1.7.1-28.5,graphframes:graphframes:0.8.3-spark3.5-s_2.12"
export LOCAL_SPARK_JAR_PATH="$HOME/local_jars"
mkdir -p "$LOCAL_SPARK_JAR_PATH"

# Enhanced dependency resolution with debugging
function get_spark_dependencies {
    local online_status=$(is_online)
    echo "🔍 Dependency resolution:" >&2
    echo "   Online status: $online_status" >&2
    if [[ "$online_status" == "online" ]]; then
        echo "   Using online packages: $DEFAULT_SPARK_JARS" >&2
        echo "--packages $DEFAULT_SPARK_JARS"
    else
        echo "   Checking local JARs in: $LOCAL_SPARK_JAR_PATH" >&2
        local local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        if [[ -n "$local_jars" ]]; then
            echo "   Using local JARs: $(echo $local_jars | tr ',' ' ' | wc -w) found" >&2
            echo "--jars $local_jars"
        else
            echo "   ⚠️  No local JARs found, downloading recommended..." >&2
            download_spark_jars_if_needed
            # Try again after download
            local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$local_jars" ]]; then
                echo "   Using downloaded JARs" >&2
                echo "--jars $local_jars"
            else
                echo "   ⚠️  Proceeding without additional JARs" >&2
                echo ""
            fi
        fi
    fi
}

# Download essential JARs when offline
function download_spark_jars_if_needed {
    echo "📦 Downloading essential Spark JARs for offline use..."
    # Core JAR URLs (Maven Central)
    local jar_urls=(
        "https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.5_2.12/1.7.1/sedona-spark-shaded-3.5_2.12-1.7.1.jar"
        "https://repo1.maven.org/maven2/org/datasyslab/geotools-wrapper/1.7.1-28.5/geotools-wrapper-1.7.1-28.5.jar"
        "https://repo1.maven.org/maven2/graphframes/graphframes/0.8.3-spark3.5-s_2.12/graphframes-0.8.3-spark3.5-s_2.12.jar"
    )
    for url in "${jar_urls[@]}"; do
        local jar_name=$(basename "$url")
        local jar_path="$LOCAL_SPARK_JAR_PATH/$jar_name"
        if [[ ! -f "$jar_path" ]]; then
            echo "  Downloading: $jar_name"
            if curl -sL "$url" -o "$jar_path"; then
                echo "  ✅ Downloaded: $jar_name"
            else
                echo "  ❌ Failed: $jar_name"
                rm -f "$jar_path"  # Remove failed download
            fi
        else
            echo "  ✅ Already exists: $jar_name"
        fi
    done
}

# Test dependency resolution
function test_spark_dependencies {
    echo "🧪 Testing Spark dependency resolution..."
    echo ""
    echo "Current status:"
    local deps=$(get_spark_dependencies 2>&1)
    echo "Dependencies resolved: $(echo "$deps" | tail -1)"
    echo ""
    echo "Local JAR inventory:"
    if [[ -d "$LOCAL_SPARK_JAR_PATH" ]]; then
        find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" -exec basename {} \; | sort
        echo "Total JARs: $(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" | wc -l)"
    else
        echo "No local JAR directory found"
    fi
}

# =====================================================
# SPARK CLUSTER MANAGEMENT (IMPROVED)
# =====================================================

function spark_start {
    echo "🚀 Starting Spark cluster..."

    # Clean shutdown first - be thorough
    echo "🛑 Ensuring clean shutdown..."
    $SPARK_HOME/sbin/stop-all.sh &>/dev/null || true
    pkill -f "spark.deploy" &>/dev/null || true
    sleep 3

    # Start master only
    echo "🔄 Starting Spark master..."
    $SPARK_HOME/sbin/start-master.sh
    sleep 5

    # Start exactly one worker instance (Spark will manage cores)
    echo "🔄 Starting worker..."
    $SPARK_HOME/sbin/start-worker.sh spark://127.0.0.1:7077 &>/dev/null
    sleep 3

    # Set environment
    export SPARK_MASTER_URL="spark://127.0.0.1:7077"

    # Quick status check
    echo "📊 Checking cluster status..."
    local masters=$(pgrep -f "spark.deploy.master.Master" | wc -l)
    local workers=$(pgrep -f "spark.deploy.worker.Worker" | wc -l)

    if [[ $masters -gt 0 && $workers -gt 0 ]]; then
        echo "✅ Cluster started successfully!"
        echo "   📊 Master UI: http://127.0.0.1:8080"
        echo "   🎯 Master URL: $SPARK_MASTER_URL"
        echo "   ⚙️  Masters: $masters, Workers: $workers"
    else
        echo "❌ Cluster startup may have failed"
        echo "   Masters: $masters, Workers: $workers"
        echo "💡 Check logs: ls $SPARK_HOME/logs/"
    fi
}

function spark_stop {
    echo "🛑 Stopping Spark cluster..."
    # Use Spark's stop scripts
    if [[ -f "$SPARK_HOME/sbin/stop-all.sh" ]]; then
        $SPARK_HOME/sbin/stop-all.sh
    fi
    # Force kill any remaining
    pkill -f 'org.apache.spark.deploy.master.Master' 2>/dev/null
    pkill -f 'org.apache.spark.deploy.worker.Worker' 2>/dev/null
    unset SPARK_MASTER_URL
    echo "✅ Cluster stopped"
}

function spark_restart {
    echo "🔄 Restarting Spark cluster..."
    spark_stop
    sleep 3
    spark_start
}

function spark_status {
    echo "📊 Spark Cluster Status:"
    echo "   Master processes: $(ps aux | grep 'spark.deploy.master.Master' | grep -v grep | wc -l)"
    echo "   Worker processes: $(ps aux | grep 'spark.deploy.worker.Worker' | grep -v grep | wc -l)"
    echo "   Master URL: ${SPARK_MASTER_URL:-'Not set'}"
    echo "   Master UI: http://127.0.0.1:8080"
    # Quick functional test
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        echo "   Testing functionality..."
        spark_test_simple
    fi
}

# =====================================================
# ADVANCED SPARK SUBMIT FUNCTIONS
# =====================================================

# Enhanced default submit with dependency resolution
function default_spark_submit() {
    local py_file="$1"
    if [[ -z "$py_file" ]]; then
        echo "Usage: default_spark_submit <python_file>"
        return 1
    fi
    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi
    echo "🚀 Local Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)
    # Use eval to properly expand dependencies
    eval "spark-submit \
        --master 'local[*]' \
        --driver-memory $SPARK_DRIVER_MEMORY \
        --executor-memory $SPARK_EXECUTOR_MEMORY \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$py_file'"
}

# Enhanced distributed submit
function distributed_spark_submit() {
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
    echo "🌐 Distributed Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)
    # Use eval to properly expand dependencies
    eval "spark-submit \
        --master '$master_url' \
        --deploy-mode client \
        --driver-memory $SPARK_DRIVER_MEMORY \
        --executor-memory $SPARK_EXECUTOR_MEMORY \
        --executor-cores 1 \
        --num-executors 4 \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        --conf spark.network.timeout=300s \
        $dependencies \
        '$py_file'"
}

# Smart environment detection submit
function smart_spark_submit() {
    local py_file="$1"
    if [ -z "$py_file" ]; then
        echo "Usage: smart_spark_submit <python_file>"
        return 1
    fi
    echo "🤖 Smart environment detection..."
    # Check for standalone Spark cluster
    if [ -n "$SPARK_MASTER_URL" ] && ps aux | grep -i "spark.deploy.master.Master" | grep -v "grep" > /dev/null; then
        echo "✅ Local Spark cluster detected - using distributed mode"
        distributed_spark_submit "$py_file"
        return
    fi
    # Check if we can start a local cluster
    if [[ -n "$SPARK_HOME" ]] && [[ -f "$SPARK_HOME/sbin/start-master.sh" ]]; then
        echo "ℹ️  No running cluster found - would you like to start one? (y/n)"
        read "start_cluster?"
        if [[ "$start_cluster" == "y" ]]; then
            spark_start
            distributed_spark_submit "$py_file"
            return
        fi
    fi
    # Fall back to local mode
    echo "ℹ️  Using local mode"
    default_spark_submit "$py_file"
}

function spark_yarn_submit {
    local script_file="$1"
    local deploy_mode="${2:-client}"  # client or cluster
    if [[ -z "$script_file" ]]; then
        echo "Usage: spark_yarn_submit <script_file> [client|cluster]"
        return 1
    fi
    echo "🚀 Submitting Spark job to YARN..."
    local dependencies=$(get_spark_dependencies)
    eval "spark-submit \
        --master yarn \
        --deploy-mode '$deploy_mode' \
        --driver-memory 2g \
        --executor-memory 1g \
        --executor-cores 2 \
        --num-executors 2 \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$script_file'"
}

# Enhanced Heavy API Submit Function with Better Log Control
function heavy_api_submit {
    local py_file="$1"
    local mode="${2:-auto}"  # auto, local, distributed, yarn
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

    # Enhanced Heavy API workload optimizations with better log control
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
        # ENHANCED LOG CONTROL - These reduce verbosity significantly
        "--conf spark.log.level=ERROR"
        "--conf spark.sql.execution.arrow.pyspark.fallback.enabled=false"
        "--conf spark.ui.showConsoleProgress=false"
        "--conf spark.eventLog.enabled=false"
        "--conf spark.sql.execution.arrow.maxRecordsPerBatch=1000"
        "--conf spark.task.maxFailures=3"
        "--conf spark.stage.maxConsecutiveAttempts=8"
        # these are here to make Spark work Better
        "--conf spark.sql.ui.retainedExecutions=1"
        "--conf spark.sql.ui.retainedTasks=100"
        "--conf spark.ui.retainedJobs=10"
        "--conf spark.ui.retainedStages=10"
        "--conf spark.worker.ui.retainedExecutors=10"
        "--conf spark.worker.ui.retainedDrivers=10"
        "--conf spark.streaming.ui.retainedBatches=10"
        "--conf spark.eventLog.compress=true"
    )

    # Set environment variables to reduce verbosity
    export SPARK_LOG_LEVEL=ERROR
    export PYTHONHASHSEED=0
    export SPARK_LOCAL_DIRS="/tmp/spark-temp"

    local dependencies=$(get_spark_dependencies)
    local config_string="${heavy_api_configs[*]}"

    case "$mode" in
        auto)
            echo "   🤖 Auto-detecting best execution environment for heavy API workload..."
            if [[ -n "$SPARK_MASTER_URL" ]] && jps | grep -q ResourceManager; then
                echo "   ✅ YARN available - using YARN mode for better resource management"
                mode="yarn"
            elif [[ -n "$SPARK_MASTER_URL" ]] && ps aux | grep -q "spark.deploy.master.Master"; then
                echo "   ✅ Spark cluster available - using distributed mode"
                mode="distributed"
            else
                echo "   ℹ️  Using local mode with heavy API optimizations"
                mode="local"
            fi
            ;;
    esac

    case "$mode" in
        local)
            echo "   🏠 Local mode with API-heavy optimizations..."
            eval "spark-submit \
                --master 'local[*]' \
                --driver-memory 4g \
                --conf 'spark.driver.maxResultSize=2g' \
                $config_string \
                $dependencies \
                '$py_file'"
            ;;
        distributed)
            if [[ -z "$SPARK_MASTER_URL" ]]; then
                echo "❌ No Spark cluster URL. Run: spark_start"
                return 1
            fi
            echo "   🌐 Distributed mode with API-heavy optimizations..."
            eval "spark-submit \
                --master '$SPARK_MASTER_URL' \
                --deploy-mode client \
                --driver-memory 4g \
                --executor-memory 2g \
                --executor-cores 2 \
                --num-executors 4 \
                --conf 'spark.driver.maxResultSize=2g' \
                $config_string \
                $dependencies \
                '$py_file'"
            ;;
        yarn)
            if ! jps | grep -q ResourceManager; then
                echo "❌ YARN not running. Run: start_hadoop"
                return 1
            fi
            echo "   🎯 YARN mode with API-heavy optimizations and resource management..."
            eval "spark-submit \
                --master yarn \
                --deploy-mode client \
                --driver-memory 4g \
                --executor-memory 2g \
                --executor-cores 2 \
                --num-executors 4 \
                --conf 'spark.driver.maxResultSize=2g' \
                $config_string \
                $dependencies \
                '$py_file'"
            ;;
        *)
            echo "❌ Invalid mode: $mode. Use: auto, local, distributed, yarn"
            return 1
            ;;
    esac

    echo ""
    echo "💡 Heavy API Submit Optimizations Applied:"
    echo "   • Increased timeouts for slow API responses"
    echo "   • Enhanced serialization for complex data structures"
    echo "   • Adaptive query execution for varying data sizes"
    echo "   • Python worker reuse for faster API client initialization"
    echo "   • Reduced logging verbosity for cleaner output"
    echo "   • Optimized for geocoding, web scraping, and API-heavy workloads"
}

function local_heavy_api_submit() {
    local py_file=""
    local extra_paths=()
    local memory_driver="$SPARK_DRIVER_MEMORY"
    local memory_executor="$SPARK_EXECUTOR_MEMORY"
    local master="local[*]"
    local auto_detect_path=true

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --file)
                py_file="$2"
                shift 2
                ;;
            --path)
                extra_paths+=("$2")
                shift 2
                ;;
            --driver-memory)
                memory_driver="$2"
                shift 2
                ;;
            --executor-memory)
                memory_executor="$2"
                shift 2
                ;;
            --master)
                master="$2"
                shift 2
                ;;
            --no-auto-path)
                auto_detect_path=false
                shift
                ;;
            --help|-h)
                echo "Usage: local_heavy_api_submit [OPTIONS] <python_file>"
                echo ""
                echo "Heavy API optimized local Spark submit with path management"
                echo ""
                echo "Options:"
                echo "  --file <file>           Python file to submit (or just pass as first arg)"
                echo "  --path <path>           Add additional Python path for imports"
                echo "  --driver-memory <mem>   Driver memory (default: \$SPARK_DRIVER_MEMORY)"
                echo "  --executor-memory <mem> Executor memory (default: \$SPARK_EXECUTOR_MEMORY)"
                echo "  --master <master>       Spark master (default: local[*])"
                echo "  --no-auto-path         Don't auto-detect script directory"
                echo "  --help, -h             Show this help"
                echo ""
                echo "Examples:"
                echo "  local_heavy_api_submit my_script.py"
                echo "  local_heavy_api_submit --path /my/project --path /other/libs script.py"
                echo "  local_heavy_api_submit --master local[1] --no-auto-path script.py"
                echo ""
                echo "Optimizations:"
                echo "  ✅ Local filesystem only (no HDFS)"
                echo "  ✅ Heavy API workload optimizations (timeouts, serialization)"
                echo "  ✅ Reduced logging verbosity"
                echo "  ✅ Python worker reuse for faster API clients"
                echo "  ✅ Perfect for geocoding, web scraping, API-heavy tasks"
                return 0
                ;;
            -*)
                echo "❌ Unknown option: $1"
                echo "Use --help for usage information"
                return 1
                ;;
            *)
                if [[ -z "$py_file" ]]; then
                    py_file="$1"
                else
                    echo "❌ Multiple files specified: $py_file and $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$py_file" ]]; then
        echo "❌ No Python file specified"
        echo "Usage: local_heavy_api_submit [OPTIONS] <python_file>"
        echo "Use --help for more information"
        return 1
    fi

    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi

    # Auto-detect script directory unless disabled
    if [[ "$auto_detect_path" == true ]]; then
        local script_dir=$(dirname "$(realpath "$py_file")")
        extra_paths=("$script_dir" "${extra_paths[@]}")
    fi

    # Build PYTHONPATH from extra_paths
    local python_path=""
    if [[ ${#extra_paths[@]} -gt 0 ]]; then
        python_path=$(IFS=:; echo "${extra_paths[*]}")
        echo "📁 Adding to PYTHONPATH: $python_path"
    fi

    echo "🚀 Local Heavy API Submit - Optimized for geocoding/API workloads..."
    echo "📄 File: $py_file"
    echo "💾 Driver Memory: $memory_driver"
    echo "⚡ Executor Memory: $memory_executor"
    echo "🎯 Master: $master"

    # Enhanced Heavy API workload optimizations
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
        # LOG CONTROL - Reduce verbosity
        "--conf spark.log.level=ERROR"
        "--conf spark.sql.execution.arrow.pyspark.fallback.enabled=false"
        "--conf spark.ui.showConsoleProgress=false"
        "--conf spark.eventLog.enabled=false"
        "--conf spark.sql.execution.arrow.maxRecordsPerBatch=1000"
        "--conf spark.task.maxFailures=3"
        "--conf spark.stage.maxConsecutiveAttempts=8"
        # UI retention settings
        "--conf spark.sql.ui.retainedExecutions=1"
        "--conf spark.sql.ui.retainedTasks=100"
        "--conf spark.ui.retainedJobs=10"
        "--conf spark.ui.retainedStages=10"
        "--conf spark.worker.ui.retainedExecutors=10"
        "--conf spark.worker.ui.retainedDrivers=10"
        "--conf spark.streaming.ui.retainedBatches=10"
        "--conf spark.eventLog.compress=true"
        # LOCAL-ONLY FIXES - Prevent HDFS connection attempts
        "--conf spark.hadoop.fs.defaultFS=file:///"
        "--conf spark.sql.warehouse.dir=file:///tmp/spark-warehouse"
    )

    # Set environment variables to reduce verbosity
    export SPARK_LOG_LEVEL=ERROR
    export PYTHONHASHSEED=0
    export SPARK_LOCAL_DIRS="/tmp/spark-temp"

    # Create temp directory if it doesn't exist
    mkdir -p "/tmp/spark-temp"

    local dependencies=$(get_spark_dependencies)

    # Build the spark-submit command
    local spark_cmd="spark-submit \
        --master '$master' \
        --driver-memory $memory_driver \
        --executor-memory $memory_executor \
        --conf 'spark.driver.maxResultSize=2g'"

    # Add heavy API configurations
    for config in "${heavy_api_configs[@]}"; do
        spark_cmd="$spark_cmd $config"
    done

    # Add PYTHONPATH if we have extra paths
    if [[ -n "$python_path" ]]; then
        spark_cmd="$spark_cmd \
            --conf spark.executorEnv.PYTHONPATH='$python_path' \
            --conf spark.yarn.appMasterEnv.PYTHONPATH='$python_path'"
    fi

    # Add dependencies and file
    spark_cmd="$spark_cmd $dependencies '$py_file'"

    # Execute the command
    eval "$spark_cmd"

    echo ""
    echo "💡 Local Heavy API Submit Features Applied:"
    echo "   ✅ Local filesystem only (no HDFS connection attempts)"
    echo "   ✅ Python path configured for utilities module"
    echo "   ✅ Increased timeouts for slow API responses (600s)"
    echo "   ✅ Enhanced serialization for complex data structures"
    echo "   ✅ Adaptive query execution for varying data sizes"
    echo "   ✅ Python worker reuse for faster API client initialization"
    echo "   ✅ Reduced logging verbosity for cleaner output"
    echo "   ✅ Optimized for geocoding, web scraping, and API-heavy workloads"
}

# Flexible Spark Submit with All Modes
function flexible_spark_submit {
    local py_file="$1"
    local mode="${2:-smart}"  # smart, local, distributed, yarn, k8s
    if [[ -z "$py_file" ]]; then
        echo "Usage: flexible_spark_submit <python_file> [mode]"
        echo "Modes: smart (default), local, distributed, yarn, k8s"
        return 1
    fi
    case "$mode" in
        smart)
            smart_spark_submit "$py_file"
            ;;
        local)
            default_spark_submit "$py_file"
            ;;
        distributed)
            distributed_spark_submit "$py_file"
            ;;
        yarn)
            spark_yarn_submit "$py_file"
            ;;
        k8s)
            echo "🚀 Kubernetes mode (if configured)..."
            if [[ -z "$SPARK_K8S_MASTER" ]]; then
                echo "❌ Kubernetes not configured. Set SPARK_K8S_MASTER"
                return 1
            fi
            local dependencies=$(get_spark_dependencies)
            eval "spark-submit \
                --master '$SPARK_K8S_MASTER' \
                --deploy-mode cluster \
                --name 'spark-k8s-app' \
                --conf spark.executor.instances=2 \
                --conf spark.kubernetes.container.image='$SPARK_K8S_IMAGE' \
                --conf spark.kubernetes.namespace='$SPARK_K8S_NAMESPACE' \
                --conf spark.kubernetes.authenticate.driver.serviceAccountName='$SPARK_K8S_SERVICE_ACCOUNT' \
                $dependencies \
                '$py_file'"
            ;;
        *)
            echo "❌ Invalid mode: $mode"
            echo "Available modes: smart, local, distributed, yarn, k8s"
            return 1
            ;;
    esac
}

# =====================================================
# TESTING FUNCTIONS
# =====================================================

function spark_test_simple {
    echo "🧪 Quick Spark functionality test..."
    python3 -c "
import sys
try:
    from pyspark.sql import SparkSession
    spark = SparkSession.builder.master('spark://127.0.0.1:7077').appName('QuickTest').getOrCreate()
    result = spark.sparkContext.parallelize([1,2,3,4,5]).sum()
    print(f'✅ Cluster functional: sum = {result}')
    spark.stop()
except Exception as e:
    print(f'❌ Test failed: {e}')
    sys.exit(1)
" 2>/dev/null
}

function test_spark_comprehensive {
    echo "🧪 Comprehensive Spark functionality test (Sedona + GraphFrames)..."
    echo "🔥 RUNNING UPDATED VERSION FROM ARTIFACT - BANANA HAMMOCK! 🔥"
    local test_script="/tmp/spark_comprehensive_test.py"
    cat > "$test_script" << 'EOF'
from pyspark.sql import SparkSession
print("🚀 Starting comprehensive Spark test...")
spark = SparkSession.builder \
    .appName("ComprehensiveSparkTest") \
    .config("spark.sql.extensions", "org.apache.sedona.sql.SedonaSqlExtensions") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.kryo.registrator", "org.apache.sedona.core.serde.SedonaKryoRegistrator") \
    .getOrCreate()
print("✅ Spark Context created successfully")
print(f"   Master: {spark.sparkContext.master}")
print(f"   Default Parallelism: {spark.sparkContext.defaultParallelism}")
print("\n🔍 Test 1: Basic RDD operations...")
rdd = spark.sparkContext.parallelize(range(100), 4)
result = rdd.map(lambda x: x * x).sum()
print(f"   ✅ RDD computation result: {result}")
print("\n🔍 Test 2: DataFrame operations...")
df = spark.range(100)
count = df.count()
print(f"   ✅ DataFrame count: {count}")
print("\n🔍 Test 3: SQL operations...")
df.createOrReplaceTempView("test_table")
sql_result = spark.sql("SELECT COUNT(*) as count FROM test_table").collect()[0]["count"]
print(f"   ✅ SQL result: {sql_result}")
print("\n🔍 Test 4: Sedona functionality...")
sedona_works = False
try:
    # Modern Sedona 1.7.1+ initialization
    from sedona.spark import SedonaContext
    sedona = SedonaContext.create(spark)
    print("   ✅ Sedona context created (modern method)")
    # Test basic spatial function
    point_result = sedona.sql("SELECT ST_Point(1.0, 2.0) as point").collect()
    print("   ✅ Sedona ST_Point works")
    # Test distance calculation
    distance_result = sedona.sql("""
        SELECT ST_Distance(
            ST_Point(-0.1275, 51.5072),
            ST_Point(-74.0060, 40.7128)
        ) as distance_degrees
    """).collect()[0]["distance_degrees"]
    print(f"   ✅ Sedona distance calculation: {distance_result:.4f} degrees")
    # Test spatial operations with DataFrame
    spatial_df = sedona.createDataFrame([
        ("London", -0.1275, 51.5072),
        ("NYC", -74.0060, 40.7128),
    ], ["city", "longitude", "latitude"])
    spatial_with_geom = spatial_df.selectExpr(
        "city",
        "ST_Point(longitude, latitude) as geom"
    )
    geom_count = spatial_with_geom.count()
    print(f"   ✅ Sedona DataFrame operations: {geom_count} geometries created")
    sedona_works = True
except Exception as e:
    print(f"   ⚠️  Sedona failed: {e}")
print("\n🔍 Test 5: GraphFrames functionality...")
graphframes_works = False
try:
    from graphframes import GraphFrame
    vertices = spark.createDataFrame([("A", "Node A"), ("B", "Node B"), ("C", "Node C")], ["id", "name"])
    edges = spark.createDataFrame([("A", "B", "edge1"), ("B", "C", "edge2")], ["src", "dst", "relationship"])
    g = GraphFrame(vertices, edges)
    v_count = g.vertices.count()
    e_count = g.edges.count()
    print(f"   ✅ GraphFrame created with {v_count} vertices, {e_count} edges")
    # Test PageRank
    pagerank_result = g.pageRank(resetProbability=0.01, maxIter=2)
    pr_vertices = pagerank_result.vertices.count()
    print(f"   ✅ PageRank completed: {pr_vertices} vertices processed")
    graphframes_works = True
except Exception as e:
    print(f"   ⚠️  GraphFrames failed: {e}")
print("\n🎉 Summary:")
print("   ✅ Core Spark: Working")
print(f"   {'✅' if sedona_works else '⚠️ '} Sedona: {'Working (Modern)' if sedona_works else 'Failed'}")
print(f"   {'✅' if graphframes_works else '⚠️ '} GraphFrames: {'Working' if graphframes_works else 'Failed'}")
spark.stop()
print("🛑 Test completed")
EOF
    echo "Running test..."
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        distributed_spark_submit "$test_script"
    else
        default_spark_submit "$test_script"
    fi
    rm -f "$test_script"
}

# =====================================================
# PYSPARK VERSION SYNCHRONIZATION
# =====================================================

function sync_pyspark_version() {
    # Automatically sync pip PySpark version with bundled Spark version.
    # Prevents version conflicts between SDKMAN Spark and pip PySpark.
    local force_reinstall=false
    local use_bundled_only=false
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_reinstall=true
                shift
                ;;
            --bundled-only)
                use_bundled_only=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h)
                echo "Usage: sync_pyspark_version [OPTIONS]"
                echo ""
                echo "Automatically sync PySpark versions to prevent conflicts"
                echo ""
                echo "Options:"
                echo "  --force          Force reinstall even if versions match"
                echo "  --bundled-only   Remove pip PySpark, use only bundled version"
                echo "  --verbose, -v    Verbose output"
                echo "  --help, -h       Show this help"
                echo ""
                echo "Examples:"
                echo "  sync_pyspark_version              # Auto-sync versions"
                echo "  sync_pyspark_version --force      # Force reinstall"
                echo "  sync_pyspark_version --bundled-only  # Use only SDKMAN bundled PySpark"
                return 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "Use --help for usage information"
                return 1
                ;;
        esac
    done

    echo "🔄 PySpark Version Synchronization"
    echo "=================================================="

    # Check if SPARK_HOME is set
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set. Ensure Spark is properly configured."
        return 1
    fi

    # Get bundled Spark version
    local spark_version=""
    if [[ -f "$SPARK_HOME/bin/spark-submit" ]]; then
        # Extract version from spark-submit output
        spark_version=$($SPARK_HOME/bin/spark-submit --version 2>&1 | grep -o "version [0-9]\+\.[0-9]\+\.[0-9]\+" | head -1 | cut -d' ' -f2)
    fi

    if [[ -z "$spark_version" ]]; then
        echo "❌ Could not detect Spark version from $SPARK_HOME"
        return 1
    fi

    echo "✅ Detected Spark version: $spark_version"
    [[ "$verbose" == true ]] && echo "   SPARK_HOME: $SPARK_HOME"

    # Check current pip PySpark version
    local pip_pyspark_version=""
    local pip_py4j_version=""

    if python -c "import pyspark" 2>/dev/null; then
        pip_pyspark_version=$(python -c "import pyspark; print(pyspark.__version__)" 2>/dev/null || echo "")
        pip_py4j_version=$(python -c "import py4j; print(py4j.__version__)" 2>/dev/null || echo "")
    fi

    echo "📦 Current Python environment status:"
    echo "   PySpark: ${pip_pyspark_version:-'Not installed'}"
    echo "   Py4J: ${pip_py4j_version:-'Not installed'}"

    # Check bundled PySpark version
    local bundled_pyspark_version=""
    if [[ -f "$SPARK_HOME/python/pyspark/__init__.py" ]]; then
        # Extract version from bundled PySpark
        bundled_pyspark_version=$(python -c "
import sys
sys.path.insert(0, '$SPARK_HOME/python')
try:
    import pyspark
    print(pyspark.__version__)
except:
    print('')
" 2>/dev/null)
    fi

    echo "   Bundled PySpark: ${bundled_pyspark_version:-'Not found'}"

    # Handle --bundled-only option
    if [[ "$use_bundled_only" == true ]]; then
        echo ""
        echo "🎯 Using bundled-only mode..."
        if [[ -n "$pip_pyspark_version" ]]; then
            echo "🗑️  Removing pip PySpark packages..."
            pip uninstall pyspark py4j pyspark-stubs -y -q
            echo "✅ Pip PySpark removed"
        else
            echo "ℹ️  No pip PySpark to remove"
        fi

        if [[ -n "$bundled_pyspark_version" ]]; then
            echo "✅ Using bundled PySpark $bundled_pyspark_version"
            echo ""
            echo "💡 To use bundled PySpark in scripts, add:"
            echo "   import sys"
            echo "   sys.path.insert(0, '$SPARK_HOME/python')"
            echo "   sys.path.insert(0, '$SPARK_HOME/python/lib/py4j-*-src.zip')"
        else
            echo "❌ No bundled PySpark found!"
            return 1
        fi
        return 0
    fi

    # Determine target PySpark version (prefer bundled, fallback to Spark version)
    local target_pyspark_version="$bundled_pyspark_version"
    if [[ -z "$target_pyspark_version" ]]; then
        target_pyspark_version="$spark_version"
        echo "⚠️  No bundled PySpark found, using Spark version as target"
    fi

    echo ""
    echo "🎯 Target PySpark version: $target_pyspark_version"

    # Check if we need to update
    local needs_update=false
    if [[ "$force_reinstall" == true ]]; then
        echo "🔄 Force reinstall requested"
        needs_update=true
    elif [[ -z "$pip_pyspark_version" ]]; then
        echo "📦 PySpark not installed via pip"
        needs_update=true
    elif [[ "$pip_pyspark_version" != "$target_pyspark_version" ]]; then
        echo "⚠️  Version mismatch: $pip_pyspark_version → $target_pyspark_version"
        needs_update=true
    else
        echo "✅ PySpark version already matches ($pip_pyspark_version)"
    fi

    if [[ "$needs_update" == true ]]; then
        echo ""
        echo "🔄 Installing PySpark $target_pyspark_version..."

        # Uninstall conflicting packages
        if [[ -n "$pip_pyspark_version" ]]; then
            echo "   Removing existing PySpark packages..."
            pip uninstall pyspark py4j pyspark-stubs -y -q
        fi

        # Install target version
        echo "   Installing PySpark $target_pyspark_version..."
        if pip install "pyspark==$target_pyspark_version" -q; then
            echo "✅ PySpark $target_pyspark_version installed successfully"
        else
            echo "❌ Failed to install PySpark $target_pyspark_version"
            echo "💡 Try: sync_pyspark_version --bundled-only"
            return 1
        fi

        # Verify installation
        local new_version=$(python -c "import pyspark; print(pyspark.__version__)" 2>/dev/null || echo "")
        if [[ "$new_version" == "$target_pyspark_version" ]]; then
            echo "✅ Installation verified: PySpark $new_version"
        else
            echo "⚠️  Installation verification failed (got: $new_version)"
        fi
    fi

    echo ""
    echo "🧪 Testing PySpark functionality..."
    if python -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName('sync-test').master('local[1]').getOrCreate()
df = spark.createDataFrame([(1, 'test')], ['id', 'name'])
count = df.count()
spark.stop()
print(f'✅ PySpark test successful: {count} rows')
" 2>/dev/null; then
        echo "✅ PySpark sync completed successfully!"
    else
        echo "❌ PySpark test failed after sync"
        echo "💡 Try: sync_pyspark_version --bundled-only"
        return 1
    fi

    echo ""
    echo "📋 Final Status:"
    echo "   Spark: $spark_version"
    echo "   PySpark: $(python -c "import pyspark; print(pyspark.__version__)" 2>/dev/null || echo 'Error')"
    echo "   Java: $(java -version 2>&1 | head -1 | cut -d'"' -f2)"
    echo ""
    echo "💡 Your PySpark environment is now synchronized!"
}

function check_pyspark_sync() {
    # Quick check if PySpark versions are in sync.
    # Returns 0 if synced, 1 if not synced.
    local quiet=false

    if [[ "$1" == "--quiet" || "$1" == "-q" ]]; then
        quiet=true
    fi

    if [[ -z "$SPARK_HOME" ]]; then
        [[ "$quiet" != true ]] && echo "❌ SPARK_HOME not set"
        return 1
    fi

    local spark_version=$($SPARK_HOME/bin/spark-submit --version 2>&1 | grep -o "version [0-9]\+\.[0-9]\+\.[0-9]\+" | head -1 | cut -d' ' -f2)
    local pip_pyspark_version=$(python -c "import pyspark; print(pyspark.__version__)" 2>/dev/null || echo "")

    if [[ -z "$spark_version" ]]; then
        [[ "$quiet" != true ]] && echo "❌ Could not detect Spark version"
        return 1
    fi

    if [[ -z "$pip_pyspark_version" ]]; then
        [[ "$quiet" != true ]] && echo "⚠️  No pip PySpark installed"
        return 1
    fi

    if [[ "$spark_version" == "$pip_pyspark_version" ]]; then
        [[ "$quiet" != true ]] && echo "✅ PySpark versions in sync ($spark_version)"
        return 0
    else
        [[ "$quiet" != true ]] && echo "❌ Version mismatch: Spark $spark_version, PySpark $pip_pyspark_version"
        return 1
    fi
}

function auto_sync_pyspark() {
    # Automatically sync PySpark if versions don't match.
    # Safe to call in .zshrc or before Spark operations.
    if ! check_pyspark_sync --quiet 2>/dev/null; then
        echo "🔄 Auto-syncing PySpark versions..."
        sync_pyspark_version
    fi
}

# Add convenience aliases
alias sync-pyspark='sync_pyspark_version'
alias check-pyspark-sync='check_pyspark_sync'
alias pyspark-bundled='sync_pyspark_version --bundled-only'

# Add to existing show_spark_config function
function show_spark_config() {
    # ... your existing show_spark_config content ...

    echo ""
    echo "🔄 PySpark Sync Functions:"
    echo "   sync_pyspark_version     - Sync pip PySpark with bundled Spark version"
    echo "   check_pyspark_sync       - Check if versions are in sync"
    echo "   auto_sync_pyspark        - Auto-sync if needed (safe for automation)"
    echo "   sync-pyspark             - Alias for sync_pyspark_version"
    echo "   pyspark-bundled          - Use only bundled PySpark (remove pip version)"
}

# =====================================================
# SPARK CONFIGURATION
# =====================================================

function spark_fix_logging {
    echo "🔧 Reducing Spark logging noise..."
    # Create log4j2.properties to reduce INFO spam
    cat > $SPARK_HOME/conf/log4j2.properties << 'EOF'
# Reduce Spark logging noise
rootLogger.level = WARN
rootLogger.appenderRefs = stdout
rootLogger.appenderRef.stdout.ref = console
appender.console.type = Console
appender.console.name = console
appender.console.target = SYSTEM_ERR
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n
# Set Spark components to WARN
logger.spark.name = org.apache.spark
logger.spark.level = WARN
logger.hadoop.name = org.apache.hadoop
logger.hadoop.level = WARN
logger.akka.name = akka
logger.akka.level = WARN
logger.jetty.name = org.eclipse.jetty
logger.jetty.level = WARN
EOF
    echo "✅ Logging reduced to WARN level"
}

function show_spark_config() {
    echo "⚙️  Enhanced Spark Configuration:"
    echo ""
    echo "🏠 Environment:"
    echo "   SPARK_HOME: ${SPARK_HOME:-'Not set'}"
    echo "   SPARK_MASTER_URL: ${SPARK_MASTER_URL:-'Not set'}"
    echo "   Java: ${JAVA_HOME:-'Not set'}"
    echo "   Hadoop: ${HADOOP_HOME:-'Not set'}"
    echo ""
    echo "📦 Dependencies:"
    echo "   Online status: $(is_online)"
    echo "   Default JARs: $DEFAULT_SPARK_JARS"
    echo "   Local JAR path: $LOCAL_SPARK_JAR_PATH"
    echo "   Local JARs available: $(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | wc -l)"
    echo ""
    echo "💡 Available functions:"
    echo "   # Core Spark functions"
    echo "   default_spark_submit     - Local with dependency resolution"
    echo "   distributed_spark_submit - Cluster with dependency resolution"
    echo "   smart_spark_submit       - Auto-detect execution environment"
    echo "   spark_yarn_submit        - Submit to YARN cluster"
    echo "   heavy_api_submit         - Optimized for API-heavy workloads (geocoding, web scraping)"
    echo "   local_heavy_api_submit   - Enhanced local submit with path management"
    echo "   flexible_spark_submit    - Multi-mode execution (local/distributed/yarn/k8s/smart)"
    echo ""
    echo "   # Testing & diagnostics"
    echo "   test_spark_comprehensive - Full Sedona + GraphFrames test"
    echo "   test_spark_dependencies  - Test dependency resolution"
    echo "   spark_test_simple        - Quick cluster test"
}

# =====================================================
# BACKWARDS COMPATIBILITY & CONVENIENCE ALIASES
# =====================================================

function spark_submit_local {
    default_spark_submit "$@"
}
function spark_submit_cluster {
    distributed_spark_submit "$@"
}
function graceful_spark_restart {
    spark_restart
}
function start_local_spark_cluster {
    spark_start
}
function stop_local_spark_cluster {
    spark_stop
}
function check_spark_cluster_health {
    spark_status
}

# Convenience aliases for different use cases
alias lhas='local_heavy_api_submit'
alias lhas1='local_heavy_api_submit --master local[1]'  # Single-threaded debugging
alias lhas_debug='local_heavy_api_submit --master local[1]'  # Same as above, clearer name

alias sstart='spark_start'
alias sstop='spark_stop'
alias srestart='spark_restart'
alias sstatus='spark_status'
alias ssubmit='default_spark_submit'
alias dsubmit='distributed_spark_submit'
alias hsubmit='heavy_api_submit'
alias stest='test_spark_comprehensive'

# Auto-fix logging on module load
spark_fix_logging 2>/dev/null || true

echo "⚡ Spark module loaded with FULL functionality - $(spark-submit --version 2>&1 | head -1 || echo 'Spark ready')"
