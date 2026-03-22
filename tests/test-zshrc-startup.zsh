#!/usr/bin/env zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
ZSHRC_FILE="$ROOT_DIR/zshrc"

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

grep -q '_zsh_is_warp_terminal()' "$ZSHRC_FILE" || fail "missing Warp detection helper"
grep -q '_zsh_show_full_startup_banner()' "$ZSHRC_FILE" || fail "missing startup banner mode helper"
grep -q '_zsh_should_auto_recover_services()' "$ZSHRC_FILE" || fail "missing auto recover mode helper"
grep -q 'ZSH_STATUS_BANNER_MODE:=auto' "$ZSHRC_FILE" || fail "missing banner mode default"
grep -q 'ZSH_AUTO_RECOVER_MODE:=auto' "$ZSHRC_FILE" || fail "missing auto-recover mode default"
grep -q 'if _zsh_should_auto_recover_services; then' "$ZSHRC_FILE" || fail "missing guarded auto-recover call"
grep -q 'if _zsh_show_full_startup_banner; then' "$ZSHRC_FILE" || fail "missing guarded banner call"

print -- "test-zshrc-startup: ok"
