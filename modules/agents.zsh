#!/usr/bin/env zsh
# =================================================================
# AGENTS - Codex & Claude session helpers
# =================================================================

: "${CODEX_SESSIONS_FILE:=$HOME/.config/zsh/codex-sessions.env}"
: "${CLAUDE_SESSIONS_FILE:=$HOME/.config/zsh/claude-sessions.env}"

# =================================================================
# Generic session manager — parameterized by tool name & file
# =================================================================

_agent_sessions_ensure_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        umask 077
        touch "$file" 2>/dev/null || return 1
    fi
    return 0
}

_agent_sessions_list_keys() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    awk -F'=' '/^[[:space:]]*#/{next} /^[[:space:]]*$/{next} {print $1}' "$file"
}

_agent_sessions_get() {
    local key="$1" file="$2"
    [[ -f "$file" ]] || return 1
    awk -F'=' -v k="$key" '$1==k {print $2; found=1} END {exit found?0:1}' "$file"
}

_agent_session_add() {
    local tool="$1" file="$2"; shift 2
    local key="" value=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --value) value="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session_add --name <name> --value <id>|<description>" >&2; return 0 ;;
            *) if [[ -z "$key" ]]; then key="$1"; else value="${value:+$value }$1"; fi; shift ;;
        esac
    done
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: ${tool}_session_add --name <name> --value <id>|<description>" >&2
        return 1
    fi
    _agent_sessions_ensure_file "$file" || { echo "Cannot write $file" >&2; return 1; }
    if _agent_sessions_get "$key" "$file" >/dev/null 2>&1; then
        echo "Key exists: $key (use ${tool}_session_update)" >&2; return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$file"
}

_agent_session_update() {
    local tool="$1" file="$2"; shift 2
    local key="" value=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --value) value="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session_update --name <name> --value <id>|<description>" >&2; return 0 ;;
            *) if [[ -z "$key" ]]; then key="$1"; else value="${value:+$value }$1"; fi; shift ;;
        esac
    done
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: ${tool}_session_update --name <name> --value <id>|<description>" >&2; return 1
    fi
    _agent_sessions_ensure_file "$file" || { echo "Cannot write $file" >&2; return 1; }
    local tmp; tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" -v v="$value" 'BEGIN{u=0} $1==k{print k"="v;u=1;next} {print} END{if(!u)exit 2}' "$file" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then rm -f "$tmp"; echo "Key not found: $key" >&2; return 1; fi
    mv "$tmp" "$file"
}

_agent_session_remove() {
    local tool="$1" file="$2" key="$3"
    if [[ -z "$key" ]]; then echo "Usage: ${tool}_session_remove <name>" >&2; return 1; fi
    local tmp; tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" '$1==k{r=1;next}{print}END{if(!r)exit 2}' "$file" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then rm -f "$tmp"; echo "Key not found: $key" >&2; return 1; fi
    mv "$tmp" "$file"
}

_agent_session_list() {
    local tool="$1" file="$2"
    _agent_sessions_ensure_file "$file" || return 1
    echo "${tool} sessions: $file"
    awk -F'=' '/^[[:space:]]*#/{next}/^[[:space:]]*$/{next}{printf "%-20s | %s\n",$1,$2}' "$file"
}

_agent_session_edit() {
    local file="$1"
    _agent_sessions_ensure_file "$file" || return 1
    "${EDITOR:-vi}" "$file"
}

