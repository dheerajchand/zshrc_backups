#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/secrets.zsh"

_make_stub_op_secrets() {
    local bin_dir="$1"
    cat > "$bin_dir/op" <<'OP'
#!/usr/bin/env zsh
field=""
item=""
args=("$@")
for ((i=1; i<=${#args[@]}; i++)); do
  case "${args[$i]}" in
    --field=*)
      field="${args[$i]#--field=}"
      ;;
    --field)
      field="${args[$((i+1))]}"
      ;;
  esac
done
item="$3"
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "item get")
    if [[ "$item" == "svc-user" && "$field" == "password" ]]; then
      echo "op-secret"
      exit 0
    fi
    if [[ "$item" == "svc" && "$field" == "token" ]]; then
      echo "op-token"
      exit 0
    fi
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin_dir/op"
}

test_secrets_load_file() {
    local tmp file old_file old_mode
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    cat > "$file" <<'EOF'
FOO=bar
# comment
BAZ=qux
export ZSH_ENV_PROFILE=dev
EOF
    old_file="$ZSH_SECRETS_FILE"
    old_mode="$ZSH_SECRETS_MODE"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_MODE="file"
    secrets_load_file
    assert_equal "bar" "$FOO" "should load FOO from file"
    assert_equal "qux" "$BAZ" "should load BAZ from file"
    assert_equal "dev" "$ZSH_ENV_PROFILE" "should support export syntax"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_MODE="$old_mode"
    rm -rf "$tmp"
}

test_secrets_load_op() {
    local tmp bin map old_path old_map old_mode
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_op_secrets "$bin"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
FEC_API_KEY svc user password
SERVICE_TOKEN svc - token
EOF
    old_path="$PATH"
    old_map="$ZSH_SECRETS_MAP"
    old_mode="$ZSH_SECRETS_MODE"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    op() { "$bin/op" "$@"; }
    hash -r
    export ZSH_SECRETS_MAP="$map"
    export ZSH_SECRETS_MODE="op"
    export OP_ACCOUNT="test-account"
    export OP_VAULT="TestVault"
    unset FEC_API_KEY SERVICE_TOKEN
    secrets_load_op
    assert_equal "op-secret" "${FEC_API_KEY-}" "should load secret from op item get"
    assert_equal "op-token" "${SERVICE_TOKEN-}" "should load token from op item get without user"
    PATH="$old_path"
    export ZSH_SECRETS_MAP="$old_map"
    export ZSH_SECRETS_MODE="$old_mode"
    unset OP_ACCOUNT OP_VAULT
    unset -f op 2>/dev/null || true
    rm -rf "$tmp"
}

test_machine_profile_default() {
    local profile
    local old_profile="${ZSH_ENV_PROFILE-}"
    unset ZSH_ENV_PROFILE
    profile="$(machine_profile)"
    assert_true "[[ -n \"$profile\" ]]" "machine_profile should return a value"
    if [[ -n "$old_profile" ]]; then
        export ZSH_ENV_PROFILE="$old_profile"
    fi
}

test_secrets_edit_creates_file() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    old_file="$ZSH_SECRETS_FILE"
    export ZSH_SECRETS_FILE="$file"
    export EDITOR="/usr/bin/true"
    secrets_edit
    assert_true "[[ -f \"$file\" ]]" "secrets_edit should create secrets file"
    export ZSH_SECRETS_FILE="$old_file"
    rm -rf "$tmp"
}

test_secrets_sync_to_1p_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    hash -r
    out="$(secrets_sync_to_1p 2>&1 || true)"
    assert_true "[[ -n \"$out\" ]]" "sync should produce an error message"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_secrets_init_from_example() {
    local tmp file example old_file old_example
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    example="$tmp/secrets.env.example"
    cat > "$example" <<'EOF'
FOO=bar
EOF
    old_file="$ZSH_SECRETS_FILE"
    old_example="$HOME/.config/zsh/secrets.env.example"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_FILE_EXAMPLE="$example"
    secrets_init
    assert_true "[[ -f \"$file\" ]]" "secrets_init should create file"
    assert_contains "$(cat "$file")" "FOO=bar" "secrets_init should copy example"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_FILE_EXAMPLE="$old_example"
    rm -rf "$tmp"
}

test_op_list_accounts_vaults_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(op_list_accounts_vaults 2>&1 || true)"
    assert_contains "$out" "op not found" "list should require op"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_account_alias_lookup() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
