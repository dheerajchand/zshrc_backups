#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_spark_health_defined() {
    source "$ROOT_DIR/modules/spark.zsh"
    assert_true "typeset -f spark_health >/dev/null 2>&1" "spark_health should be defined"
}

test_hadoop_health_defined() {
    source "$ROOT_DIR/modules/hadoop.zsh"
    assert_true "typeset -f hadoop_health >/dev/null 2>&1" "hadoop_health should be defined"
    assert_true "typeset -f yarn_health >/dev/null 2>&1" "yarn_health should be defined"
}

test_spark_home_sdkman_preferred() {
    local out
    if [[ ! -d "$HOME/.sdkman/candidates/spark/current" ]]; then
        return 0
    fi
    out="$(ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; print -r -- \"\$SPARK_HOME\"" | tail -n 1)"
    assert_equal "$HOME/.sdkman/candidates/spark/current" "$out" "should prefer SDKMAN Spark path"
}

test_hadoop_home_sdkman_preferred() {
    local out
    if [[ ! -d "$HOME/.sdkman/candidates/hadoop/current" ]]; then
        return 0
    fi
    out="$(ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/hadoop.zsh; print -r -- \"\$HADOOP_HOME\"" | tail -n 1)"
    assert_equal "$HOME/.sdkman/candidates/hadoop/current" "$out" "should prefer SDKMAN Hadoop path"
}

register_test "test_spark_home_sdkman_preferred" "test_spark_home_sdkman_preferred"
register_test "test_hadoop_home_sdkman_preferred" "test_hadoop_home_sdkman_preferred"
register_test "test_spark_health_defined" "test_spark_health_defined"
register_test "test_hadoop_health_defined" "test_hadoop_health_defined"