_agent_session_resume() {
    local tool="$1" file="$2"; shift 2
    local key="" auto_exec_var="${(U)tool}_SESSION_AUTO_EXEC_NONINTERACTIVE"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session [--name <key>]" >&2; return 0 ;;
            *) key="$1"; shift ;;
        esac
    done
    _agent_sessions_ensure_file "$file" || return 1
    if [[ -z "$key" ]]; then
        if command -v fzf >/dev/null 2>&1; then
            key="$(_agent_sessions_list_keys "$file" | fzf --prompt="${tool} session> ")"
        else
            local keys; keys=($(_agent_sessions_list_keys "$file"))
            if [[ ${#keys[@]} -eq 0 ]]; then echo "No sessions saved." >&2; return 1; fi
            echo "Select session:"
            select key in "${keys[@]}"; do break; done
        fi
    fi
    [[ -z "$key" ]] && return 1
    local entry; entry="$(_agent_sessions_get "$key" "$file" 2>/dev/null || true)"
    if [[ -z "$entry" ]]; then echo "Key not found: $key" >&2; return 1; fi
    local id="${entry%%|*}" desc="${entry#*|}"
    [[ "$id" == "$desc" ]] && desc=""
    local cmd="${tool} resume $id"
    [[ -n "$desc" ]] && echo "$cmd  # $desc" || echo "$cmd"
    local should_exec=0
    if [[ -o interactive ]]; then
        local reply; read -r "reply?Execute command? [Y/n]: "; reply="${reply:-y}"
        [[ "$reply" =~ ^[Yy]$ ]] && should_exec=1
    else
        [[ "${(P)auto_exec_var:-0}" == "1" ]] && should_exec=1
    fi
    if (( should_exec )); then
        [[ ! "$id" =~ ^[A-Za-z0-9._:-]+$ ]] && { echo "Unsafe session id: $id" >&2; return 1; }
        command "$tool" resume "$id"
    fi
}

# =================================================================
# Codex wrappers (thin delegates to generic session manager)
# =================================================================
codex_session_add()    { _agent_session_add    codex "$CODEX_SESSIONS_FILE" "$@"; }
codex_session_update() { _agent_session_update codex "$CODEX_SESSIONS_FILE" "$@"; }
codex_session_remove() { _agent_session_remove codex "$CODEX_SESSIONS_FILE" "$1"; }
codex_session_list()   { _agent_session_list   codex "$CODEX_SESSIONS_FILE"; }
codex_session_edit()   { _agent_session_edit   "$CODEX_SESSIONS_FILE"; }
codex_session()        { _agent_session_resume codex "$CODEX_SESSIONS_FILE" "$@"; }

codex_start_net() {
    command -v codex >/dev/null 2>&1 || { echo "codex not found on PATH" >&2; return 1; }
    codex --sandbox workspace-write -a on-request -c network_access="enabled" "$@"
}
codex_start_danger() {
    command -v codex >/dev/null 2>&1 || { echo "codex not found on PATH" >&2; return 1; }
    codex --dangerously-bypass-approvals-and-sandbox "$@"
}

# =================================================================
# Claude wrappers (thin delegates to generic session manager)
# =================================================================
claude_session_add()    { _agent_session_add    claude "$CLAUDE_SESSIONS_FILE" "$@"; }
claude_session_update() { _agent_session_update claude "$CLAUDE_SESSIONS_FILE" "$@"; }
claude_session_remove() { _agent_session_remove claude "$CLAUDE_SESSIONS_FILE" "$1"; }
claude_session_list()   { _agent_session_list   claude "$CLAUDE_SESSIONS_FILE"; }
claude_session_edit()   { _agent_session_edit   "$CLAUDE_SESSIONS_FILE"; }
claude_session()        { _agent_session_resume claude "$CLAUDE_SESSIONS_FILE" "$@"; }

# =================================================================
# Claude project initialization
# =================================================================

claude_init() {
    local project_name org_name git_root current_date
    local add_to_sessions=false
    local claude_configs_repo="${CLAUDE_CONFIGS_REPO:-https://github.com/siege-analytics/claude-configs.git}"
    local claude_skills_repo="${CLAUDE_SKILLS_REPO:-https://github.com/StrongAI/claude-skills.git}"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project)
                project_name="$2"
                shift 2
                ;;
            --org)
                org_name="$2"
                shift 2
                ;;
            --git-root)
                git_root="$2"
                shift 2
                ;;
            --add-session)
                add_to_sessions=true
                shift
                ;;
            --help)
                cat <<'HELP'
Usage: claude_init [OPTIONS]

Initialize Claude Code configuration in the current directory.

Options:
  --project NAME      Project name (default: auto-detect from directory/git)
  --org NAME          Organization name (default: auto-detect from git remote)
  --git-root PATH     Git root path (default: parent directory)
  --add-session       Add project to claude_session list
  --help              Show this help message

Examples:
  claude_init                           # Auto-detect everything
  claude_init --project myapp --org myorg
  claude_init --add-session             # Also add to session list
