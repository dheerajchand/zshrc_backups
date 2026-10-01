# Module: Python

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Python/pyenv management and data‑science helpers.

## Environment
- `PYENV_ROOT`, `PYTHONPATH`
- `DEFAULT_PYENV_VENV`

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `py_env_switch` | Switch pyenv env | `pyenv` | Env exists |
| `get_python_path` | Resolve selected interpreter via `sys.executable` | `python` or `python3` | Python installed |
| `get_python_version` | Get Python version | `python` | Python installed |
| `python_status` | Show selected interpreter and manager | `python` or `python3` | None |
| `python_config_status` | Show configuration | `pyenv`/`python` | None |
| `py_env_switch --default` | Set default venv | `pyenv` | Env exists |
| `pyenv_use_version` | `pyenv shell` | `pyenv` | Version exists |
| `pyenv_default_version` | `pyenv global` | `pyenv` | Version exists |
| `with_python` | Run command with selected Python | `python` or `python3` | Python installed |
| `use_uv` | Use `uv` tool | `uv` | Installed |
| `ds_project_init` | Create DS project | `mkdir`, `git` | Writable dir |

## Notes
- Status follows the selected interpreter, even when pyenv is installed.
- See [Runtime Managers](Runtime-Managers) for mise integration, inherited environments, and pyenv auto-init/activation controls.
- Startup uses `pyenv init ... --no-rehash` to avoid 60-second stalls from pyenv shim lock contention.
