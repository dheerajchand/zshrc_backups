#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${0:A}")" && pwd)"
TESTS_DIR="$ROOT_DIR/tests"

TEST_VERBOSE=0
TEST_NAME=""

usage() {
    cat <<'USAGE'
Usage: zsh run-tests.zsh [--verbose] [--list] [--test NAME]
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) TEST_VERBOSE=1; shift ;;
        --list) TEST_NAME="__list__"; shift ;;
        --test) TEST_NAME="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown arg: $1"; usage; exit 1 ;;
    esac
done

export TEST_VERBOSE
export ZSH_TEST_MODE=1

for test_file in "$TESTS_DIR"/test-*.zsh; do
    [[ -f "$test_file" ]] || continue
    [[ "$test_file" == *"/test-framework.zsh" ]] && continue
    source "$test_file"
done

if [[ "$TEST_NAME" == "__list__" ]]; then
    for name in "${TEST_NAMES[@]}"; do
        echo "$name"
    done
    exit 0
fi

if [[ -n "$TEST_NAME" ]]; then
    set +e
    run_test "$TEST_NAME"
    rc=$?
    set -e
    exit $rc
fi

set +e
run_all_tests
rc=$?
set -e
exit $rc
