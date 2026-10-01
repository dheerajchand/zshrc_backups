#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

# Stub `op` to fail loudly: any invocation marks the test impure.
typeset -g _OP_STUB_CALLS=0
op() {
    (( _OP_STUB_CALLS++ ))
    echo "op stub: must not be called during --help" >&2
    return 99
}

# Source the module under test AFTER stubbing `op`.
source "$ROOT_DIR/modules/secrets/1password-cli.zsh"

typeset -ga _OP_PUBLIC_FUNCS=(
    op_accounts_edit
    op_accounts_sanitize
    op_accounts_set_alias
    op_accounts_seed
    op_verify_accounts
    op_set_default
    op_list_accounts_vaults
    op_list_items
    op_find_item_across_accounts
    op_signin_account
    op_signin_all
    op_sessions_source
    op_set_default_alias
)

# One generated test per public function: --help returns 0, prints Usage,
# does not invoke the op binary.
_make_help_test() {
    local fn="$1"
    eval "
test_${fn}_help_long() {
    _OP_STUB_CALLS=0
    local out rc
    out=\$($fn --help 2>&1)
    rc=\$?
    assert_equal '0' \"\$rc\" '${fn} --help should exit 0'
    assert_contains \"\$out\" 'Usage:' '${fn} --help should print Usage:'
    assert_equal '0' \"\$_OP_STUB_CALLS\" '${fn} --help must not invoke op'
}

test_${fn}_help_short() {
    _OP_STUB_CALLS=0
    local rc
    $fn -h >/dev/null 2>&1
    rc=\$?
    assert_equal '0' \"\$rc\" '${fn} -h should exit 0'
    assert_equal '0' \"\$_OP_STUB_CALLS\" '${fn} -h must not invoke op'
}
"
    register_test "${fn}_help_long"  "test_${fn}_help_long"
    register_test "${fn}_help_short" "test_${fn}_help_short"
}

for fn in "${_OP_PUBLIC_FUNCS[@]}"; do
    _make_help_test "$fn"
done

# Sanity: --help is recognized even when the function would normally
# error on bad args (op_accounts_set_alias requires <alias> <uuid>).
test_help_overrides_required_args() {
    _OP_STUB_CALLS=0
    local out rc
    out=$(op_accounts_set_alias --help 2>&1)
    rc=$?
    assert_equal '0' "$rc" '--help bypasses required-arg check'
    assert_contains "$out" 'Usage: op_accounts_set_alias' 'prints function-specific synopsis'
}
register_test "help_overrides_required_args" test_help_overrides_required_args
