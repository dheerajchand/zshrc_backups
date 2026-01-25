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
| `get_python_path` | Resolve Python path | `pyenv` or `python3` | Python installed |
| `get_python_version` | Get Python version | `python` | Python installed |
| `python_status` | Show Python status | `pyenv` | None |
| `python_config_status` | Show configuration | `pyenv`/`python` | None |
| `pyenv_use_version` | `pyenv shell` | `pyenv` | Version exists |
| `pyenv_default_version` | `pyenv global` | `pyenv` | Version exists |
| `with_python` | Run command with Python env | `pyenv` | Env exists |
| `use_uv` | Use `uv` tool | `uv` | Installed |
| `ds_project_init` | Create DS project | `mkdir`, `git` | Writable dir |

## Notes
- `python_status` falls back to system Python if pyenv unavailable.