HELP
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done

    # Auto-detect project name
    if [[ -z "$project_name" ]]; then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            # Try to get from git remote
            local remote_url
            remote_url="$(git remote get-url origin 2>/dev/null || true)"
            if [[ -n "$remote_url" ]]; then
                # Extract repo name from git@github.com:org/repo.git or https://github.com/org/repo.git
                project_name="${remote_url##*/}"
                project_name="${project_name%.git}"
            fi
        fi
        # Fallback to directory name
        if [[ -z "$project_name" ]]; then
            project_name="${PWD:t}"
        fi
    fi

    # Auto-detect organization name
    if [[ -z "$org_name" ]]; then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local remote_url
            remote_url="$(git remote get-url origin 2>/dev/null || true)"
            if [[ -n "$remote_url" ]]; then
                # Extract org from git@github.com:org/repo.git or https://github.com/org/repo.git
                org_name="${remote_url#*[:/]}"
                org_name="${org_name%%/*}"
            fi
        fi
        # Fallback to project name
        if [[ -z "$org_name" ]]; then
            org_name="$project_name"
        fi
    fi

    # Auto-detect git root
    if [[ -z "$git_root" ]]; then
        git_root="${PWD:h}"
    fi

    # Current date
    current_date="$(date +%Y-%m-%d)"

    echo "Initializing Claude Code configuration..."
    echo "  Project: $project_name"
    echo "  Organization: $org_name"
    echo "  Git root: $git_root"
    echo ""

    # Check if already initialized
    if [[ -d .claude ]]; then
        echo "⚠️  .claude/ directory already exists"
        read -r "reply?Reinitialize? This will preserve existing files but may update skills. [y/N]: "
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return 1
        fi
    fi

    # Create .claude directory
    mkdir -p .claude

    # ── Phase 1: Fetch org configs (templates + org-specific skills) ──
    local tmp_dir configs_ok=false templates_dir=""
    tmp_dir="$(mktemp -d)"

    echo "Fetching org configs from $claude_configs_repo..."
    # Prefer gh (handles private repos via GitHub CLI auth) over plain git
    local _clone_ok=false
    if command -v gh >/dev/null 2>&1; then
        local _repo_slug="${claude_configs_repo#https://github.com/}"
        _repo_slug="${_repo_slug%.git}"
        gh repo clone "$_repo_slug" "$tmp_dir" -- --depth 1 >/dev/null 2>&1 && _clone_ok=true
    fi
    if [[ "$_clone_ok" != true ]]; then
        git clone --depth 1 "$claude_configs_repo" "$tmp_dir" >/dev/null 2>&1 && _clone_ok=true
    fi
    if [[ "$_clone_ok" == true ]]; then
        configs_ok=true
        templates_dir="$tmp_dir/templates"
        if [[ -d "$tmp_dir/skills" ]]; then
            mkdir -p .claude/skills
            cp -r "$tmp_dir/skills/"* .claude/skills/ 2>/dev/null
            echo "✅ Org skills copied to .claude/skills/"
        fi
    else
        echo "⚠️  Org configs repo not available — skipping (this is fine)"
    fi

    # ── Phase 2: Fetch community skills from StrongAI/claude-skills ──
    local skills_tmp
    skills_tmp="$(mktemp -d)"
    echo "Fetching community skills from $claude_skills_repo..."
    if git clone --depth 1 --recursive "$claude_skills_repo" "$skills_tmp" >/dev/null 2>&1; then
        mkdir -p .claude/skills
        # Copy each skill category, preserving existing org skills
        local category
        for category in "$skills_tmp"/skills/*(N/); do
            local cat_name="${category:t}"
            if [[ ! -d ".claude/skills/$cat_name" ]]; then
                cp -r "$category" ".claude/skills/$cat_name"
            else
                # Merge: copy individual skills that don't already exist
                local skill_dir
                for skill_dir in "$category"/*(N/); do
                    local skill_name="${skill_dir:t}"
                    if [[ ! -d ".claude/skills/$cat_name/$skill_name" ]]; then
                        cp -r "$skill_dir" ".claude/skills/$cat_name/$skill_name"
                    fi
                done
            fi
        done
        echo "✅ Community skills merged into .claude/skills/"
        echo "   Source: StrongAI/claude-skills ($(ls -d .claude/skills/*/* 2>/dev/null | wc -l | tr -d ' ') skills)"
    else
        echo "⚠️  Community skills repo not available — skipping"
    fi
    rm -rf "$skills_tmp"

    # Stage skills if in a git repo
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [[ -d .claude/skills ]]; then
        git add .claude/skills 2>/dev/null
        echo ""
        echo "💡 To update skills in the future, re-run: claude_init"
    fi

    # ── Phase 3: Generate CLAUDE.md ──
    if [[ ! -f CLAUDE.md ]] || { echo "CLAUDE.md exists."; read -q "?Overwrite? [y/N]: " }; then
        echo ""
        echo "Generating CLAUDE.md..."
        if [[ "$configs_ok" == true && -f "$templates_dir/CLAUDE.md.template" ]]; then
            local template_content
            template_content="$(<"$templates_dir/CLAUDE.md.template")"
            template_content="${template_content//\{\{PROJECT_NAME\}\}/$project_name}"
            template_content="${template_content//\{\{ORG_NAME\}\}/$org_name}"
            template_content="${template_content//\{\{GIT_ROOT\}\}/$git_root}"
            template_content="${template_content//\{\{CURRENT_DATE\}\}/$current_date}"
            echo "$template_content" > CLAUDE.md
            echo "✅ CLAUDE.md created from org template"
        else
            cat > CLAUDE.md <<EOF
