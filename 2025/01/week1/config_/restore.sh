#!/bin/bash
echo "🔄 Restoring migrated zsh configuration..."
if [[ -f zshrc.txt ]]; then
    cp zshrc.txt ~/.zshrc
    echo "✅ Restored zshrc from migrated backup"
elif [[ -f zshrc ]]; then
    cp zshrc ~/.zshrc
    echo "✅ Restored zshrc from migrated backup"
else
    echo "❌ No zshrc file found in this backup"
    exit 1
fi
source ~/.zshrc
echo "✅ Configuration reloaded"
