#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/utils.zsh"

test_command_exists_basic() {
    assert_true "command_exists echo" "echo should exist"
}

test_path_add_and_clean() {
    local old_path="$PATH"
    PATH="/bin:/bin:/usr/bin"
    path_add "/tmp" "append"
    assert_contains "$PATH" "/tmp" "path_add should append new dir"
    path_clean >/dev/null
    local count
    count="$(printf '%s' "$PATH" | tr ':' '\n' | grep -c "^/bin$")"
    assert_equal "1" "$count" "path_clean should dedupe entries"
    PATH="$old_path"
}

test_download_jars_stub() {
    local old_path="$PATH"
    local tmp bin dest jar
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    dest="$tmp/jars"
    mkdir -p "$bin"
    cat > "$bin/curl" <<'CURL'
#!/usr/bin/env zsh
out=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            out="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
[[ -n "$out" ]] || exit 1
mkdir -p "$(dirname "$out")"
echo "stub" > "$out"
CURL
    chmod +x "$bin/curl"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    download_jars --dest "$dest" "org.example:demo:1.0.0"
    jar="$dest/demo-1.0.0.jar"
    assert_true "[[ -f \"$jar\" ]]" "download_jars should create jar file"
    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "utils_command_exists" test_command_exists_basic
register_test "utils_path_add_clean" test_path_add_and_clean
register_test "utils_download_jars" test_download_jars_stub
