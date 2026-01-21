#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/backup.zsh"

test_backup_requires_git_repo() {
    local old_dir="$ZSHRC_CONFIG_DIR"
    local tmp out
    tmp="$(mktemp -d)"
    ZSHRC_CONFIG_DIR="$tmp"
    out="$(backup "test" 2>&1 || true)"
    assert_contains "$out" "Not a git repository" "backup should refuse non-git dir"
    ZSHRC_CONFIG_DIR="$old_dir"
    rm -rf "$tmp"
}

register_test "backup_requires_git" test_backup_requires_git_repo
