#!/usr/bin/env zsh
# =====================================================
# PATHS MODULE - Compatibility Bridge
# =====================================================
#
# This module provides compatibility between the old and new systems.
# It loads the new system.module.zsh which contains all PATH functions.
#
# Bridge: Old system → New modular system
# =====================================================

# Load the new system module which contains PATH management
if [[ -f "$ZSH_MODULES_DIR/system.module.zsh" ]]; then
    source "$ZSH_MODULES_DIR/system.module.zsh"
else
    echo "⚠️ New system module not found at $ZSH_MODULES_DIR/system.module.zsh"
    echo "💡 PATH functions may not be available"
fi