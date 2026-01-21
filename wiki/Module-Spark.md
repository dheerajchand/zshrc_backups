# Module: Spark

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Local Spark cluster management, job submission, dependency resolution, and jar matrix helpers.

## Environment
- `SPARK_HOME`, `SPARK_MASTER_HOST`, `SPARK_MASTER_PORT`
- `SPARK_VERSION`, `SPARK_SCALA_VERSION`
- `SPARK_SEDONA_ENABLE`, `SPARK_SEDONA_VERSION`, `SPARK_GEOTOOLS_VERSION`
- `SPARK_KAFKA_ENABLE`, `SPARK_KAFKA_VERSION`
- `SPARK_JARS_COORDS` (extra Maven coords, comma-separated)
- `SPARK_JARS_AUTO_DOWNLOAD` (default `1`)
- `JARS_DIR` (shared jar root)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_spark_detect_versions` | Detect Spark/Scala versions | `spark-submit` | Spark installed and in PATH |
| `jar_matrix_resolve` | Resolve jar coordinates | `_spark_detect_versions` | Env vars set or detectable |
| `jar_matrix_status` | Explain jar resolution | `jar_matrix_resolve` | None |
| `spark_start` | Start master + worker | `jps`, `start-master.sh`, `start-worker.sh` | Local single-node cluster |
| `spark_stop` | Stop master + worker | `stop-master.sh`, `stop-worker.sh` | Local cluster |
| `spark_status` | Basic status | `pgrep`, `spark-submit` | Local processes |
| `spark_health` | Health + version | `pgrep`, `spark-submit` | Local processes |
| `get_spark_dependencies` | Resolve `--jars`/`--packages` | `is_online`, `download_jars` | JARS_DIR writable |
| `smart_spark_submit` | Auto-submit job | `spark-submit` | File exists |
| `pyspark_shell` | PySpark shell | `pyspark` | Spark installed |
| `spark_history_server` | Start history server | `start-history-server.sh` | `SPARK_HOME` valid |
| `spark_install_from_tar` | Install Spark via SDKMAN layout | `tar`, `sdk` | SDKMAN installed |
| `spark_yarn_submit` | Submit to YARN | `yarn`, `spark-submit` | YARN running |
| `spark_shell` | Scala Spark shell | `spark-shell` | Spark installed |
| `spark_restart` | Restart cluster | `spark_stop`, `spark_start` | Local cluster |

## Notes
- `spark_start` writes `spark-env-zsh.sh` and sources it from `spark-env.sh` to avoid clobbering user settings.
- Sedona coordinates are resolved for Spark 4.x as `sedona-spark-shaded-4.0_2.13` (per Sedona docs).
