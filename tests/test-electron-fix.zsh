#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/agents.zsh"

# =================================================================
# Helpers — mock external commands for the test environment
# =================================================================

_efix_setup() {
    local tmp
    tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    mkdir -p "$bin"

    # Zero out sleeps in the function under test
    export ELECTRON_FIX_KILL_DELAY=0
    export ELECTRON_FIX_LAUNCH_DELAY=0

    # Mock killall — just log
    cat > "$bin/killall" <<'STUB'
#!/usr/bin/env zsh
echo "killall $*" >> "$EFIX_LOG"
STUB
    chmod +x "$bin/killall"

    # Mock open — just log
    cat > "$bin/open" <<'STUB'
#!/usr/bin/env zsh
echo "open $*" >> "$EFIX_LOG"
STUB
    chmod +x "$bin/open"

    # Mock osascript — return configurable window count
    cat > "$bin/osascript" <<'STUB'
#!/usr/bin/env zsh
echo "${EFIX_MOCK_WCOUNT:-1}"
STUB
    chmod +x "$bin/osascript"

    export EFIX_TMP="$tmp"
    export EFIX_LOG="$tmp/commands.log"
    export EFIX_BIN="$bin"
    : > "$EFIX_LOG"
}

_efix_teardown() {
    rm -rf "$EFIX_TMP"
    unset EFIX_TMP EFIX_LOG EFIX_BIN EFIX_MOCK_WCOUNT
    unset ELECTRON_FIX_KILL_DELAY ELECTRON_FIX_LAUNCH_DELAY
}

# =================================================================
# Tests — _electron_fix_window
# =================================================================

test_efix_missing_args_fails() {
    local out
    out="$(_electron_fix_window 2>&1)"
    local rc=$?
    assert_true "[[ $rc -ne 0 ]]" "should fail with no arguments"
    assert_contains "$out" "Usage" "should print usage"
}

test_efix_standalone_writes_state_file() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_true "[[ -f '$state_file' ]]" "should create state file"
    assert_contains "$(cat "$state_file")" "1200" "state file should contain default bounds"
    _efix_teardown
}

test_efix_standalone_with_state_builder() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"

    _test_builder() {
        echo '{"windows":[{"id":"custom","bounds":{"x":50,"y":50,"width":800,"height":600}}]}'
    }

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone \
        --state-builder _test_builder >/dev/null 2>&1

    assert_contains "$(cat "$state_file")" '"id":"custom"' "should use state builder output"
    assert_contains "$(cat "$state_file")" "800" "should contain builder-specified width"

    unfunction _test_builder
    _efix_teardown
}

test_efix_embedded_patches_key() {
    skip_if_missing python3
    _efix_setup
    local state_file="$EFIX_TMP/prefs.json"

    # Seed an existing prefs file with other data
    cat > "$state_file" <<'EOF'
{
  "theme": "dark",
  "windowBounds": {"x": 9999, "y": 9999, "width": 10, "height": 10},
  "otherSetting": true
}
EOF

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format embedded \
        --state-key "windowBounds" >/dev/null 2>&1

    # The key should be overwritten with default bounds
    assert_contains "$(cat "$state_file")" "1200" "embedded key should have new bounds"
    # Other keys should be preserved
    assert_contains "$(cat "$state_file")" '"theme": "dark"' "should preserve other keys"
    assert_contains "$(cat "$state_file")" '"otherSetting": true' "should preserve other settings"
    _efix_teardown
}

test_efix_embedded_requires_state_key() {
    _efix_setup
    local state_file="$EFIX_TMP/prefs.json"
    echo '{}' > "$state_file"

    local out
    out="$(PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format embedded 2>&1)"
    local rc=$?

    assert_true "[[ $rc -ne 0 ]]" "should fail without --state-key"
    assert_contains "$out" "state-key" "should mention missing state-key"
    _efix_teardown
}

test_efix_embedded_missing_file_fails() {
    _efix_setup

    local out
    out="$(PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$EFIX_TMP/nonexistent.json" \
        --state-format embedded \
        --state-key "bounds" 2>&1)"
    local rc=$?

    assert_true "[[ $rc -ne 0 ]]" "should fail when state file does not exist"
    assert_contains "$out" "not found" "should report file not found"
    _efix_teardown
}

test_efix_kills_app() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_contains "$(cat "$EFIX_LOG")" "killall TestApp" "should kill the app process"
    _efix_teardown
}

test_efix_uses_process_name_override() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --process-name "TestElectron" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_contains "$(cat "$EFIX_LOG")" "killall TestElectron" "should kill using process-name"
    assert_not_contains "$(cat "$EFIX_LOG")" "killall TestApp" "should not use app-name for kill"
    _efix_teardown
}

test_efix_removes_lock_files() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"
    local lock1="$EFIX_TMP/.server.lock"
    local lock2="$EFIX_TMP/SingletonLock"
    echo "123" > "$lock1"
    echo "456" > "$lock2"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone \
        --lock-file "$lock1" \
        --lock-file "$lock2" >/dev/null 2>&1

    assert_false "[[ -f '$lock1' ]]" "first lock file should be removed"
    assert_false "[[ -f '$lock2' ]]" "second lock file should be removed"
    _efix_teardown
}

test_efix_relaunches_with_app_path() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"
    mkdir -p "$EFIX_TMP/TestApp.app"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --app-path "$EFIX_TMP/TestApp.app" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_contains "$(cat "$EFIX_LOG")" "open $EFIX_TMP/TestApp.app" "should relaunch using app-path"
    _efix_teardown
}

