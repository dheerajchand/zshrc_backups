#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_tests_readme_lists_all_test_files() {
    local readme="$ROOT_DIR/tests/README.md"
    assert_true "[[ -f \"$readme\" ]]" "tests/README.md should exist"
    local files
    files=("${ROOT_DIR}/tests"/test-*.zsh)
    local f base
    for f in "${files[@]}"; do
        [[ "$f" == *"/test-framework.zsh" ]] && continue
        base="$(basename "$f")"
        assert_contains "$(cat "$readme")" "$base" "tests/README.md should list $base"
    done
}

test_testing_docs_exist() {
    assert_true "[[ -f \"$ROOT_DIR/wiki/Testing-Framework.md\" ]]" "wiki/Testing-Framework.md should exist"
}

register_test "test_tests_readme_lists_all_test_files" "test_tests_readme_lists_all_test_files"
register_test "test_testing_docs_exist" "test_testing_docs_exist"
