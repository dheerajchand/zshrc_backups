#!/usr/bin/env zsh
# =====================================================
# PYTHON MODULE - Python environment management
# =====================================================
#
# Purpose: Comprehensive Python environment management
# Provides: pyenv, UV, virtualenv, project management
# Dependencies: centralized variables
# =====================================================

echo "🐍 Loading Python module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# PYTHON ENVIRONMENT SETUP
# =====================================================

# Setup pyenv if available (uses centralized PYENV_ROOT)
if [[ -d "$PYENV_ROOT" ]]; then
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        echo "✅ Pyenv initialized"
    fi
fi

# Setup UV if available (uses centralized UV_BIN_PATH)
if command -v uv >/dev/null 2>&1; then
    export PATH="$UV_BIN_PATH:$PATH"
    echo "✅ UV initialized"
fi

# =====================================================
# PYTHON FUNCTIONS
# =====================================================

# Purpose: Show comprehensive Python environment status
# Arguments: None
# Returns: 0 always
# Usage: python_status
python_status() {
    echo "🐍 Python Environment Status"
    echo "============================"

    # Python version info
    if command -v python3 >/dev/null 2>&1; then
        echo "✅ Python: $(python3 --version)"
        echo "📍 Location: $(which python3)"
    else
        echo "❌ Python: Not found"
    fi

    # Pyenv status
    if command -v pyenv >/dev/null 2>&1; then
        echo "✅ Pyenv: $(pyenv --version)"
        echo "🔄 Current: $(pyenv version)"
        echo "📋 Available:"
        pyenv versions --bare | head -5 | sed 's/^/  /'
    else
        echo "❌ Pyenv: Not available"
    fi

    # UV status
    if command -v uv >/dev/null 2>&1; then
        echo "✅ UV: $(uv --version)"
    else
        echo "❌ UV: Not available"
    fi

    # Virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🌟 Active virtualenv: $(basename $VIRTUAL_ENV)"
    else
        echo "💤 No virtual environment active"
    fi
}

# Purpose: Interactive Python environment switching
# Arguments: $1 - environment name or 'list' or 'uv'
# Returns: 0 on success, 1 on error
# Usage: py_env_switch <env_name> | py_env_switch list | py_env_switch uv
py_env_switch() {
    local action="$1"

    case "$action" in
        "list")
            echo "📋 Available Python environments:"
            if command -v pyenv >/dev/null 2>&1; then
                echo "  Pyenv versions:"
                pyenv versions --bare | sed 's/^/    /'
            fi
            if command -v uv >/dev/null 2>&1; then
                echo "  UV projects:"
                find . -name "pyproject.toml" -exec dirname {} \; 2>/dev/null | sed 's/^/    /'
            fi
            ;;
        "uv")
            if command -v uv >/dev/null 2>&1; then
                if [[ -f "pyproject.toml" ]]; then
                    echo "🔄 Activating UV project environment..."
                    source .venv/bin/activate 2>/dev/null || uv venv && source .venv/bin/activate
                else
                    echo "❌ No pyproject.toml found in current directory"
                    return 1
                fi
            else
                echo "❌ UV not available"
                return 1
            fi
            ;;
        "")
            echo "💡 Usage: py_env_switch <env_name> | list | uv"
            echo "📋 Available environments:"
            py_env_switch list
            ;;
        *)
            if command -v pyenv >/dev/null 2>&1; then
                echo "🔄 Switching to Python $action..."
                pyenv global "$action" && echo "✅ Switched to $(python --version)"
            else
                echo "❌ Pyenv not available"
                return 1
            fi
            ;;
    esac
}

# =====================================================
# ADVANCED FEATURES
# =====================================================

# Purpose: Benchmark Python package managers performance
# Arguments: $1 - optional package list (default: "requests pandas")
# Returns: 0 on success, 1 on error
# Usage: python_benchmark ["package1 package2"]
python_benchmark() {
    local packages="${1:-requests pandas}"
    local temp_dir="/tmp/python_benchmark_$$"

    echo "📊 Python Package Manager Benchmark"
    echo "==================================="
    echo "📦 Testing packages: $packages"
    echo "📁 Test directory: $temp_dir"
    echo ""

    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # Benchmark pyenv/pip
    if command -v python3 >/dev/null 2>&1 && command -v pip >/dev/null 2>&1; then
        echo "🔍 Testing pip..."
        python3 -m venv pip_test_env
        source pip_test_env/bin/activate

        local pip_start=$(date +%s.%N)
        pip install --quiet $packages >/dev/null 2>&1
        local pip_end=$(date +%s.%N)
        local pip_time=$(echo "$pip_end - $pip_start" | bc 2>/dev/null || echo "N/A")

        deactivate
        echo "✅ pip: ${pip_time}s"
    fi

    # Benchmark UV
    if command -v uv >/dev/null 2>&1; then
        echo "🔍 Testing uv..."

        local uv_start=$(date +%s.%N)
        uv venv uv_test_env >/dev/null 2>&1
        source uv_test_env/bin/activate
        uv pip install $packages >/dev/null 2>&1
        local uv_end=$(date +%s.%N)
        local uv_time=$(echo "$uv_end - $uv_start" | bc 2>/dev/null || echo "N/A")

        deactivate
        echo "✅ uv: ${uv_time}s"

        if [[ "$pip_time" != "N/A" && "$uv_time" != "N/A" ]]; then
            local speedup=$(echo "scale=2; $pip_time / $uv_time" | bc 2>/dev/null || echo "N/A")
            echo ""
            echo "🚀 UV is ${speedup}x faster than pip"
        fi
    fi

    # Cleanup
    cd - >/dev/null
    rm -rf "$temp_dir"

    echo ""
    echo "💡 Benchmark complete"
}

