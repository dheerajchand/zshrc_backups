#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/screen.zsh"

test_screen_ensure_pyenv_writes_files() {
    local old_home="$HOME"
    local tmp
    tmp="$(mktemp -d)"
    HOME="$tmp"
    screen_ensure_pyenv >/dev/null
    assert_true "[[ -f \"$HOME/.zshenv\" ]]" "screen_ensure_pyenv should create .zshenv"
    assert_true "[[ -f \"$HOME/.zshrc\" ]]" "screen_ensure_pyenv should create .zshrc"
    assert_contains "$(cat "$HOME/.zshenv")" "PYENV_ROOT" "zshenv should set PYENV_ROOT"
    assert_contains "$(cat "$HOME/.zshrc")" "pyenv init" "zshrc should include pyenv init"
    HOME="$old_home"
    rm -rf "$tmp"
}

register_test "screen_ensure_pyenv" test_screen_ensure_pyenv_writes_files
