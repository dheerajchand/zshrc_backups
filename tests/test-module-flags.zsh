#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

# Extract the registry, loader, and status renderer for isolated tests
# without sourcing the rest of the config.
_extract_load_module() {
    awk '/^# Shared startup groups/,/^# ===/ { if (/^# ===/) exit; print }' "$ROOT_DIR/zshrc"
    awk '/^modules\(\)/,/^\}/' "$ROOT_DIR/zshrc"
}

test_load_module_honors_disable_flag() {
    # With ZSH_DISABLE_<NAME>=1, the module should NOT be sourced.
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_FROM_FAKE_MODULE' > "$tmp/modules/fake.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_DISABLE_FAKE=1 zsh -fc "$loader; load_module fake")"
    rm -rf "$tmp"
    assert_equal "" "$out" "ZSH_DISABLE_FAKE=1 should skip the module source"
}

test_load_module_loads_when_flag_unset() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_FROM_FAKE_MODULE' > "$tmp/modules/fake.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" zsh -fc "$loader; load_module fake")"
    rm -rf "$tmp"
    assert_equal "LOADED_FROM_FAKE_MODULE" "$out" "load_module should source by default"
}

test_load_module_flag_maps_hyphen_to_underscore() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_HYPHEN' > "$tmp/modules/my-module.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_DISABLE_MY_MODULE=1 zsh -fc "$loader; load_module my-module")"
    rm -rf "$tmp"
    assert_equal "" "$out" "hyphens should map to underscores in the flag name"
}

register_test "load_module_honors_disable_flag" test_load_module_honors_disable_flag
register_test "load_module_loads_when_flag_unset" test_load_module_loads_when_flag_unset
register_test "load_module_flag_maps_hyphen_to_underscore" test_load_module_flag_maps_hyphen_to_underscore

test_module_status_tracks_load_results() {
    local tmp out loader
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    print -r -- 'return 0' > "$tmp/modules/working.zsh"
    print -r -- 'return 7' > "$tmp/modules/broken.zsh"
    print -r -- 'print SHOULD_NOT_LOAD' > "$tmp/modules/disabled.zsh"
    loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_DISABLE_DISABLED=1 zsh -fuc "$loader"'
        load_module working
        load_module broken
        print -- "FAILURE_RC=$?"
        load_module absent
        print -- "MISSING_RC=$?"
        load_module disabled
        modules
    ' 2>&1)"
    assert_contains "$out" 'working            Loaded' "successful source is listed without description metadata"
    assert_contains "$out" 'broken             Load failed (exit 7)' "source errors are recorded"
    assert_contains "$out" 'FAILURE_RC=7' "loader preserves source return code"
    assert_contains "$out" 'absent             File missing' "missing file is listed"
    assert_contains "$out" 'MISSING_RC=1' "missing file returns failure"
    assert_contains "$out" 'disabled           Disabled' "disabled module is listed as skipped"
    assert_not_contains "$out" 'SHOULD_NOT_LOAD' "disabled module is never sourced"
    rm -rf "$tmp"
}

test_module_status_updates_without_duplicates() {
    local tmp out loader
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    print -r -- 'return 9' > "$tmp/modules/retry.zsh"
    loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" zsh -fuc "$loader"'
        load_module retry
        print -- "BEFORE=${_zsh_module_state[retry]}"
        print -- "return 0" > "$ZSH_CONFIG_DIR/modules/retry.zsh"
        load_module retry
        load_module retry
        print -- "AFTER=${_zsh_module_state[retry]} RC=${_zsh_module_result[retry]}"
        modules
    ')"
    assert_contains "$out" 'BEFORE=failed' "initial load failure is recorded"
    assert_contains "$out" 'AFTER=loaded RC=0' "retry replaces stale failure state"
    assert_equal 1 "$(print -r -- "$out" | grep -c 'retry .*Loaded')" "reloading does not duplicate listing entries"
    assert_not_contains "$out" 'Load failed' "listing uses the latest result"
    rm -rf "$tmp"
}

register_test module_status_tracks_load_results test_module_status_tracks_load_results
register_test module_status_updates_without_duplicates test_module_status_updates_without_duplicates

test_module_secrets_quiet_load_succeeds() {
    local tmp out loader
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    # Exercise the real initialization footer without accessing credentials.
    print -r -- 'load_secrets() { :; }; _secrets_auto_signin_all_on_load() { :; }; _secrets_check_profile() { :; }' > "$tmp/modules/secrets.zsh"
    sed -n '/^# Auto-load secrets/,$p' "$ROOT_DIR/modules/secrets.zsh" >> "$tmp/modules/secrets.zsh"
    loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_TEST_MODE= ZSH_SECRETS_VERBOSE=0 zsh -fuc "$loader"'
        load_module secrets
        print -- "RC=$? STATE=${_zsh_module_state[secrets]}"
    ')"
    assert_equal 'RC=0 STATE=loaded' "$out" "quiet secrets startup is successful and silent"
    rm -rf "$tmp"
}

register_test module_secrets_quiet_load_succeeds test_module_secrets_quiet_load_succeeds
