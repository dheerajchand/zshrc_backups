# Module: System Diagnostics

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
macOS iCloud/Dropbox helpers, Linux system summary, and data platform health.

## Environment
- `ZSH_TEST_MODE` (suppresses side effects)
- `OSTYPE` (OS detection)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_run_with_timeout` | Run a command with timeout | `timeout`/`gtimeout`/`perl` | Timeout tool available or best-effort |
| `_is_macos` | macOS check | `OSTYPE` | None |
| `data_platform_health` | Spark/Hadoop/YARN health | `spark_health`, `hadoop_health` | Modules loaded |
| `icloud_status` | iCloud status | `brctl`, `fileproviderctl` | macOS only |
| `icloud_logs` | Recent CloudDocs logs | `log` | macOS only |
| `icloud_snapshot` | Write snapshot file | `icloud_status` | macOS only |
| `icloud_preflight` | Detect active sync | `brctl` | macOS only |
| `icloud_reset_state` | Reset CloudDocs/FileProvider state | `killall` | Interactive shell |
| `dropbox_status` | Dropbox health summary | `ls`, `cat` | macOS only |
| `dropbox_restart` | Restart Dropbox app | `open` | macOS only |
| `dropbox_relink_helper` | Assist relink flow | `open`, `Finder` | macOS only |
| `linux_system_status` | Linux summary | `uname`, `df`, `free`/`vmstat`, `systemctl` | Linux only |
| `data_platform_config_status` | Spark/Hadoop/Python config | module functions | Modules loaded |

## Notes
- `icloud_reset_state` is destructive; it moves state to `.bak.<timestamp>`.
- `data_platform_health` delegates to Spark/Hadoop/YARN modules.
