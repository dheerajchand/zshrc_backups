#!/usr/bin/env zsh
# =================================================================
# PYTHON - Python Environment Management
# =================================================================
# Pyenv setup, environment switching, project initialization
# =================================================================

# Default environment to auto-activate
: "${PYENV_DEFAULT_VENV:=${DEFAULT_PYENV_VENV:-default_31111}}"
export DEFAULT_PYENV_VENV="${PYENV_DEFAULT_VENV}"

_pyenv_default_venv() {
    echo "${PYENV_DEFAULT_VENV:-${DEFAULT_PYENV_VENV:-}}"
}

# Provide python shim on Linux when only python3 exists
if ! command -v python >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    python() {
        # A manager may add `python` after this module has loaded.
        if whence -p python >/dev/null 2>&1; then
            command python "$@"
        else
            command python3 "$@"
        fi
    }
fi

# Initialize only when this shell owns Python selection. Helpers always load.
_python_initialize() {
    [[ -z "${ZSH_TEST_MODE:-}" ]] || return 0
    [[ "${ZSH_PYENV_AUTO_INIT:-1}" == 1 && "${ZSH_MISE_ACTIVATE:-0}" != 1 ]] || return 0
    # Preserve inherited mise/venv environments in nested interactive shells.
    [[ -z "${__MISE_DIFF:-}${VIRTUAL_ENV:-}" ]] || return 0
    command -v pyenv >/dev/null 2>&1 || return 0
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ ":$PATH:" == *":$PYENV_ROOT/bin:"* ]] || export PATH="$PATH:$PYENV_ROOT/bin"
    eval "$(pyenv init --path --no-rehash 2>/dev/null)"
    eval "$(pyenv init - --no-rehash 2>/dev/null)"

    # Disabling activation also disables the virtualenv prompt hook.
    [[ "${ZSH_PYENV_AUTO_ACTIVATE:-1}" == 1 ]] || return 0
    local pyenv_commands default_venv versions
    pyenv_commands="$(pyenv commands --bare 2>/dev/null)"
    if [[ $'\n'"$pyenv_commands"$'\n' == *$'\nvirtualenv-init\n'* ]]; then
        eval "$(pyenv virtualenv-init - 2>/dev/null)"
    fi
    default_venv="$(_pyenv_default_venv)"
    versions="$(pyenv versions --bare 2>/dev/null)"
    if [[ -n "$default_venv" && $'\n'"$versions"$'\n' == *$'\n'"$default_venv"$'\n'* ]]; then
        pyenv activate "$default_venv" 2>/dev/null || pyenv shell "$default_venv" 2>/dev/null
    fi
    return 0
}
_python_initialize

# Switch Python environments
py_env_switch() {
    local env_name="" set_default=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)    env_name="${2:-}"; shift 2 ;;
            --default) set_default="${2:-}"; shift 2 ;;
            --list)    env_name="list"; shift ;;
            --help|-h) echo "Usage: py_env_switch [--name <env>] [--default <env>] [--list]" >&2; return 0 ;;
            *)         env_name="$1"; shift ;;  # accept bare arg for convenience
        esac
    done
    if [[ -n "$set_default" ]]; then
        PYENV_DEFAULT_VENV="$set_default"
        DEFAULT_PYENV_VENV="$set_default"
        if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
            _secrets_update_env_file --key "PYENV_DEFAULT_VENV" --value "$set_default" >/dev/null 2>&1 || true
            _secrets_update_env_file --key "DEFAULT_PYENV_VENV" --value "$set_default" >/dev/null 2>&1 || true
        fi
        env_name="$set_default"
    fi
    if [[ -z "$env_name" || "$env_name" == "default" ]]; then
        env_name="$(_pyenv_default_venv)"
    fi
    if [[ -z "$env_name" ]]; then
        env_name="list"
    fi

    if [[ "$env_name" == "list" ]]; then
        echo "📋 Available Python environments:"
        pyenv versions
        echo ""
        echo "Current: $(pyenv version-name 2>/dev/null || echo 'system')"
        return 0
    fi
    
    if pyenv versions --bare | grep -q "^${env_name}$"; then
        pyenv activate "$env_name" 2>/dev/null || pyenv shell "$env_name" 2>/dev/null
        echo "✅ Activated: $env_name"
        python --version
        if [[ -n "$DEFAULT_PYENV_VENV" && "$env_name" == "$DEFAULT_PYENV_VENV" ]]; then
            export PYENV_DEFAULT_VENV="$DEFAULT_PYENV_VENV"
        fi
    else
        echo "❌ Environment not found: $env_name"
        echo "Available:"
        pyenv versions --bare
        return 1
    fi
}

# Get the executable selected by PATH, resolving shims through Python itself.
get_python_path() {
    local py_bin=python
    command -v "$py_bin" >/dev/null 2>&1 || py_bin=python3
    "$py_bin" -c 'import sys; print(sys.executable)'
}

# Get current Python version (major.minor).
get_python_version() {
    local py_bin=python
    command -v "$py_bin" >/dev/null 2>&1 || py_bin=python3
    "$py_bin" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
}

