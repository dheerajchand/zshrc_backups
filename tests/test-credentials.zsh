#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/credentials.zsh"

_make_stub_op() {
    local bin_dir="$1"
    cat > "$bin_dir/op" <<'OP'
#!/usr/bin/env zsh
cmd="$1"
sub="$2"
case "$cmd $sub" in
    "account list")
        exit 0
        ;;
    "item get")
        item="$3"
        if [[ -z "${OP_STUB_ITEM:-}" || "$item" == "$OP_STUB_ITEM" ]]; then
            echo "${OP_STUB_VALUE:-op-value}"
            exit 0
        fi
        exit 1
        ;;
    "item edit")
        exit 0
        ;;
    "item create")
        exit 0
        ;;
    "item list")
        echo "[]"
        exit 0
        ;;
    "item delete")
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
OP
    chmod +x "$bin_dir/op"
}

_make_stub_security() {
    local bin_dir="$1"
    cat > "$bin_dir/security" <<'SEC'
#!/usr/bin/env zsh
cmd="$1"
case "$cmd" in
    find-generic-password)
        echo "${SECURITY_STUB_VALUE:-kc-value}"
        exit 0
        ;;
    add-generic-password)
        exit 0
        ;;
    delete-generic-password)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
SEC
    chmod +x "$bin_dir/security"
}

_make_stub_bin() {
    local bin_dir="$1"
    mkdir -p "$bin_dir"
    _make_stub_op "$bin_dir"
    _make_stub_security "$bin_dir"
    cat > "$bin_dir/vault" <<'VAULT'
#!/usr/bin/env zsh
exit 0
VAULT
    chmod +x "$bin_dir/vault"
    cat > "$bin_dir/aws" <<'AWS'
#!/usr/bin/env zsh
exit 0
AWS
    chmod +x "$bin_dir/aws"
}

test_get_credential_env() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    PATH="$bin:/usr/bin:/bin"
    export CRED_BACKENDS="env"
    export CRED_STORE_BACKENDS="op keychain"
    export PGPASSWORD="pgpass"
    local out
    out="$(get_credential postgres user)"
    assert_equal "pgpass" "$out" "env backend should return PGPASSWORD"
    unset PGPASSWORD
    PATH="$old_path"
    rm -rf "$tmp"
}

test_get_credential_op_priority() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    _make_stub_bin "$bin"
    PATH="$bin:/usr/bin:/bin"
    export CRED_BACKENDS="op keychain"
    export CRED_STORE_BACKENDS="op keychain"
    export OP_STUB_ITEM="svc-user"
    export OP_STUB_VALUE="op-pass"
    export SECURITY_STUB_VALUE="kc-pass"
    local out
    out="$(get_credential svc user)"
    assert_equal "op-pass" "$out" "op backend should take priority"
    unset OP_STUB_ITEM OP_STUB_VALUE SECURITY_STUB_VALUE
    PATH="$old_path"
    rm -rf "$tmp"
}

test_get_credential_keychain() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    _make_stub_bin "$bin"
    PATH="$bin:/usr/bin:/bin"
    export CRED_BACKENDS="keychain"
    export CRED_STORE_BACKENDS="op keychain"
    export SECURITY_STUB_VALUE="kc-pass"
    local out
    out="$(get_credential svc user)"
    assert_equal "kc-pass" "$out" "keychain backend should return security value"
    unset SECURITY_STUB_VALUE
    PATH="$old_path"
    rm -rf "$tmp"
}

test_store_credential_multiple_backends() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    _make_stub_bin "$bin"
    PATH="$bin:/usr/bin:/bin"
    export CRED_BACKENDS="op keychain"
    export CRED_STORE_BACKENDS="op keychain"
    local out
    out="$(store_credential svc user secret)"
    assert_contains "$out" "Stored in 2 backend(s)" "store should report two backends"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_backend_status_output() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    _make_stub_bin "$bin"
    PATH="$bin:/usr/bin:/bin"
    local out
    out="$(credential_backend_status)"
    assert_contains "$out" "1Password: Ready" "status should show 1Password ready"
    assert_contains "$out" "Keychain: Available" "status should show Keychain available"
    assert_contains "$out" "Vault:" "status should mention Vault"
    assert_contains "$out" "AWS Secrets Manager" "status should mention AWS Secrets Manager"
    assert_contains "$out" "Environment variables:" "status should show env section"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_unknown_backend_warns() {
    local old_path="$PATH"
    local tmp bin err
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    _make_stub_bin "$bin"
    PATH="$bin:/usr/bin:/bin"
    export CRED_BACKENDS="bogus op"
    err="$tmp/err.log"
    get_credential svc user 2>"$err" >/dev/null || true
    assert_contains "$(cat "$err")" "Unknown credential backend: bogus" "unknown backend should warn"
    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "test_get_credential_env" "test_get_credential_env"
register_test "test_get_credential_op_priority" "test_get_credential_op_priority"
register_test "test_get_credential_keychain" "test_get_credential_keychain"
register_test "test_store_credential_multiple_backends" "test_store_credential_multiple_backends"
register_test "test_backend_status_output" "test_backend_status_output"
register_test "test_unknown_backend_warns" "test_unknown_backend_warns"
