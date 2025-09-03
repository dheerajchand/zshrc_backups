#!/usr/bin/env zsh

# =============================================================================
# Test Integration with Backup System
# =============================================================================

# Add test functions to backup system
test_backup_system() {
    echo "🧪 Testing backup system functions..."
    
    # Test deduplicate_path
    local original_path="$PATH"
    local test_path="/usr/bin:/usr/local/bin:/usr/bin:/opt/homebrew/bin:/usr/bin"
    PATH="$test_path"
    deduplicate_path
    local path_count=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d | wc -l)
    if [[ $path_count -eq 0 ]]; then
        echo "✅ deduplicate_path: PASSED"
    else
        echo "❌ deduplicate_path: FAILED"
    fi
    PATH="$original_path"
    
    # Test get_backup_path
    local backup_path=$(get_backup_path)
    if [[ -n "$backup_path" && "$backup_path" == *"$ZSHRC_BACKUPS"* ]]; then
        echo "✅ get_backup_path: PASSED"
    else
        echo "❌ get_backup_path: FAILED"
    fi
    
    # Test environment variables
    if [[ -n "$ZSHRC_BACKUPS" && -n "$PATH_DEDUPLICATION_ENABLED" ]]; then
        echo "✅ Environment variables: PASSED"
    else
        echo "❌ Environment variables: FAILED"
    fi
    
    echo "🧪 Backup system tests completed"
}

# Add test functions to Python system
test_python_system() {
    echo "🧪 Testing Python system functions..."
    
    # Test setup_pyenv
    setup_pyenv
    if [[ -n "$PYENV_ROOT" && "$PATH" == *"$PYENV_ROOT/bin"* ]]; then
        echo "✅ setup_pyenv: PASSED"
    else
        echo "❌ setup_pyenv: FAILED"
    fi
    
    # Test setup_uv
    setup_uv
    if command -v uv >/dev/null 2>&1; then
        echo "✅ setup_uv: PASSED"
    else
        echo "❌ setup_uv: FAILED (uv not installed)"
    fi
    
    # Test python_status
    local status_output=$(python_status 2>&1)
    if [[ "$status_output" == *"Python Environment Status"* ]]; then
        echo "✅ python_status: PASSED"
    else
        echo "❌ python_status: FAILED"
    fi
    
    echo "🧪 Python system tests completed"
}

# Add test functions to bash compatibility
test_bash_compatibility() {
    echo "🧪 Testing bash compatibility functions..."
    
    # Test shell detection
    local detected_shell=$(detect_shell)
    if [[ "$detected_shell" == "zsh" ]]; then
        echo "✅ detect_shell: PASSED"
    else
        echo "❌ detect_shell: FAILED"
    fi
    
    # Test platform detection
    local detected_platform=$(detect_platform)
    if [[ "$detected_platform" == "macos" ]]; then
        echo "✅ detect_platform: PASSED"
    else
        echo "❌ detect_platform: FAILED"
    fi
    
    # Test compatibility initialization
    init_compatibility
    if [[ "$CURRENT_SHELL" == "zsh" && "$PLATFORM" == "macos" && "$IS_ZSH" == "true" ]]; then
        echo "✅ init_compatibility: PASSED"
    else
        echo "❌ init_compatibility: FAILED"
    fi
    
    echo "🧪 Bash compatibility tests completed"
}

# Add test functions to Spark system
test_spark_system() {
    echo "🧪 Testing Spark system functions..."
    
    # Test Spark setup
    setup_spark
    if [[ -n "$SPARK_HOME" && "$PATH" == *"$SPARK_HOME/bin"* ]]; then
        echo "✅ setup_spark: PASSED"
    else
        echo "❌ setup_spark: FAILED"
    fi
    
    # Test Hadoop setup
    setup_hadoop
    if [[ -n "$HADOOP_HOME" && "$PATH" == *"$HADOOP_HOME/bin"* ]]; then
        echo "✅ setup_hadoop: PASSED"
    else
        echo "❌ setup_hadoop: FAILED"
    fi
    
    # Test YARN setup
    setup_yarn
    if [[ -n "$YARN_HOME" && "$PATH" == *"$YARN_HOME/bin"* ]]; then
        echo "✅ setup_yarn: PASSED"
    else
        echo "❌ setup_yarn: FAILED"
    fi
    
    # Test Spark config display
    local config_output=$(show_spark_config 2>&1)
    if [[ "$config_output" == *"Spark Configuration"* ]]; then
        echo "✅ show_spark_config: PASSED"
    else
        echo "❌ show_spark_config: FAILED"
    fi
    
    echo "🧪 Spark system tests completed"
}

# Add test functions to Jupyter system
test_jupyter_system() {
    echo "🧪 Testing Jupyter system functions..."
    
    # Test Jupyter setup
    setup_jupyter
    if [[ -n "$JUPYTER_HOME" && "$PATH" == *"$JUPYTER_HOME/bin"* ]]; then
        echo "✅ setup_jupyter: PASSED"
    else
        echo "❌ setup_jupyter: FAILED"
    fi
    
    # Test Jupyter status
    local status_output=$(jupyter_status 2>&1)
    if [[ "$status_output" == *"Jupyter"* ]]; then
        echo "✅ jupyter_status: PASSED"
    else
        echo "❌ jupyter_status: FAILED"
    fi
    
    echo "🧪 Jupyter system tests completed"
}

# Add test functions to JVM system
test_jvm_system() {
    echo "🧪 Testing JVM system functions..."
    
    # Test Java environment
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -1)
        if [[ "$java_version" == *"version"* ]]; then
            echo "✅ Java environment: PASSED"
        else
            echo "❌ Java environment: FAILED"
        fi
    else
        echo "⚠️  Java not available - skipping Java tests"
    fi
    
    # Test Hadoop setup
    setup_hadoop
    if [[ -n "$HADOOP_HOME" && "$PATH" == *"$HADOOP_HOME/bin"* ]]; then
        echo "✅ setup_hadoop: PASSED"
    else
        echo "❌ setup_hadoop: FAILED"
    fi
    
    # Test YARN setup
    setup_yarn
    if [[ -n "$YARN_HOME" && "$PATH" == *"$YARN_HOME/bin"* ]]; then
        echo "✅ setup_yarn: PASSED"
    else
        echo "❌ setup_yarn: FAILED"
    fi
    
    # Test HDFS availability
    if command -v hdfs >/dev/null 2>&1; then
        echo "✅ HDFS: PASSED"
    else
        echo "⚠️  HDFS not available"
    fi
    
    # Test MapReduce availability
    if command -v hadoop >/dev/null 2>&1; then
        echo "✅ MapReduce: PASSED"
    else
        echo "⚠️  MapReduce not available"
    fi
    
    echo "🧪 JVM system tests completed"
}

# Run all quick tests
run_quick_tests() {
    echo "🚀 Running quick system tests..."
    echo ""
    
    test_backup_system
    echo ""
    test_python_system
    echo ""
    test_bash_compatibility
    echo ""
    test_spark_system
    echo ""
    test_jupyter_system
    echo ""
    test_jvm_system
    echo ""
    
    echo "🎉 Quick tests completed!"
}

# Add test command to help system
alias test_system='run_quick_tests'
alias test_backup='test_backup_system'
alias test_python='test_python_system'
alias test_compatibility='test_bash_compatibility'
alias test_spark='test_spark_system'
alias test_jupyter='test_jupyter_system'
alias test_jvm='test_jvm_system'
