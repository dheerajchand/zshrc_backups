#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/agents.zsh"

test_codex_session_crud() {
    local tmp
    tmp="$(mktemp)"
    CODEX_SESSIONS_FILE="$tmp"
    codex_session_add "demo" "abc123|Test session"
    local out
    out="$(codex_session_list)"
    assert_contains "$out" "demo" "list should include key"
    codex_session_update "demo" "xyz999|Updated"
    out="$(codex_session demo)"
    assert_contains "$out" "codex resume xyz999" "resume should use updated id"
    codex_session_remove "demo"
    out="$(codex_session_list)"
    assert_not_contains "$out" "demo" "key should be removed"
    rm -f "$tmp"
}

register_test "test_codex_session_crud" "test_codex_session_crud"
