#!/usr/bin/env zsh
# =================================================================
# BACKUP - Load Comprehensive Backup System
# =================================================================
# Loads the full-featured backup system from git history
# while maintaining backward compatibility with simple commands
# =================================================================

# Source the comprehensive backup system
if [[ -f "$HOME/.config/zsh/backup-system.zsh" ]]; then
    source "$HOME/.config/zsh/backup-system.zsh"
    echo "✅ Comprehensive backup system loaded (864 lines)"
else
    echo "⚠️  Comprehensive backup system not found at backup-system.zsh"
    echo "⚠️  Using minimal backup functions"
fi

# Add backward compatibility aliases for the old simple interface
if type enhanced_backup >/dev/null 2>&1; then
    # Comprehensive system loaded - use its functions
    alias pushmain='enhanced_backup'
    alias repo_sync='sync_zsh'
    alias repo_status='zsh_repo_status'
    alias list_backups='list_zsh_backups'
    alias dedupe_path='deduplicate_path'
else
    echo "⚠️  Using minimal backup fallback"
    alias pushmain='backup'
    alias repo_sync='sync'
    alias repo_status='repo_status'
fi

echo "✅ backup module loaded"
