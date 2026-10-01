# Runtime Managers

Back: [Home](Home)

Keep Homebrew for general tools, pyenv for existing Python work, and SDKMAN for
existing JVM/data-platform work. A project's committed `mise.toml` owns the
versions and tasks declared by that project. Avoid setting global mise runtime
versions or enabling discovery of `.python-version`/`.sdkmanrc` files during
initial adoption.

## Environment inheritance

The repository's `zshenv` adds missing fallback paths without replacing or
reordering inherited paths. It sets SDKMAN's current Java as a fallback only
when `JAVA_HOME` is unset or empty. `zshrc` uses the same defaults, including its
non-TTY fast path. SDKMAN, Spark, Hadoop, and Rancher paths are fallback entries;
an inherited project executable stays ahead of them.

New installations link `~/.zshenv` to this file when no `.zshenv` exists.
Existing `.zshenv` files are preserved by the installer. To migrate one:

1. Back up `~/.zshenv`.
2. Replace unconditional `PATH=...` resets and hardcoded `JAVA_HOME` assignments
   with `source "$HOME/.config/zsh/zshenv"` (adjust for a custom installation).
3. Keep unrelated personal exports. Additional path entries should be appended
   only when absent, rather than resetting the inherited path.

Do not merely append this source line after a destructive PATH reset: the
inherited environment has already been lost at that point. Check `.zprofile`
and any other startup scripts for similar resets.

## Start with explicit project commands

From a cloned project, review its `mise.toml`, follow the team's trust/setup
instructions, then run:

```zsh
mise install
mise tasks ls
# Execute a task listed above: mise run TASK
# Execute a project command: mise exec -- COMMAND [ARG ...]
```

These commands require no mise shell activation. They configure the child
process; they do not change your current shell. They are not isolation from
all inherited variables. If the project manages Python, deactivate a personal
virtualenv first (`pyenv deactivate` for pyenv, `deactivate` for a regular venv).
Use the project's own dependency manager and virtualenv configuration.

For child interactive shells launched from a mise environment or an active
virtualenv, Python initialization is skipped to preserve that environment.
Python helpers remain available. Use `setup_pyenv` explicitly if you later
want to initialize pyenv in such a shell.

## Optional interactive mise shell

Set `ZSH_MISE_ACTIVATE=1` before starting an interactive shell, or in the
appropriate settings file. It suppresses automatic pyenv initialization and
loads `mise activate zsh` after startup path and directory setup:

```zsh
# Deactivate an existing personal virtualenv first, if one is active.
ZSH_MISE_ACTIVATE=1 ZSH_AUTO_RECOVER_MODE=off zsh
# cd to the project, then use its commands normally.
# exit returns to the parent shell and its runtime settings.
```

Mise activation is off by default. It reports an error if mise is missing or
an unrelated virtualenv is still active. It does not install mise or change
its global configuration. Avoid `pyenv activate` / `sdk use` for a runtime
owned by mise in this shell. SDKMAN helpers remain available for other work.
Use a new shell when changing activation flags; they do not unload hooks
already installed in the current process. `ZSH_DISABLE_MISE=1` disables the
module through the standard module loader.

Automatic switching is provided by mise's own directory and prompt hooks.
Configuration discovery follows mise's normal project/ancestor/global rules;
this flag does not restrict mise to a particular client directory.

## Python controls and diagnostics

- `ZSH_PYENV_AUTO_INIT=0`: skip all automatic pyenv initialization while keeping
  Python helper functions.
- `ZSH_PYENV_AUTO_ACTIVATE=0`: initialize pyenv's shell commands, but skip the
  virtualenv prompt hook and default environment activation.
- Both default to `1` for ordinary shells without an inherited mise/venv
  environment. An active mise environment, inherited virtualenv, or
  `ZSH_MISE_ACTIVATE=1` takes precedence over these defaults.

`get_python_path`, `python_status`, `python_config_status`, and `with_python`
follow the interpreter selected by PATH. Installing pyenv does not make it the
owner of every Python invocation. The `virtualenv` label identifies a selected
venv; it does not claim whether uv, mise, or another tool created it.

Useful checks inside the project:

```zsh
mise config
mise ls --current
command -v python
python -c 'import sys; print(sys.executable)'
python_status
print -r -- "$JAVA_HOME"
zsh -c 'command -v python; print -r -- "$JAVA_HOME"'
```

Only check runtimes used by the project. IDEs should use the project's selected
interpreter/SDK or a `mise exec` command; a GUI environment probe intentionally
skips full interactive initialization.

## Startup directory

Shells preserve their inherited working directory by default. To request the
old startup-directory behavior, set both:

```zsh
export ZSH_STARTUP_CD=1
export STARTUP_DIR="$HOME/Desktop"
```

Mac settings respect an existing `STARTUP_DIR`. For Storeminder, the current
Mac profile defines `$PROFESSIONAL` as `~/Documents/Professional`; the project
could live at `$PROFESSIONAL/Storeminder`. No directory or project tool versions
are created by this configuration change.

## References

- [mise execution](https://mise.jdx.dev/cli/exec.html)
- [mise activation](https://mise.jdx.dev/cli/activate.html)
- [mise Python environments](https://mise.jdx.dev/lang/python.html)