_python_manager() {
    local executable="${1:-}"
    [[ -n "$executable" ]] || executable="$(get_python_path 2>/dev/null)" || true
    local pyenv_root="${PYENV_ROOT:-$HOME/.pyenv}"
    local mise_data="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
    case "$executable" in
        "$pyenv_root"/versions/*) print -- pyenv ;;
        "$mise_data"/installs/python/*) print -- mise ;;
        *)
            if [[ -n "${VIRTUAL_ENV:-}" && "$executable" == "$VIRTUAL_ENV"/* ]]; then
                print -- virtualenv
            else
                print -- system
            fi
            ;;
    esac
}

_python_active() {
    local manager="$1" executable="$2"
    case "$manager" in
        pyenv|mise|virtualenv) print -- "${executable:h:h:t}" ;;
        *) print -- system ;;
    esac
}

# Show the selected Python and its owning environment.
python_status() {
    local executable manager active py_bin=python
    executable="$(get_python_path 2>/dev/null)" || true
    manager="$(_python_manager "$executable")"
    active="$(_python_active "$manager" "$executable")"
    command -v "$py_bin" >/dev/null 2>&1 || py_bin=python3
    echo "🐍 Python Environment"
    echo "===================="
    echo "Manager: $manager"
    echo "Active: $active"
    if [[ -n "$executable" ]]; then
        echo "Python: $("$py_bin" --version 2>&1)"
        echo "Version: $(get_python_version)"
        echo "Location: $(command -v "$py_bin")"
        echo "Actual Binary: $executable"
    else
        echo "Python: not found"
    fi
    if command -v uv >/dev/null 2>&1; then
        echo "UV: $(uv --version 2>&1 | head -1)"
    fi
}

# Show Python defaults alongside the interpreter actually selected.
python_config_status() {
    local executable manager py_bin=python
    executable="$(get_python_path 2>/dev/null)" || true
    manager="$(_python_manager "$executable")"
    command -v "$py_bin" >/dev/null 2>&1 || py_bin=python3
    echo "⚙️  Python Configuration"
    echo "======================="
    echo "Manager: $manager"
    echo "Active: $(_python_active "$manager" "$executable")"
    if [[ -n "$executable" ]]; then
        echo "Python: $("$py_bin" --version 2>&1 | head -1)"
        echo "Actual Binary: $executable"
    else
        echo "Python: not found"
    fi
    echo "Pyenv auto-init: ${ZSH_PYENV_AUTO_INIT:-1}"
    echo "Pyenv auto-activate: ${ZSH_PYENV_AUTO_ACTIVATE:-1}"
    if command -v pyenv >/dev/null 2>&1; then
        echo "PYENV_ROOT: ${PYENV_ROOT:-$HOME/.pyenv}"
        local default_venv="$(_pyenv_default_venv)"
        [[ -n "$default_venv" ]] && echo "Default venv: $default_venv"
    fi
    return 0
}

# Select a pyenv version for this shell.
pyenv_use_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: pyenv_use_version <version>" >&2
        return 1
    fi
    if ! command -v pyenv >/dev/null 2>&1; then
        echo "pyenv not found" >&2
        return 1
    fi
    pyenv shell "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file --key "PYENV_VERSION" --value "$version" >/dev/null 2>&1 || true
    fi
    export PYENV_VERSION="$version"
}

pyenv_default_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: pyenv_default_version <version>" >&2
        return 1
    fi
    if ! command -v pyenv >/dev/null 2>&1; then
        echo "pyenv not found" >&2
        return 1
    fi
    pyenv global "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file --key "PYENV_VERSION" --value "$version" >/dev/null 2>&1 || true
    fi
    export PYENV_VERSION="$version"
}

# Run command with current Python (for Spark, Jupyter, etc.)
with_python() {
    local cmd="$1"
    shift
    local python_path
    python_path="$(get_python_path)" || return $?
    [[ -n "$python_path" ]] || return 1
    
    # Set Python env vars for the command
    PYSPARK_PYTHON="$python_path" \
    PYSPARK_DRIVER_PYTHON="$python_path" \
    JUPYTER_PYTHON="$python_path" \
    "$cmd" "$@"
}

# Switch to UV for project-based management
use_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "✅ Using UV for project management"
        echo "💡 Run: uv init <project> to create new project"
    else
        echo "❌ UV not installed"
        echo "Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

# Initialize data science project structure
ds_project_init() {
    local project_name="" with_spark=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)       project_name="${2:-}"; shift 2 ;;
            --with-spark) with_spark=1; shift ;;
            --help|-h)    echo "Usage: ds_project_init --name <project> [--with-spark]" >&2; return 0 ;;
            *)            project_name="$1"; shift ;;  # accept bare arg for convenience
        esac
    done

    if [[ -z "$project_name" ]]; then
        echo "Usage: ds_project_init --name <project> [--with-spark]" >&2
        return 1
    fi

    echo "📦 Creating data science project: $project_name"

    mkdir -p "$project_name"/{data,notebooks,src,tests,output}
    cd "$project_name"

    # Create basic structure
    touch src/__init__.py
    touch tests/__init__.py
    touch README.md

    # Create requirements.txt
    cat > requirements.txt << 'EOF'
pandas
numpy
matplotlib
seaborn
jupyter
EOF

    # Add Spark dependencies if requested
    if [[ "$with_spark" -eq 1 ]]; then
        echo "pyspark" >> requirements.txt
    fi

    echo "✅ Project structure created"
    echo "💡 Next steps:"
    echo "   cd $project_name"
    echo "   uv init  # or python -m venv .venv"
    echo "   pip install -r requirements.txt"
}

# Aliases
alias py='python'
alias py3='python3'
alias ipy='ipython'
alias jn='jupyter notebook'

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ python loaded"
fi