# Purpose: Setup Jupyter environment with optimal configuration
# Arguments: $1 - optional port (default: 8888), $2 - optional directory
# Returns: 0 on success, 1 on error
# Usage: python_jupyter [port] [directory]
python_jupyter() {
    local port="${1:-8888}"
    local dir="${2:-$(pwd)}"

    if [[ ! -d "$dir" ]]; then
        echo "❌ Directory not found: $dir"
        return 1
    fi

    echo "📓 Starting Jupyter Lab Environment"
    echo "=================================="
    echo "📁 Directory: $dir"
    echo "🌐 Port: $port"
    echo ""

    cd "$dir"

    # Check if we're in a UV project
    if [[ -f "pyproject.toml" ]] && command -v uv >/dev/null 2>&1; then
        echo "🔍 UV project detected"

        # Ensure Jupyter is installed
        if ! uv run python -c "import jupyter" 2>/dev/null; then
            echo "📦 Installing Jupyter dependencies..."
            uv add --dev jupyter jupyterlab ipykernel
        fi

        # Create kernel
        uv run python -m ipykernel install --user --name="$(basename "$dir")" \
            --display-name="$(basename "$dir") (UV)" 2>/dev/null

        echo "🚀 Starting Jupyter Lab with UV..."
        uv run jupyter lab --port="$port" --no-browser

    elif [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🔍 Virtual environment detected: $(basename "$VIRTUAL_ENV")"

        # Ensure Jupyter is installed
        if ! python -c "import jupyter" 2>/dev/null; then
            echo "📦 Installing Jupyter dependencies..."
            pip install --quiet jupyter jupyterlab ipykernel
        fi

        # Create kernel
        python -m ipykernel install --user --name="$(basename "$VIRTUAL_ENV")" \
            --display-name="$(basename "$VIRTUAL_ENV")" 2>/dev/null

        echo "🚀 Starting Jupyter Lab..."
        jupyter lab --port="$port" --no-browser

    else
        echo "⚠️  No virtual environment detected"
        echo "💡 Consider activating a virtual environment or using UV"
        echo ""
        echo "📋 Available environments:"
        py_env_switch list
        return 1
    fi
}

# Purpose: Create optimized Python project structure
# Arguments: $1 - project name, $2 - project type (web/data/cli/package)
# Returns: 0 on success, 1 on error
# Usage: python_create_project myproject [web|data|cli|package]
python_create_project() {
    local project_name="$1"
    local project_type="${2:-package}"

    if [[ -z "$project_name" ]]; then
        echo "❌ Usage: python_create_project <name> [web|data|cli|package]"
        return 1
    fi

    if [[ -d "$project_name" ]]; then
        echo "❌ Directory already exists: $project_name"
        return 1
    fi

    echo "🏗️  Creating Python project: $project_name ($project_type)"
    echo "================================================="

    mkdir -p "$project_name"
    cd "$project_name"

    # Initialize with UV if available
    if command -v uv >/dev/null 2>&1; then
        echo "📦 Initializing with UV..."
        uv init --no-readme

        # Add project-specific dependencies
        case "$project_type" in
            "web")
                echo "🌐 Adding web development dependencies..."
                uv add fastapi uvicorn[standard] pydantic
                uv add --dev pytest black ruff mypy
                ;;
            "data")
                echo "📊 Adding data science dependencies..."
                uv add pandas numpy matplotlib seaborn jupyter
                uv add --dev pytest black ruff mypy
                ;;
            "cli")
                echo "⌨️  Adding CLI development dependencies..."
                uv add click rich typer
                uv add --dev pytest black ruff mypy
                ;;
            "package")
                echo "📦 Adding package development dependencies..."
                uv add --dev pytest black ruff mypy build twine
                ;;
        esac

        # Create project structure
        mkdir -p src/"$project_name" tests docs

        # Create basic files
        cat > src/"$project_name"/__init__.py << EOF
