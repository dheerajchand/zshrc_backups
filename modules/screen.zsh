#!/usr/bin/env zsh
# =================================================================
# SCREEN - GNU screen session helpers
# =================================================================

screen_ensure_pyenv() {
    local zshenv="$HOME/.zshenv"
    local zshrc="$HOME/.zshrc"
    local marker="# pyenv (screen)"
    if [[ -f "$zshenv" ]] && ! grep -q "$marker" "$zshenv" 2>/dev/null; then
        cat >> "$zshenv" <<'PYENV'

# pyenv (screen)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
PYENV
    elif [[ ! -f "$zshenv" ]]; then
        cat >> "$zshenv" <<'PYENV'
# pyenv (screen)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
PYENV
    fi

    if [[ -f "$zshrc" ]] && ! grep -q "$marker" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'PYENV'

# pyenv (screen)
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
PYENV
    elif [[ ! -f "$zshrc" ]]; then
        cat >> "$zshrc" <<'PYENV'
# pyenv (screen)
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
PYENV
    fi
    echo "✅ screen pyenv setup applied"
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ screen loaded"
fi
