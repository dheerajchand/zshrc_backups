#!/bin/bash
echo "🔄 Restoring original monolithic zshrc configuration..."

# Backup current state before restore
if [[ -f ~/.zshrc ]]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%s)
fi

# Remove modular config
if [[ -d ~/.config/zsh ]]; then
    echo "📂 Backing up modular config..."
    mv ~/.config/zsh ~/.config/zsh.backup.$(date +%s)
fi

# Restore original
cp zshrc.txt ~/.zshrc

echo "✅ Original configuration restored!"
echo "🔄 Please restart your shell or run: source ~/.zshrc"