"""$project_name package."""
__version__ = "0.1.0"
EOF

        cat > tests/test_basic.py << EOF
"""Basic tests for $project_name."""
import pytest
from $project_name import __version__


def test_version():
    assert __version__ == "0.1.0"
EOF

        # Create README
        cat > README.md << EOF
# $project_name

A Python $project_type project.

## Development

This project uses [UV](https://github.com/astral-sh/uv) for dependency management.

\`\`\`bash
# Install dependencies
uv sync

# Run tests
uv run pytest

# Run linting
uv run ruff check
uv run black --check .

# Format code
uv run black .
uv run ruff --fix .
\`\`\`
EOF

        echo "✅ UV project created successfully"

    else
        echo "📦 Initializing with pip/venv..."
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip

        # Create basic structure
        mkdir -p "$project_name" tests

        cat > "$project_name"/__init__.py << EOF
"""$project_name package."""
__version__ = "0.1.0"
EOF

        echo "✅ Basic project created successfully"
        echo "💡 Consider using UV for better dependency management"
    fi

    echo ""
    echo "📁 Project structure:"
    tree -a -L 2 2>/dev/null || find . -type f -name ".*" -o -type f | head -10
    echo ""
    echo "🚀 Next steps:"
    echo "  cd $project_name"
    if command -v uv >/dev/null 2>&1; then
        echo "  uv run python src/$project_name"
    else
        echo "  source venv/bin/activate"
    fi
}

# Purpose: Python environment health check
# Arguments: None
# Returns: 0 if healthy, 1 if issues found
# Usage: python_health_check
python_health_check() {
    echo "🏥 Python Environment Health Check"
    echo "=================================="

    local issues=0

    # Check Python installation
    if command -v python3 >/dev/null 2>&1; then
        echo "✅ Python3 is available: $(python3 --version)"
    else
        echo "❌ Can't find Python 3 on your computer"
        echo "💡 Install Python 3 from https://python.org or use 'brew install python3'"
        ((issues++))
    fi

    # Check pip
    if command -v pip >/dev/null 2>&1; then
        echo "✅ pip is available: $(pip --version | cut -d' ' -f2)"
    else
        echo "❌ Can't find pip (Python package installer)"
        echo "💡 Install with: python3 -m ensurepip --upgrade"
        ((issues++))
    fi

    # Check pyenv
    if command -v pyenv >/dev/null 2>&1; then
        echo "✅ pyenv is available: $(pyenv --version)"

        # Check pyenv Python installations
        local pyenv_versions=$(pyenv versions --bare | wc -l | tr -d ' ')
        echo "📊 pyenv Python versions installed: $pyenv_versions"
    else
        echo "⚠️  pyenv not available"
    fi

    # Check UV
    if command -v uv >/dev/null 2>&1; then
        echo "✅ UV is available: $(uv --version)"
    else
        echo "⚠️  UV not available (consider installing for faster package management)"
    fi

    # Check virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "✅ Virtual environment active: $(basename "$VIRTUAL_ENV")"
    else
        echo "💤 No virtual environment active"
    fi

    # Check common packages
    echo ""
    echo "📦 Common Package Status:"
    for pkg in pip setuptools wheel; do
        if python3 -c "import $pkg" 2>/dev/null; then
            echo "  ✅ $pkg"
        else
            echo "  ❌ $pkg"
            ((issues++))
        fi
    done

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "🎉 Python environment is healthy!"
        return 0
    else
        echo "⚠️  Found $issues issues in Python environment"
        echo "💡 Run 'python_fix_environment' to attempt automatic fixes"
        return 1
    fi
}

# Purpose: Attempt to fix common Python environment issues
# Arguments: None
# Returns: 0 on success, 1 on error
# Usage: python_fix_environment
python_fix_environment() {
    echo "🔧 Python Environment Auto-Fix"
    echo "=============================="

    # Upgrade pip
    if command -v pip >/dev/null 2>&1; then
        echo "📈 Upgrading pip..."
        python3 -m pip install --upgrade pip
    fi

    # Install essential packages
    echo "📦 Installing essential packages..."
    python3 -m pip install --upgrade setuptools wheel

    # Fix UV installation if missing
    if ! command -v uv >/dev/null 2>&1; then
        echo "🚀 Installing UV for faster package management..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source ~/.cargo/env 2>/dev/null || true
    fi

    echo "✅ Environment fixes applied"
    echo "🔍 Running health check..."
    python_health_check
}

# =====================================================
# ALIASES
# =====================================================

alias py-status='python_status'
alias py-switch='py_env_switch'
alias py-list='py_env_switch list'
alias py-uv='py_env_switch uv'
alias py-benchmark='python_benchmark'
alias py-jupyter='python_jupyter'
alias py-create='python_create_project'
alias py-health='python_health_check'
alias py-fix='python_fix_environment'

echo "✅ Python module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export PYTHON_MODULE_LOADED=true