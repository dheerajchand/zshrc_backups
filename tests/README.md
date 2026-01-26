# Tests

Minimal zsh test framework and test suites for this repo.

## Suites

- `test-credentials.zsh`
- `test-secrets.zsh`
- `test-python.zsh`
- `test-spark-hadoop.zsh`
- `test-system-diagnostics.zsh`
- `test-agents.zsh`
- `test-utils.zsh`
- `test-backup.zsh`
- `test-database.zsh`
- `test-docker.zsh`
- `test-screen.zsh`

## Run tests

```bash
zsh run-tests.zsh
```

## Options

```bash
zsh run-tests.zsh --list
zsh run-tests.zsh --test test_get_credential_env
zsh run-tests.zsh --verbose
```