# $project_name

> **SESSION START**: Always read all markdown files in $project_name repositories at session start:
> \`\`\`
> $git_root/$project_name/CLAUDE.md
> $git_root/$project_name/*/CLAUDE.md
> $git_root/$project_name/docs/*.md
> \`\`\`

## Attribution Policy

**NEVER** include AI assistant attribution in commits, PRs, issues, comments, or any public-facing content.

## Project Overview

[Add project description here]

---

*Last updated: $current_date*
EOF
            echo "✅ CLAUDE.md created from fallback template"
        fi
    fi

    # ── Phase 4: Copy settings.local.json ──
    if [[ ! -f .claude/settings.local.json ]] || { echo "settings.local.json exists."; read -q "?Overwrite? [y/N]: " }; then
        echo ""
        if [[ "$configs_ok" == true && -f "$templates_dir/settings.local.json" ]]; then
            cp "$templates_dir/settings.local.json" .claude/settings.local.json
            echo "✅ .claude/settings.local.json created"
        else
            echo "⚠️  Settings template not found (create .claude/settings.local.json manually)" >&2
        fi
    fi

    # Clean up
    rm -rf "$tmp_dir"

    echo ""
    echo "✅ Claude Code initialization complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit CLAUDE.md to add project-specific context"
    echo "  2. Edit .claude/settings.local.json to add necessary permissions"
    echo "  3. Customize skills in .claude/skills/ as needed"
    echo "  4. Start a Claude session: claude"

    # Optionally add to session list
    if [[ "$add_to_sessions" == true ]]; then
        echo ""
        read -r "session_name?Enter session name (e.g., ${project_name}_dev): "
        if [[ -n "$session_name" ]]; then
            read -r "session_desc?Enter session description (optional): "
            local session_value="${PWD}"
            if [[ -n "$session_desc" ]]; then
                session_value="${PWD}|${session_desc}"
            fi
            claude_session_add --name "$session_name" --value "$session_value"
            echo "✅ Added to Claude session list: $session_name"
        fi
    fi
}

# =================================================================
# Codex + Combined project initialization
# =================================================================

_agents_detect_project_name() {
    local remote_url
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        remote_url="$(git remote get-url origin 2>/dev/null || true)"
        if [[ -n "$remote_url" ]]; then
            local p="${remote_url##*/}"
            echo "${p%.git}"
            return 0
        fi
    fi
    echo "${PWD:t}"
}

_agents_detect_org_name() {
    local remote_url
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        remote_url="$(git remote get-url origin 2>/dev/null || true)"
        if [[ -n "$remote_url" ]]; then
            local o="${remote_url#*[:/]}"
            echo "${o%%/*}"
            return 0
        fi
    fi
    echo "$(_agents_detect_project_name)"
}

_agents_detect_git_root() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
        return 0
    fi
    echo "$PWD"
}

_agents_write_codex_agents_md() {
    local out="$1"
    local project_name="$2"
    local org_name="$3"
    local git_root="$4"
    local role="$5"
    local approval="$6"
    local sandbox="$7"
    cat > "$out" <<EOF
# AGENTS.md

## Role
\`$role\`

## Execution Defaults
- Approval mode: \`$approval\`
- Sandbox mode: \`$sandbox\`
- Destructive operations: require explicit confirmation.

## Project Context
- Project: \`$project_name\`
- Organization: \`$org_name\`
- Workspace root: \`$git_root\`

## Working Rules
- Plan first, then execute.
- Prefer targeted edits over broad changes.
- Run tests for changed behavior before presenting results.
- Keep commits focused and reversible.
- No AI attribution in commits, comments, docs, or PRs.
- Never use phrases like "created with", "generated by", or "co-authored-by AI".

## Escalation Rules
- Ask before destructive operations (\`rm -rf\`, reset, force push).
- Ask before changing external infrastructure or production data.
- Ask before introducing long-running background processes.

## Initialization Notes
- Update this file with domain-specific constraints and architecture.
- Keep secrets out of the repository.
EOF
}

_agents_write_codex_settings() {
    local out="$1"
    local role="$2"
    local approval="$3"
    local sandbox="$4"
    cat > "$out" <<EOF
{
  "defaults": {
    "role": "$role",
    "approval_mode": "$approval",
    "sandbox_mode": "$sandbox"
  },
  "rules": {
    "ask_before_destructive": true,
    "no_ai_attribution": true,
    "forbid_created_with_phrasing": true,
    "require_tests_for_behavior_changes": true
  }
}
EOF
}

_agents_merge_codex_agents_md() {
    local file="$1"
    local -a required_rules
    required_rules=(
        "- Plan first, then execute."
        "- Run tests for changed behavior before presenting results."
        "- No AI attribution in commits, comments, docs, or PRs."
        "- Never use phrases like \"created with\", \"generated by\", or \"co-authored-by AI\"."
    )

    local -a missing_rules
    local line
    for line in "${required_rules[@]}"; do
        if ! grep -Fqx -- "$line" "$file" 2>/dev/null; then
            missing_rules+=("$line")
        fi
    done

    [[ ${#missing_rules[@]} -eq 0 ]] && return 0

    {
        echo
        echo "## Codex Managed Rules"
        for line in "${missing_rules[@]}"; do
            echo "$line"
        done
    } >> "$file"
}

_agents_merge_codex_settings() {
    local out="$1"
    local role="$2"
    local approval="$3"
    local sandbox="$4"

    python3 - "$out" "$role" "$approval" "$sandbox" <<'PY'
import json
import os
import sys

path, role, approval, sandbox = sys.argv[1:5]
data = {}

if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}

defaults = data.setdefault("defaults", {})
if not isinstance(defaults, dict):
    defaults = {}
    data["defaults"] = defaults
defaults.setdefault("role", role)
defaults.setdefault("approval_mode", approval)
defaults.setdefault("sandbox_mode", sandbox)

rules = data.setdefault("rules", {})
if not isinstance(rules, dict):
    rules = {}
    data["rules"] = rules
rules["ask_before_destructive"] = True
rules["no_ai_attribution"] = True
rules["forbid_created_with_phrasing"] = True
rules["require_tests_for_behavior_changes"] = True

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=False)
    f.write("\n")
PY
}

codex_init() {
    local project_name=""
    local org_name=""
    local git_root=""
    local role="${CODEX_DEFAULT_ROLE:-Senior pragmatic software engineer}"
    local approval="${CODEX_DEFAULT_APPROVAL:-on-request}"
    local sandbox="${CODEX_DEFAULT_SANDBOX:-workspace-write}"
    local add_to_sessions=false
    local session_name=""
    local session_desc=""
    local update=0
    local yes=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project_name="${2:-}"; shift 2 ;;
            --org) org_name="${2:-}"; shift 2 ;;
            --git-root) git_root="${2:-}"; shift 2 ;;
            --role) role="${2:-}"; shift 2 ;;
            --approval) approval="${2:-}"; shift 2 ;;
            --sandbox) sandbox="${2:-}"; shift 2 ;;
            --add-session) add_to_sessions=true; shift ;;
            --session-name) session_name="${2:-}"; shift 2 ;;
            --session-desc) session_desc="${2:-}"; shift 2 ;;
            --update) update=1; shift ;;
            --yes|-y) yes=1; shift ;;
            --help)
                cat <<'HELP'
Usage: codex_init [OPTIONS]

Initialize Codex-oriented project config in the current directory.

Options:
  --project NAME         Project name (auto-detected if omitted)
  --org NAME             Organization name (auto-detected if omitted)
  --git-root PATH        Workspace root (auto-detected if omitted)
  --role TEXT            Default role/persona
  --approval MODE        Default approval mode (default: on-request)
  --sandbox MODE         Default sandbox mode (default: workspace-write)
  --add-session          Add this project to codex_session list
  --session-name NAME    Session key to use with --add-session
  --session-desc TEXT    Session description with --add-session
  --update               Merge required rules into existing files
  --yes, -y              Overwrite existing files without prompt
HELP
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    [[ -n "$project_name" ]] || project_name="$(_agents_detect_project_name)"
    [[ -n "$org_name" ]] || org_name="$(_agents_detect_org_name)"
    [[ -n "$git_root" ]] || git_root="$(_agents_detect_git_root)"

    mkdir -p .codex

    local agents_file="AGENTS.md"
    local settings_file=".codex/settings.local.json"
    local state_file=".codex/init.env"

    if [[ "$update" -ne 1 && -f "$agents_file" && "$yes" -ne 1 ]]; then
        read -r "reply?AGENTS.md exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi
    if [[ "$update" -ne 1 && -f "$settings_file" && "$yes" -ne 1 ]]; then
        read -r "reply?.codex/settings.local.json exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi

    if [[ "$update" -eq 1 ]]; then
        if [[ -f "$agents_file" ]]; then
            _agents_merge_codex_agents_md "$agents_file"
        else
            _agents_write_codex_agents_md "$agents_file" "$project_name" "$org_name" "$git_root" "$role" "$approval" "$sandbox"
        fi
        _agents_merge_codex_settings "$settings_file" "$role" "$approval" "$sandbox"
    else
        _agents_write_codex_agents_md "$agents_file" "$project_name" "$org_name" "$git_root" "$role" "$approval" "$sandbox"
        _agents_write_codex_settings "$settings_file" "$role" "$approval" "$sandbox"
    fi

    cat > "$state_file" <<EOF
PROJECT_NAME=$project_name
ORG_NAME=$org_name
GIT_ROOT=$git_root
ROLE=$role
APPROVAL=$approval
SANDBOX=$sandbox
EOF

    echo "✅ Codex config initialized"
    echo "   - $agents_file"
    echo "   - $settings_file"
    echo "   - $state_file"

    if [[ "$add_to_sessions" == true ]]; then
        if [[ -z "$session_name" ]]; then
            if [[ -o interactive ]]; then
                read -r "session_name?Enter Codex session name (e.g., ${project_name}_dev): "
            else
                session_name="${project_name}_dev"
            fi
        fi
        if [[ -n "$session_name" && -z "$session_desc" && -o interactive ]]; then
            read -r "session_desc?Enter session description (optional): "
        fi
        if [[ -n "$session_name" ]]; then
            local session_value="${PWD}"
            if [[ -n "$session_desc" ]]; then
                session_value="${PWD}|${session_desc}"
            fi
            if _codex_sessions_get "$session_name" >/dev/null 2>&1; then
                codex_session_update --name "$session_name" --value "$session_value"
                echo "✅ Updated Codex session: $session_name"
            else
                codex_session_add --name "$session_name" --value "$session_value"
                echo "✅ Added Codex session: $session_name"
            fi
        fi
    fi
}

ai_init() {
    local claude_only=0
    local codex_only=0
    local pass=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --claude-only) claude_only=1; shift ;;
            --codex-only) codex_only=1; shift ;;
            *) pass+=("$1"); shift ;;
        esac
    done

    if [[ "$claude_only" -eq 1 && "$codex_only" -eq 1 ]]; then
        echo "Cannot set both --claude-only and --codex-only" >&2
        return 1
    fi

    if [[ "$codex_only" -eq 0 ]]; then
        claude_init "${pass[@]}" || return 1
    fi
    if [[ "$claude_only" -eq 0 ]]; then
        codex_init "${pass[@]}" || return 1
    fi
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ agents loaded"
fi
