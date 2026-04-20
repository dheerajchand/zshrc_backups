#!/usr/bin/env zsh
# Startup-time budget test.
#
# Runs `zsh -i -c exit` several times, computes the median wall-clock time
# (excluding a warm-up sample), and fails if it exceeds ZSH_STARTUP_BUDGET_MS.
# Uses deterministic env:
#   ZSH_FORCE_FULL_INIT=1         — skip non-TTY fast path
#   ZSH_STATUS_BANNER_MODE=off    — skip heavy status banner
#   ZSH_AUTO_RECOVER_MODE=off     — skip service auto-recovery
#
# Overrides:
#   ZSH_STARTUP_BUDGET_MS=1500 zsh tests/test-startup-budget.zsh
#   SKIP_STARTUP_BUDGET=1 (skips entirely — escape hatch for flaky CI)

# The test runner sources this file; everything lives inside a function so
# that `local` is legal and `return` doesn't abort the whole test suite.
_test_startup_budget() {
    emulate -L zsh
    setopt errexit nounset pipefail

    if [[ "${SKIP_STARTUP_BUDGET:-0}" == "1" ]]; then
        print -- "test-startup-budget: skipped (SKIP_STARTUP_BUDGET=1)"
        return 0
    fi

    # Budget chosen to catch real regressions without being flaky. Local
    # measurement on a warm shell runs ~500ms; cold-cache first samples can
    # hit >1s. The first run is discarded as warm-up; median is taken over
    # the remaining samples.
    : "${ZSH_STARTUP_BUDGET_MS:=2500}"
    : "${ZSH_STARTUP_RUNS:=6}"  # 1 warm-up + 5 measured

    zmodload zsh/datetime 2>/dev/null || {
        print -u2 -- "FAIL: zsh/datetime module unavailable"
        return 1
    }

    local -a samples
    local i t0 t1 ms
    for (( i = 1; i <= ZSH_STARTUP_RUNS; i++ )); do
        t0="$EPOCHREALTIME"
        ZSH_FORCE_FULL_INIT=1 \
            ZSH_STATUS_BANNER_MODE=off \
            ZSH_AUTO_RECOVER_MODE=off \
            zsh -i -c exit >/dev/null 2>&1
        t1="$EPOCHREALTIME"
        ms=$(( (t1 - t0) * 1000 ))
        ms=${ms%.*}
        samples+=("$ms")
    done

    # Discard the first sample as warm-up; take the median of the rest.
    local -a measured sorted
    measured=("${(@)samples[2,-1]}")
    sorted=(${(on)measured})
    local n=${#sorted}
    local mid_idx=$(( (n + 1) / 2 ))
    local median="${sorted[$mid_idx]}"

    print -- "startup samples (ms): ${samples[*]}   (first = warm-up, discarded)"
    print -- "sorted (measured):    ${sorted[*]}"
    print -- "median:               ${median}ms  (budget: ${ZSH_STARTUP_BUDGET_MS}ms)"

    if (( median > ZSH_STARTUP_BUDGET_MS )); then
        print -u2 -- "FAIL: startup median ${median}ms exceeds budget ${ZSH_STARTUP_BUDGET_MS}ms"
        return 1
    fi

    print -- "test-startup-budget: ok"
    return 0
}

_test_startup_budget
_startup_rc=$?
unfunction _test_startup_budget 2>/dev/null
# When executed directly (not sourced by run-tests.zsh), propagate the rc.
if [[ "${ZSH_EVAL_CONTEXT:-toplevel}" != *file* ]]; then
    exit $_startup_rc
fi
# When sourced, only abort if the test failed — matches the style of
# tests/test-zshrc-startup.zsh.
if (( _startup_rc != 0 )); then
    exit $_startup_rc
fi
unset _startup_rc
