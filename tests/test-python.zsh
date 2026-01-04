#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/python.zsh"

_make_stub_pyenv() {
    local bin_dir="$1"
    cat > "$bin_dir/pyenv" <<'PYENV'
#!/usr/bin/env zsh
case "$1" in
    init)
        exit 0
        ;;
    commands)
        echo "virtualenv-init"
        exit 0
        ;;
    "version-name")
        echo "testenv"
        exit 0
        ;;
    which)
        echo "/tmp/python"
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
PYENV
    chmod +x "$bin_dir/pyenv"
}

_make_stub_python() {
    local bin_dir="$1"
    cat > "$bin_dir/python" <<'PY'
#!/usr/bin/env zsh
echo "Python 3.11.0"
PY
    chmod +x "$bin_dir/python"
}

test_python_status_no_pyenv() {
    local old_path="$PATH"
    local old_pyenv_fn="$(typeset -f pyenv 2>/dev/null || true)"
    unfunction pyenv 2>/dev/null || true
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_python "$bin"
    PATH="$bin:/usr/bin:/bin"
    out="$(python_status)"
    assert_contains "$out" "Manager: system" "should report system manager without pyenv"
    assert_contains "$out" "Python: Python 3.11.0" "should report python version"
    if [[ -n "$old_pyenv_fn" ]]; then
        eval "$old_pyenv_fn"
    fi
    PATH="$old_path"
    rm -rf "$tmp"
}

test_python_status_with_pyenv() {
    local old_path="$PATH"
    local old_pyenv_fn="$(typeset -f pyenv 2>/dev/null || true)"
    unfunction pyenv 2>/dev/null || true
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_pyenv "$bin"
    _make_stub_python "$bin"
    PATH="$bin:/usr/bin:/bin"
    out="$(python_status)"
    assert_contains "$out" "Manager: pyenv" "should report pyenv manager"
    assert_contains "$out" "Active: testenv" "should report active pyenv env"
    if [[ -n "$old_pyenv_fn" ]]; then
        eval "$old_pyenv_fn"
    fi
    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "test_python_status_no_pyenv" "test_python_status_no_pyenv"
register_test "test_python_status_with_pyenv" "test_python_status_with_pyenv"
