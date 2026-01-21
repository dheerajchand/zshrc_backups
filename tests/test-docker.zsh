#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/docker.zsh"

_make_stub_docker() {
    local bin_dir="$1"
    cat > "$bin_dir/docker" <<'DOCKER'
#!/usr/bin/env zsh
cmd="$1"
shift
case "$cmd" in
    info)
        exit 0
        ;;
    --version)
        echo "Docker version 24.0.0, build stub"
        exit 0
        ;;
    system)
        if [[ "$1" == "df" ]]; then
            echo "TYPE TOTAL ACTIVE SIZE RECLAIMABLE"
            exit 0
        fi
        ;;
    ps)
        if [[ "$1" == "-q" ]]; then
            exit 0
        fi
        echo ""
        exit 0
        ;;
    images)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
DOCKER
    chmod +x "$bin_dir/docker"
}

test_docker_status_output() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_docker "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(docker_status 2>&1)"
    assert_contains "$out" "Docker Status" "docker_status should print header"
    assert_contains "$out" "Running containers: 0" "docker_status should show running count"
    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "docker_status" test_docker_status_output
