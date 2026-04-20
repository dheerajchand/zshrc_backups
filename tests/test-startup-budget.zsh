#!/usr/bin/env zsh
# Startup-time budget test.
#
# Runs `zsh -i -c exit` N times, computes the median wall-clock time,
# and fails if it exceeds ZSH_STARTUP_BUDGET_MS. Uses deterministic env:
#   ZSH_FORCE_FULL_INIT=1         — skip non-TTY fast path
#   ZSH_STATUS_BANNER_MODE=off    — skip heavy status banner
#   ZSH_AUTO_RECOVER_MODE=off     — skip service auto-recovery
#
# Budget can be overridden for local debugging:
#   ZSH_STARTUP_BUDGET_MS=1500 zsh tests/test-startup-budget.zsh
#
# CI skips the test entirely if SKIP_STARTUP_BUDGET=1 (escape hatch for
# known-slow transient CI environments).

set -euo pipefail

ROOT_DIR="${0:A:h:h}"

fail() {
    print -u2 -- "FAIL: $1"
    exit 1
}

if [[ "${SKIP_STARTUP_BUDGET:-0}" == "1" ]]; then
    print -- "test-startup-budget: skipped (SKIP_STARTUP_BUDGET=1)"
    exit 0
fi

# Budget chosen to catch real regressions without being flaky. Local
# measurement on a warm shell runs ~500ms; cold-cache first samples can
# hit >1s. The first run is discarded as warm-up; median is taken over
# the remaining samples.
: "${ZSH_STARTUP_BUDGET_MS:=2500}"
: "${ZSH_STARTUP_RUNS:=6}"  # 1 warm-up + 5 measured

# High-resolution wall-clock via $EPOCHREALTIME (seconds.microseconds).
zmodload zsh/datetime 2>/dev/null || fail "zsh/datetime module unavailable"

typeset -a samples
for (( i = 1; i <= ZSH_STARTUP_RUNS; i++ )); do
    local t0="$EPOCHREALTIME"
    ZSH_FORCE_FULL_INIT=1 \
        ZSH_STATUS_BANNER_MODE=off \
        ZSH_AUTO_RECOVER_MODE=off \
        zsh -i -c exit >/dev/null 2>&1
    local t1="$EPOCHREALTIME"
    # Whole-millisecond wall-clock delta (integer ms).
    local ms=$(( (t1 - t0) * 1000 ))
    ms=${ms%.*}
    samples+=("$ms")
done

# Discard the first sample as warm-up; take the median of the rest.
typeset -a measured
measured=("${(@)samples[2,-1]}")
typeset -a sorted
sorted=(${(on)measured})
local n=${#sorted}
local mid_idx=$(( (n + 1) / 2 ))
local median="${sorted[$mid_idx]}"

print -- "startup samples (ms): ${samples[*]}   (first = warm-up, discarded)"
print -- "sorted (measured):    ${sorted[*]}"
print -- "median:               ${median}ms  (budget: ${ZSH_STARTUP_BUDGET_MS}ms)"

if (( median > ZSH_STARTUP_BUDGET_MS )); then
    fail "startup median ${median}ms exceeds budget ${ZSH_STARTUP_BUDGET_MS}ms"
fi

print -- "test-startup-budget: ok"
