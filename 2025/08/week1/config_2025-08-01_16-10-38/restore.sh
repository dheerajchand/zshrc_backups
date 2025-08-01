#!/bin/bash
echo "🔄 Restoring modular zsh configuration..."
if [[ -f ~/.zshrc ]]; then
    echo "💾 Backing up current config..."
    cp ~/.zshrc ~/.zshrc.pre-restore.$(date +%s)
fi
echo "📂 Restoring main zshrc..."
cp zshrc.txt ~/.zshrc
if [[ -d zsh ]]; then
    echo "📂 Restoring modular config..."
    mkdir -p ~/.config
    cp -r zsh ~/.config/
fi
echo "✅ Configuration restored!"
source ~/.zshrc
