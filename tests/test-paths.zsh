#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/paths.zsh"

test_paths_init_and_list() {
    local tmp
    tmp="$(mktemp -d)"
    ZSH_PATHS_FILE="$tmp/paths.env"
    paths_init >/dev/null
    assert_true "[[ -f \"$ZSH_PATHS_FILE\" ]]" "paths_init should create file"
    echo "export WRITING_STUFF=\"$HOME/Documents/Writing_Projects/Current\"" >> "$ZSH_PATHS_FILE"
    local out
    out="$(paths_list)"
    assert_contains "$out" "WRITING_STUFF" "paths_list should show exports"
    rm -rf "$tmp"
}

register_test "test_paths_init_and_list" "test_paths_init_and_list"