ElectInfo=ABC123
EOF
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    assert_equal "ABC123" "$(_op_account_alias ElectInfo)" "alias should resolve to uuid"
    assert_equal "ElectInfo" "$(_op_account_alias_for_uuid ABC123)" "uuid should resolve to alias"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_list_accounts_vaults_empty() {
    local tmp bin old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  echo '[{"account_uuid":"UUID1","email":"u@example.com","url":"example.com"}]'
  exit 0
fi
if [[ "$1 $2" == "vault list" ]]; then
  echo '[]'
  exit 0
fi
exit 0
OP
    cat > "$bin/jq" <<'JQ'
#!/usr/bin/env zsh
if [[ "$1" == "-r" && "$2" == ".[] | \"\\(.account_uuid)\\t\\(.email)\\t\\(.url)\"" ]]; then
  echo -e "UUID1\tu@example.com\texample.com"
  exit 0
fi
if [[ "$1" == "-r" && "$2" == ".[]?.name" ]]; then
  exit 0
fi
exit 0
JQ
    chmod +x "$bin/op" "$bin/jq"
    old_path="$PATH"
    PATH="$bin:/usr/bin:/bin"
    out="$(op_list_accounts_vaults)"
    assert_contains "$out" "(none found or access denied)" "empty vault list should show placeholder"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_list_items_requires_op() {
    local tmp bin out rc
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "item list")
    echo '[]'
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source /Users/dheerajchand/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; op_list_items' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "op_list_items should fail on empty list"
    assert_contains "$out" "No items found" "op_list_items should warn on empty list"
    rm -rf "$tmp"
}

test_secrets_pull_requires_op() {
    local tmp bin out rc
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "item get")
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source /Users/dheerajchand/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; secrets_pull_from_1p' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "secrets_pull_from_1p should fail on empty field"
    assert_contains "$out" "No secrets_file field" "secrets_pull_from_1p should warn on empty field"
    rm -rf "$tmp"
}

test_secrets_profile_switch_usage() {
    local out
    out="$(secrets_profile_switch 2>&1 || true)"
    assert_contains "$out" "Usage: secrets_profile_switch" "should show usage on missing args"
}

test_secrets_profile_switch_sets_profile() {
    local old_profile="${ZSH_ENV_PROFILE-}"
    ZSH_SECRETS_MODE=off
    secrets_profile_switch dev >/dev/null 2>&1
    assert_equal "dev" "$ZSH_ENV_PROFILE" "should set ZSH_ENV_PROFILE"
    if [[ -n "$old_profile" ]]; then
        export ZSH_ENV_PROFILE="$old_profile"
    fi
}

test_secrets_sync_to_1p_with_account_vault() {
    local tmp bin file old_file old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/secrets.env"
    echo "FOO=bar" > "$file"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  exit 0
fi
if [[ "$1 $2" == "item create" ]]; then
  printf '%s\n' "$@" > "${OP_ARGS_FILE}"
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_file="$ZSH_SECRETS_FILE"
    old_path="$PATH"
    export ZSH_SECRETS_FILE="$file"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    export OP_ARGS_FILE="$tmp/op.args"
    out="$(secrets_sync_to_1p "zsh-secrets-env" "acct-1" "VaultA" 2>&1)"
    assert_true "[[ -f \"$tmp/op.args\" ]]" "sync should call op item create"
    assert_contains "$(cat "$tmp/op.args")" "--account=acct-1" "should pass account arg"
    assert_contains "$(cat "$tmp/op.args")" "--vault=VaultA" "should pass vault arg"
    export ZSH_SECRETS_FILE="$old_file"
    PATH="$old_path"
    unset OP_ARGS_FILE
    rm -rf "$tmp"
}

test_vault_without_account_warns() {
    local out old_account
    old_account="${OP_ACCOUNT-}"
    unset OP_ACCOUNT
    out="$(secrets_sync_to_1p "zsh-secrets-env" "" "VaultA" 2>&1 || true)"
    assert_contains "$out" "Vault specified without account; refusing to sync" "should reject vault without account"
    if [[ -n "${old_account-}" ]]; then
        export OP_ACCOUNT="$old_account"
    fi
}

register_test "test_secrets_load_file" "test_secrets_load_file"
register_test "test_secrets_load_op" "test_secrets_load_op"
register_test "test_machine_profile_default" "test_machine_profile_default"
register_test "test_secrets_edit_creates_file" "test_secrets_edit_creates_file"
register_test "test_secrets_sync_to_1p_requires_op" "test_secrets_sync_to_1p_requires_op"
register_test "test_secrets_sync_to_1p_with_account_vault" "test_secrets_sync_to_1p_with_account_vault"
register_test "test_secrets_init_from_example" "test_secrets_init_from_example"
register_test "test_op_list_accounts_vaults_requires_op" "test_op_list_accounts_vaults_requires_op"
register_test "test_op_account_alias_lookup" "test_op_account_alias_lookup"
register_test "test_op_list_accounts_vaults_empty" "test_op_list_accounts_vaults_empty"
register_test "test_op_list_items_requires_op" "test_op_list_items_requires_op"
register_test "test_secrets_pull_requires_op" "test_secrets_pull_requires_op"
register_test "test_secrets_profile_switch_usage" "test_secrets_profile_switch_usage"
register_test "test_secrets_profile_switch_sets_profile" "test_secrets_profile_switch_sets_profile"
register_test "test_vault_without_account_warns" "test_vault_without_account_warns"
