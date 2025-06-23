# =====================================================
# CORE SHELL SETUP
# =====================================================
# oh-my-zsh configuration
export ZSH=$HOME/.dotfiles/oh-my-zsh
export ZSH_THEME="powerlevel9k/powerlevel9k"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir nvm vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history time)
export CASE_SENSITIVE="true"
export DISABLE_AUTO_TITLE="true"
plugins=(colorize compleat dirpersist autojump git gulp history cp)

# Load oh-my-zsh if available
[[ -s "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Shell behavior
autoload -U add-zsh-hook
unsetopt correct

# Basic aliases
alias vim="nvim"
alias edit="nvim"

# MacOS settings
defaults write -g ApplePressAndHoldEnabled -bool true 2>/dev/null || true
export WORKING_ON_LAPTOP="True"

# Default editor
export EDITOR="zed"
export VISUAL="zed"

function zshreboot {
    source ~/.zshrc
}

function zshconfig {
    zed ~/.config/zsh/
}
