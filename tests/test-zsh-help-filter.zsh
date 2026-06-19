#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

# Re-implement just the help body + filter from zshrc — sourcing the
# whole zshrc into a test would drag every module. The filter is the
# logic we want to test; the body is a fixture.
_zsh_help_body() {
    cat <<'EOF'
🚀 ZSH Quick Reference
====================

🐍 Python:
  py_env_switch [env]    - Switch Python environment
  python_status          - Show current environment

🔐 Secrets:
  secrets_status         - Show secrets loader status
  op_accounts_edit       - Edit 1Password account aliases
  op_signin_all          - Sign in to all account aliases
  op_signin_account      - Sign in to one account alias

💽 Disk:
  disk_audit [N]         - Top space consumers
  disk_clean_caches      - Sweep regenerable caches

📚 Full docs: example
EOF
}

# Copy of the filter from zshrc (kept in sync by hand; if the filter
# logic gets a third call site, hoist to a shared lib).
zsh_help() {
    local filter="${1:-}"
    if [[ -z "$filter" ]]; then
        _zsh_help_body
        return 0
    fi
    local -a lines
    lines=("${(@f)$(_zsh_help_body)}")
    local lc_filter="${filter:l}"
    local current_header="" lc_header="" line first_token lc_token
    local -a section_buf
    local -i printed=0 in_match_section=0
    for line in "${lines[@]}"; do
        if [[ "$line" == *:* && "$line" != "  "* && "$line" != "==="* && -n "$line" && "${line[1]}" != [a-zA-Z🚀📚] ]]; then
            if (( in_match_section )); then
                printf '%s\n' "${section_buf[@]}"
                printed=1
                in_match_section=0
            fi
            current_header="$line"
            lc_header="${current_header:l}"
            section_buf=("$current_header")
            if [[ "$lc_header" == *"$lc_filter"* ]]; then
                in_match_section=1
            fi
            continue
        fi
        if (( in_match_section )); then
            section_buf+=("$line")
            continue
        fi
        if [[ "$line" == "  "[a-zA-Z_]* ]]; then
            first_token="${${line##  }%% *}"
            lc_token="${first_token:l}"
            if [[ "$lc_token" == "$lc_filter"* ]]; then
                [[ -n "$current_header" ]] && printf '%s\n' "$current_header"
                printf '%s\n' "$line"
                printed=1
            fi
        fi
    done
    if (( in_match_section )); then
        printf '%s\n' "${section_buf[@]}"
        printed=1
    fi
    if (( ! printed )); then
        echo "zsh_help: no matches for '$filter' (try: zsh_help with no arg)" >&2
        return 0
    fi
}

test_no_arg_full_dump() {
    local out
    out=$(zsh_help)
    assert_contains "$out" 'ZSH Quick Reference' 'no-arg call prints full reference'
    assert_contains "$out" 'op_signin_all' 'no-arg call includes op_signin_all'
    assert_contains "$out" 'disk_audit'    'no-arg call includes disk_audit'
}

test_section_filter_secrets() {
    local out
    out=$(zsh_help secrets)
    assert_contains "$out" '🔐 Secrets:'    'section filter prints Secrets header'
    assert_contains "$out" 'op_signin_all'  'section filter includes section body'
    assert_false "[[ '$out' == *'Python:'* ]]" 'section filter excludes other sections'
    assert_false "[[ '$out' == *'disk_audit'* ]]" 'section filter excludes disk section'
}

test_section_filter_disk() {
    local out
    out=$(zsh_help disk)
    assert_contains "$out" 'disk_audit'    'disk section appears'
    assert_false "[[ '$out' == *'op_signin_all'* ]]" 'op_signin_all not in disk section'
}

test_function_name_filter() {
    local out
    out=$(zsh_help op_signin_all)
    assert_contains "$out" 'op_signin_all' 'function filter prints the target'
    assert_contains "$out" '🔐 Secrets:'   'function filter prints section header for context'
    assert_false "[[ '$out' == *'op_signin_account'* ]]" 'exact-prefix match excludes other op_signin_*'
}

test_function_name_filter_prefix() {
    # Prefix match: zsh_help op_signin finds both op_signin_all and
    # op_signin_account. zsh_help signin (no prefix) does NOT — users
    # type the prefix they remember.
    local out
    out=$(zsh_help op_signin)
    assert_contains "$out" 'op_signin_all'      'prefix matches op_signin_all'
    assert_contains "$out" 'op_signin_account'  'prefix matches op_signin_account'
}

test_zsh_help_op_lists_op_commands() {
    # Primary UX path: the user types `zsh_help op` and expects to see
    # the op_* surface. Regression guard for the substring → prefix
    # refactor (CodeRabbit feedback on PR #169).
    local out
    out=$(zsh_help op)
    assert_contains "$out" 'op_signin_all'  'zsh_help op surfaces op_signin_all'
    assert_contains "$out" 'op_signin_account' 'zsh_help op surfaces op_signin_account'
    assert_contains "$out" 'op_accounts_edit'  'zsh_help op surfaces op_accounts_edit'
}

test_no_match() {
    local out rc
    out=$(zsh_help foo_does_not_exist 2>&1)
    rc=$?
    assert_equal '0' "$rc"                  'no-match still exits 0'
    assert_contains "$out" 'no matches for'  'no-match prints hint'
}

test_case_insensitive() {
    local out
    out=$(zsh_help SECRETS)
    assert_contains "$out" '🔐 Secrets:' 'filter is case-insensitive'
}

register_test "no_arg_full_dump"          test_no_arg_full_dump
register_test "section_filter_secrets"    test_section_filter_secrets
register_test "section_filter_disk"       test_section_filter_disk
register_test "function_name_filter"      test_function_name_filter
register_test "function_name_filter_pre"  test_function_name_filter_prefix
register_test "zsh_help_op_lists_op"      test_zsh_help_op_lists_op_commands
register_test "no_match"                  test_no_match
register_test "case_insensitive"          test_case_insensitive
