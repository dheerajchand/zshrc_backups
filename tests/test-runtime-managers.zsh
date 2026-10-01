#!/usr/bin/env zsh
ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

_runtime_fixture() {
    local fixture module
    fixture="$(mktemp -d)" || return 1
    mkdir -p "$fixture"/{home,dot,config/modules,bin,project,elsewhere}
    cp "$ROOT_DIR/zshrc" "$ROOT_DIR/zshenv" "$fixture/config/"
    # Exercise real startup without services, credentials, or personal plugins.
    for module in "$ROOT_DIR"/modules/*.zsh; do
        : > "$fixture/config/modules/${module:t}"
    done
    cp "$ROOT_DIR/modules/python.zsh" "$ROOT_DIR/modules/mise.zsh" "$fixture/config/modules/"
    ln -s "$fixture/config/zshrc" "$fixture/dot/.zshrc"
    ln -s "$fixture/config/zshenv" "$fixture/dot/.zshenv"
    cat > "$fixture/bin/pyenv" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$RUNTIME_LOG"
case "$1" in
    commands) printf 'virtualenv-init\n' ;;
    versions) printf 'default_31111\n' ;;
    virtualenv-init) printf 'precmd_functions+=(_fixture_pyenv_hook)\n' ;;
    version-name) printf 'default_31111\n' ;;
    which) printf '/wrong/pyenv/python\n' ;;
esac
STUB
    cat > "$fixture/bin/mise" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$RUNTIME_LOG"
if [ "$1" = activate ]; then
    printf '_mise_hook() { :; }\nprecmd_functions+=(_mise_hook)\n'
fi
STUB
    cat > "$fixture/bin/python" <<'STUB'
#!/bin/sh
case "$*" in
    *sys.executable*) printf '%s\n' "$RUNTIME_PYTHON" ;;
    *sys.version_info*) printf '3.13\n' ;;
    *) printf 'Python 3.13.1\n' ;;
esac
STUB
    chmod +x "$fixture/bin/"*
    print -r -- "$fixture"
}

_runtime_shell() {
    local fixture="$1" code="$2"
    shift 2
    env HOME="$fixture/home" ZDOTDIR="$fixture/dot" \
        ZSHRC_CONFIG_DIR="$fixture/config" ZSH_CONFIG_DIR="$fixture/config" \
        PYENV_ROOT="$fixture/home/.pyenv" MISE_DATA_DIR="$fixture/home/.local/share/mise" \
        PATH="$fixture/bin:/usr/bin:/bin" JAVA_HOME=/project/java \
        VIRTUAL_ENV= PYENV_VIRTUAL_ENV= PYENV_VERSION= __MISE_DIFF= \
        ZSH_PYENV_AUTO_INIT=1 ZSH_PYENV_AUTO_ACTIVATE=1 ZSH_MISE_ACTIVATE=0 \
        ZSH_FORCE_FULL_INIT=1 ZSH_STARTUP_MODE=immediate ZSH_TEST_MODE= \
        ZSH_STARTUP_CD=0 STARTUP_DIR="$fixture/elsewhere" \
        ZSH_STATUS_BANNER_MODE=off ZSH_AUTO_RECOVER_MODE=off \
        RUNTIME_LOG="$fixture/log" RUNTIME_PYTHON="$fixture/project/.venv/bin/python" \
        "$@" /bin/zsh -d -i -c "$code"
}

test_runtime_child_preserves_environment() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'print -r -- "FIRST=$path[1] JAVA=$JAVA_HOME"; zsh -d -c '\''print -r -- "CHILD=$path[1] JAVA=$JAVA_HOME"'\''; source "$ZSH_CONFIG_DIR/zshenv"; print -r -- "COUNT=${#path}"' ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" "FIRST=$fixture/bin JAVA=/project/java" "interactive startup preserves inherited runtime"
    assert_contains "$out" "CHILD=$fixture/bin JAVA=/project/java" "noninteractive child preserves inherited runtime"
    # Idempotent fallback paths must not accumulate on every source.
    out="$(_runtime_shell "$fixture" 'before=${#path}; source "$ZSH_CONFIG_DIR/zshenv"; [[ "$before" == "${#path}" ]] && print IDEMPOTENT' ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" 'IDEMPOTENT' "environment defaults are idempotent"
    rm -rf "$fixture"
}

test_runtime_gui_fast_path_preserves_environment() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'print -r -- "FIRST=$path[1] JAVA=$JAVA_HOME"' ZSH_FORCE_FULL_INIT= TERM_PROGRAM= WARP_IS_LOCAL_SHELL_SESSION=)"
    assert_contains "$out" "FIRST=$fixture/bin JAVA=/project/java" "GUI fast path preserves runtime"
    rm -rf "$fixture"
}

test_runtime_empty_path_has_no_current_directory_entry() {
    local out
    out="$(env PATH= /bin/zsh -dfc '
        source "$1"
        for dir in "${path[@]}"; do
            [[ -n "$dir" ]] || { print EMPTY_ENTRY; exit 1; }
        done
        [[ ":$PATH:" == *":/usr/bin:"* ]] && print DEFAULTS_PRESENT
    ' -- "$ROOT_DIR/zshenv")"
    assert_not_contains "$out" EMPTY_ENTRY "empty PATH must not introduce a current-directory entry"
    assert_contains "$out" DEFAULTS_PRESENT "empty PATH receives usable fallback paths"
}

test_runtime_default_java_is_fallback() {
    local fixture out
    fixture="$(_runtime_fixture)"
    mkdir -p "$fixture/home/.sdkman/candidates/java/current"
    out="$(_runtime_shell "$fixture" 'print -r -- "JAVA=$JAVA_HOME"' JAVA_HOME= ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" "JAVA=$fixture/home/.sdkman/candidates/java/current" "SDKMAN supplies missing Java default"
    rm -rf "$fixture"
}

test_runtime_pyenv_controls() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'print -r -- "HELPER=${+functions[py_env_switch]} HOOKS=${precmd_functions[*]}"; modules' ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" 'HELPER=1' "helpers remain available without initialization"
    assert_contains "$out" '✅ mise loaded (shell hooks inactive)' "startup distinguishes loading from activation"
    assert_contains "$out" 'mise        - Project runtimes (shell hooks inactive)' "module listing includes inactive mise"
    assert_false "[[ -s '$fixture/log' ]]" "disabled init never calls pyenv or mise"
    out="$(_runtime_shell "$fixture" 'print -r -- "HOOKS=${precmd_functions[*]}"' ZSH_PYENV_AUTO_ACTIVATE=0)"
    assert_contains "$(cat "$fixture/log")" 'init - --no-rehash' "manual mode keeps pyenv shell commands"
    assert_not_contains "$(cat "$fixture/log")" 'virtualenv-init' "manual mode skips virtualenv prompt hook"
    assert_not_contains "$(cat "$fixture/log")" 'activate default_31111' "manual mode skips default activation"
    : > "$fixture/log"
    out="$(_runtime_shell "$fixture" 'print -r -- "HOOKS=${precmd_functions[*]}"')"
    assert_contains "$(cat "$fixture/log")" 'activate default_31111' "legacy default activation remains available"
    assert_contains "$out" '_fixture_pyenv_hook' "legacy virtualenv hook remains available"
    rm -rf "$fixture"
}

test_runtime_inherited_environment_skips_pyenv() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'print -r -- "VENV=$VIRTUAL_ENV"' VIRTUAL_ENV="$fixture/project/.venv")"
    assert_contains "$out" "VENV=$fixture/project/.venv" "inherited venv survives startup"
    assert_false "[[ -s '$fixture/log' ]]" "inherited venv suppresses pyenv init"
    out="$(_runtime_shell "$fixture" ':' __MISE_DIFF=fixture)"
    assert_false "[[ -s '$fixture/log' ]]" "inherited mise environment suppresses pyenv init"
    rm -rf "$fixture"
}

test_runtime_mise_is_opt_in_and_idempotent() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'source "$ZSH_CONFIG_DIR/modules/mise.zsh"; print -r -- "HOOKS=${precmd_functions[*]}"; modules' ZSH_MISE_ACTIVATE=1)"
    assert_equal 'activate zsh' "$(cat "$fixture/log")" "mise activates once and pyenv never initializes"
    assert_contains "$out" 'HOOKS=_mise_hook' "mise hook is installed"
    assert_contains "$out" '✅ mise loaded (shell hooks active)' "startup reports active hooks"
    assert_contains "$out" 'mise        - Project runtimes (shell hooks active)' "module listing reports active hooks"
    : > "$fixture/log"
    out="$(_runtime_shell "$fixture" ':' ZSH_MISE_ACTIVATE=1 VIRTUAL_ENV=/personal/venv PYENV_VIRTUAL_ENV=/personal/venv 2>&1 || true)"
    assert_contains "$out" 'deactivate the current virtualenv' "personal virtualenv requires explicit deactivation"
    assert_contains "$out" 'activation failed)' "failed activation is visible"
    assert_not_contains "$out" '✅ mise loaded' "failed activation does not report success"
    assert_false "[[ -s '$fixture/log' ]]" "conflicting virtualenv does not activate mise"
    out="$(_runtime_shell "$fixture" 'modules' ZSH_DISABLE_MISE=1 ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" 'mise        - Module not loaded' "disabled module is not listed as loaded"
    assert_not_contains "$out" 'mise loaded (' "disabled module emits no startup line"
    out="$(_runtime_shell "$fixture" ':' ZSH_TEST_MODE=1)"
    assert_not_contains "$out" 'mise loaded (' "test mode suppresses startup messages"
    rm -rf "$fixture"
}

test_runtime_python_follows_selected_interpreter() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(_runtime_shell "$fixture" 'python_status; with_python print -r -- "WRAPPER"' ZSH_PYENV_AUTO_INIT=0 VIRTUAL_ENV="$fixture/project/.venv")"
    assert_contains "$out" 'Manager: virtualenv' "installed pyenv does not determine ownership"
    assert_contains "$out" "Actual Binary: $fixture/project/.venv/bin/python" "status follows selected interpreter"
    out="$(_runtime_shell "$fixture" 'with_python /bin/sh -c '\''printf "%s|%s|%s" "$PYSPARK_PYTHON" "$PYSPARK_DRIVER_PYTHON" "$JUPYTER_PYTHON"'\''' ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" "$fixture/project/.venv/bin/python|$fixture/project/.venv/bin/python|$fixture/project/.venv/bin/python" "Spark/Jupyter use selected interpreter"
    out="$(_runtime_shell "$fixture" 'python_config_status' ZSH_PYENV_AUTO_INIT=0 RUNTIME_PYTHON="$fixture/home/.local/share/mise/installs/python/3.13.1/bin/python")"
    assert_contains "$out" 'Manager: mise' "mise interpreter is recognized"
    assert_contains "$out" 'Active: 3.13.1' "mise version is reported"
    assert_false "[[ -s '$fixture/log' ]]" "Python selection never queries installed pyenv"
    rm -rf "$fixture"
}

test_runtime_startup_directory_is_opt_in() {
    local fixture out
    fixture="$(_runtime_fixture)"
    out="$(cd "$fixture/project" && _runtime_shell "$fixture" 'print -r -- "PWD=$PWD"' ZSH_PYENV_AUTO_INIT=0)"
    assert_contains "$out" "PWD=$fixture/project" "project cwd is preserved by default"
    out="$(cd "$fixture/project" && _runtime_shell "$fixture" 'print -r -- "PWD=$PWD"' ZSH_PYENV_AUTO_INIT=0 ZSH_STARTUP_CD=1)"
    assert_contains "$out" "PWD=$fixture/elsewhere" "explicit startup cd is honored"
    out="$(HOME="$fixture/home" STARTUP_DIR="$fixture/project" /bin/zsh -dfc 'source "$1"; print -r -- "STARTUP=$STARTUP_DIR"' -- "$ROOT_DIR/vars.mac.env")"
    assert_contains "$out" "STARTUP=$fixture/project" "Mac settings preserve caller startup preference"
    rm -rf "$fixture"
}

register_test runtime_child_preserves_environment test_runtime_child_preserves_environment
register_test runtime_gui_fast_path_preserves_environment test_runtime_gui_fast_path_preserves_environment
register_test runtime_empty_path_has_no_current_directory_entry test_runtime_empty_path_has_no_current_directory_entry
register_test runtime_default_java_is_fallback test_runtime_default_java_is_fallback
register_test runtime_pyenv_controls test_runtime_pyenv_controls
register_test runtime_inherited_environment_skips_pyenv test_runtime_inherited_environment_skips_pyenv
register_test runtime_mise_is_opt_in_and_idempotent test_runtime_mise_is_opt_in_and_idempotent
register_test runtime_python_follows_selected_interpreter test_runtime_python_follows_selected_interpreter
register_test runtime_startup_directory_is_opt_in test_runtime_startup_directory_is_opt_in

# Exercise installer entry points with scratch homes; never run either main().
test_runtime_installer_preserves_existing_zshenv() {
    local fixture installer out
    fixture="$(_runtime_fixture)"
    installer="$(awk '/^create_symlinks\(\)/,/^}/' "$ROOT_DIR/install.sh")"
    print -r -- '# personal environment' > "$fixture/home/.zshenv"
    out="$(HOME="$fixture/home" CONFIG_DIR="$fixture/config" bash -c '
        print_header() { :; }; print_info() { :; }; print_success() { :; }
        print_error() { echo "$*" >&2; }
        eval "$1"
        create_symlinks
        cat "$HOME/.zshenv"
    ' -- "$installer")"
    assert_equal '# personal environment' "$out" "installer preserves personal .zshenv"
    mv "$fixture/home/.zshenv" "$fixture/home/saved-env"
    HOME="$fixture/home" CONFIG_DIR="$fixture/config" bash -c '
        print_header() { :; }; print_info() { :; }; print_success() { :; }
        print_error() { echo "$*" >&2; }
        eval "$1"
        create_symlinks
    ' -- "$installer"
    assert_equal "$fixture/config/zshenv" "$(readlink "$fixture/home/.zshenv")" "new installations use managed .zshenv"
    rm -rf "$fixture"
}

test_runtime_java_installer_preserves_inherited_home() {
    local fixture installer out
    fixture="$(_runtime_fixture)"
    installer="$(awk '/^ensure_java_home_in_zshenv\(\)/,/^}/' "$ROOT_DIR/setup-software.sh")"
    print -r -- 'export JAVA_HOME="/old/java"' > "$fixture/home/.zshenv"
    out="$(HOME="$fixture/home" SCRIPT_DIR="$ROOT_DIR" bash -c '
        print_info() { :; }; print_success() { :; }; print_warning() { :; }
        java() { :; }; _resolve_java_home() { echo /sdk/java; }
        eval "$1"
        ensure_java_home_in_zshenv
        JAVA_HOME=/project/java
        source "$HOME/.zshenv"
        echo "$JAVA_HOME"
        unset JAVA_HOME
        source "$HOME/.zshenv"
        echo "$JAVA_HOME"
    ' -- "$installer")"
    assert_equal $'/project/java\n/sdk/java' "$out" "generated Java assignment is a fallback"
    cp "$ROOT_DIR/zshenv" "$fixture/config/zshenv"
    mv "$fixture/home/.zshenv" "$fixture/home/saved-env"
    ln -s "$fixture/config/zshenv" "$fixture/home/.zshenv"
    HOME="$fixture/home" SCRIPT_DIR="$fixture/config" bash -c '
        print_info() { :; }
        eval "$1"
        ensure_java_home_in_zshenv
    ' -- "$installer"
    assert_true "cmp -s '$ROOT_DIR/zshenv' '$fixture/config/zshenv'" "software installer does not modify managed source"
    rm -rf "$fixture"
}

register_test runtime_installer_preserves_existing_zshenv test_runtime_installer_preserves_existing_zshenv
register_test runtime_java_installer_preserves_inherited_home test_runtime_java_installer_preserves_inherited_home
