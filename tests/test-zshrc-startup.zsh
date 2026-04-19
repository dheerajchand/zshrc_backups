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

# OMZ overhead knobs — all must be set before sourcing oh-my-zsh.sh.
grep -q "zstyle ':omz:update' mode disabled" "$ZSHRC_FILE" \
  || fail "missing OMZ auto-update disable"
grep -q 'ZSH_DISABLE_COMPFIX=true' "$ZSHRC_FILE" \
  || fail "missing ZSH_DISABLE_COMPFIX=true"
grep -q 'DISABLE_MAGIC_FUNCTIONS=true' "$ZSHRC_FILE" \
  || fail "missing DISABLE_MAGIC_FUNCTIONS=true"
grep -q 'DISABLE_AUTO_TITLE=true' "$ZSHRC_FILE" \
  || fail "missing DISABLE_AUTO_TITLE=true"
# Order matters: knobs must appear before the oh-my-zsh.sh source line.
_knob_line=$(grep -n "zstyle ':omz:update' mode disabled" "$ZSHRC_FILE" | head -1 | cut -d: -f1)
_omz_line=$(grep -n 'source "\$ZSH/oh-my-zsh.sh"' "$ZSHRC_FILE" | head -1 | cut -d: -f1)
[[ -n "$_knob_line" && -n "$_omz_line" && "$_knob_line" -lt "$_omz_line" ]] \
  || fail "OMZ knobs must appear before the oh-my-zsh.sh source line"

# Archived modules must not be loaded from zshrc.
_archived_modules=("$ROOT_DIR"/modules/archived/*.zsh(N:t:r))
for _m in $_archived_modules; do
    [[ "$_m" == "README" ]] && continue
    if grep -qE "^\s*load_module\s+${_m}\b" "$ZSHRC_FILE"; then
        fail "archived module '${_m}' is still loaded from zshrc"
    fi
done

# Completion cache must live under $XDG_CACHE_HOME/zsh, not the repo root.
grep -q 'XDG_CACHE_HOME:=\$HOME/.cache' "$ZSHRC_FILE" || fail "missing XDG_CACHE_HOME default"
grep -q '_zcompdump="\$XDG_CACHE_HOME/zsh/zcompdump-' "$ZSHRC_FILE" \
  || fail "_zcompdump path should be rooted in \$XDG_CACHE_HOME/zsh/"
grep -q 'compinit -d "\$_zcompdump"' "$ZSHRC_FILE" \
  || fail "compinit must target \$_zcompdump with -d (rebuild path)"
grep -q 'compinit -C -d "\$_zcompdump"' "$ZSHRC_FILE" \
  || fail "compinit fast path must target \$_zcompdump with -C -d"

# Behavioral check: executing just the compinit block writes under $XDG_CACHE_HOME/zsh,
# not into $HOME. Extract lines between the compinit comment and the `unset _zcompdump`
# marker, then run them in a subshell with scratch HOME/XDG.
_cache_tmp="$(mktemp -d 2>/dev/null)" || fail "mktemp failed"
_home_tmp="$(mktemp -d 2>/dev/null)" || fail "mktemp failed"
trap 'rm -rf "$_cache_tmp" "$_home_tmp"' EXIT
_block="$(awk '/^# Initialize completion system/,/^unset _zcompdump/' "$ZSHRC_FILE")"
[[ -n "$_block" ]] || fail "could not extract compinit block from zshrc"
HOME="$_home_tmp" XDG_CACHE_HOME="$_cache_tmp" \
  zsh -c "$_block" >/dev/null 2>&1 || fail "compinit block errored under scratch HOME/XDG"
_dumps=("$_cache_tmp"/zsh/zcompdump-*(N))
(( ${#_dumps} > 0 )) \
  || fail "expected zcompdump under \$XDG_CACHE_HOME/zsh/, found none"
_stragglers=("$_home_tmp"/.zcompdump*(N))
(( ${#_stragglers} == 0 )) \
  || fail "compinit block leaked .zcompdump* into \$HOME"

print -- "test-zshrc-startup: ok"
