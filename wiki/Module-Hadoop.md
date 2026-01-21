# Module: Hadoop & YARN

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
HDFS/YARN start/stop/status, health checks, and HDFS helpers.

## Environment
- `HADOOP_HOME`, `HADOOP_CONF_DIR`, `YARN_CONF_DIR`
- `HDFS_NAMENODE_USER`, `HDFS_DATANODE_USER`
- `YARN_RESOURCEMANAGER_USER`, `YARN_NODEMANAGER_USER`

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `start_hadoop` | Start HDFS + YARN | `hdfs`, `yarn`, `jps` | Local single-node cluster |
| `stop_hadoop` | Stop HDFS + YARN | `hdfs`, `yarn` | Local cluster |
| `restart_hadoop` | Restart services | `stop_hadoop`, `start_hadoop` | Local cluster |
| `hadoop_status` | Status summary | `jps`, `hadoop`, `yarn` | Local processes |
| `yarn_health` | YARN health | `pgrep`, `yarn` | Local processes |
| `hadoop_health` | HDFS + YARN health | `pgrep`, `hadoop` | Local processes |
| `yarn_application_list` | List YARN apps | `yarn` | RM running |
| `yarn_kill_all_apps` | Kill all apps | `yarn` | Requires `--force` |
| `yarn_logs` | App logs | `yarn` | App ID provided |
| `yarn_cluster_info` | Node list | `yarn` | RM running |
| `hdfs_ls` | List HDFS paths | `hdfs` | HDFS running |
| `hdfs_put` | Upload to HDFS | `hdfs` | Local file exists |
| `hdfs_get` | Download from HDFS | `hdfs` | HDFS path exists |
| `hdfs_rm` | Remove from HDFS | `hdfs` | Requires `--force` |

## Notes
- `start_hadoop` requires `--format` if NameNode is not formatted.
- Destructive operations are non-interactive and require `--force`.
