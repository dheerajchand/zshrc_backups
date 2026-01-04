#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/system_diagnostics.zsh"

test_icloud_status_missing_tools() {
    local old_path="$PATH"
    local tmp
    tmp="$(mktemp -d)"
    PATH="$tmp"
    local out
    out="$(icloud_status 2>/dev/null || true)"
    assert_contains "$out" "brctl not found" "brctl missing should be reported"
    assert_contains "$out" "fileproviderctl not found" "fileproviderctl missing should be reported"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_icloud_preflight_no_brctl() {
    local old_path="$PATH"
    local tmp
    tmp="$(mktemp -d)"
    PATH="$tmp"
    local out
    out="$(icloud_preflight 2>/dev/null || true)"
    local rc=$?
    assert_equal "0" "$rc" "preflight should return success without brctl"
    assert_contains "$out" "brctl not found" "preflight should mention missing brctl"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_icloud_reset_state_non_interactive() {
    local old_ps1="${PS1-}"
    unset PS1
    local out
    out="$(icloud_reset_state 2>/dev/null)"
    local rc=$?
    assert_equal "1" "$rc" "reset should refuse in non-interactive shell"
    assert_contains "$out" "Refusing to run in non-interactive shell" "should refuse non-interactive run"
    PS1="$old_ps1"
}

test_dropbox_restart_test_mode() {
    ZSH_TEST_MODE=1
    local out
    out="$(dropbox_restart 2>/dev/null || true)"
    local rc=$?
    assert_equal "0" "$rc" "dropbox_restart should succeed in test mode"
    assert_contains "$out" "Test mode: would restart Dropbox." "test mode should skip action"
    unset ZSH_TEST_MODE
}

register_test "test_icloud_status_missing_tools" "test_icloud_status_missing_tools"
register_test "test_icloud_preflight_no_brctl" "test_icloud_preflight_no_brctl"
register_test "test_icloud_reset_state_non_interactive" "test_icloud_reset_state_non_interactive"
register_test "test_dropbox_restart_test_mode" "test_dropbox_restart_test_mode"