test_efix_relaunches_by_name_without_app_path() {
    _efix_setup
    local state_file="$EFIX_TMP/window-state.json"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_contains "$(cat "$EFIX_LOG")" "open -a TestApp" "should relaunch using open -a"
    _efix_teardown
}

test_efix_reports_failure_when_no_window() {
    _efix_setup
    export EFIX_MOCK_WCOUNT=0
    local state_file="$EFIX_TMP/window-state.json"

    local out
    out="$(PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone 2>&1)"
    local rc=$?

    assert_true "[[ $rc -ne 0 ]]" "should return failure when no window appears"
    assert_contains "$out" "no window detected" "should warn about missing window"
    _efix_teardown
}

test_efix_creates_parent_dirs_for_state_file() {
    _efix_setup
    local state_file="$EFIX_TMP/nested/deep/window-state.json"

    PATH="$EFIX_BIN:/usr/bin:/bin" _electron_fix_window \
        --app-name "TestApp" \
        --state-file "$state_file" \
        --state-format standalone >/dev/null 2>&1

    assert_true "[[ -f '$state_file' ]]" "should create parent directories and state file"
    _efix_teardown
}

# =================================================================
# Tests — craft_agents_fix wrapper
# =================================================================

test_craft_agents_fix_builds_state_from_config() {
    _efix_setup
    local craft_dir="$EFIX_TMP/.craft-agent"
    mkdir -p "$craft_dir"
    cat > "$craft_dir/config.json" <<'EOF'
{
  "workspaces": [
    { "id": "ws-aaa", "name": "First" },
    { "id": "ws-bbb", "name": "Second" }
  ],
  "activeWorkspaceId": "ws-bbb"
}
EOF

    # Override HOME so craft_agents_fix finds our mock config
    HOME="$EFIX_TMP" PATH="$EFIX_BIN:/usr/bin:/bin" \
        craft_agents_fix >/dev/null 2>&1

    local state
    state="$(cat "$craft_dir/window-state.json")"
    assert_contains "$state" "ws-bbb" "should use activeWorkspaceId"
    assert_contains "$state" "1200" "should include bounds"
    _efix_teardown
}

test_craft_agents_fix_falls_back_to_first_workspace() {
    skip_if_missing python3
    _efix_setup
    local craft_dir="$EFIX_TMP/.craft-agent"
    mkdir -p "$craft_dir"
    cat > "$craft_dir/config.json" <<'EOF'
{
  "workspaces": [
    { "id": "ws-fallback", "name": "Only" }
  ],
  "activeWorkspaceId": null
}
EOF

    HOME="$EFIX_TMP" PATH="$EFIX_BIN:/usr/bin:/bin" \
        craft_agents_fix >/dev/null 2>&1

    assert_contains "$(cat "$craft_dir/window-state.json")" "ws-fallback" \
        "should fall back to first workspace when active is null"
    _efix_teardown
}

test_craft_agents_fix_removes_server_lock() {
    _efix_setup
    local craft_dir="$EFIX_TMP/.craft-agent"
    mkdir -p "$craft_dir"
    cat > "$craft_dir/config.json" <<'EOF'
{ "workspaces": [{"id":"ws-1","name":"W"}], "activeWorkspaceId": "ws-1" }
EOF
    echo "999" > "$craft_dir/.server.lock"

    HOME="$EFIX_TMP" PATH="$EFIX_BIN:/usr/bin:/bin" \
        craft_agents_fix >/dev/null 2>&1

    assert_false "[[ -f '$craft_dir/.server.lock' ]]" "should remove .server.lock"
    _efix_teardown
}

# =================================================================
# Tests — claude_desktop_fix wrapper
# =================================================================

test_claude_desktop_fix_writes_default_bounds() {
    _efix_setup
    local claude_dir="$EFIX_TMP/Library/Application Support/Claude"
    mkdir -p "$claude_dir"

    HOME="$EFIX_TMP" PATH="$EFIX_BIN:/usr/bin:/bin" \
        claude_desktop_fix >/dev/null 2>&1

    local state_file="$claude_dir/window-state.json"
    assert_true "[[ -f '$state_file' ]]" "should create window-state.json"
    assert_contains "$(cat "$state_file")" "1200" "should have default bounds"
    _efix_teardown
}

# =================================================================
# Registration
# =================================================================

register_test "test_efix_missing_args_fails"
register_test "test_efix_standalone_writes_state_file"
register_test "test_efix_standalone_with_state_builder"
register_test "test_efix_embedded_patches_key"
register_test "test_efix_embedded_requires_state_key"
register_test "test_efix_embedded_missing_file_fails"
register_test "test_efix_kills_app"
register_test "test_efix_uses_process_name_override"
register_test "test_efix_removes_lock_files"
register_test "test_efix_relaunches_with_app_path"
register_test "test_efix_relaunches_by_name_without_app_path"
register_test "test_efix_reports_failure_when_no_window"
register_test "test_efix_creates_parent_dirs_for_state_file"
register_test "test_craft_agents_fix_builds_state_from_config"
register_test "test_craft_agents_fix_falls_back_to_first_workspace"
register_test "test_craft_agents_fix_removes_server_lock"
register_test "test_claude_desktop_fix_writes_default_bounds"
