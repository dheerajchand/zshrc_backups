# Module: Spark

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Local Spark cluster management, job submission, dependency resolution, and jar matrix helpers.

## Environment
- `SPARK_HOME`, `SPARK_MASTER_HOST`, `SPARK_MASTER_PORT`
- `SPARK_VERSION`, `SPARK_SCALA_VERSION`
- `HADOOP_VERSION` (optional override for Hadoop detection)
- `SPARK_SEDONA_ENABLE`, `SPARK_SEDONA_VERSION`, `SPARK_GEOTOOLS_VERSION`
- `SPARK_KAFKA_ENABLE`, `SPARK_KAFKA_VERSION`
- `SPARK_JARS_COORDS` (extra Maven coords, comma-separated)
- `SPARK_JARS_AUTO_DOWNLOAD` (default `1`)
- `JARS_DIR` (shared jar root)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_spark_detect_versions` | Detect Spark/Scala versions | `spark-submit` | Spark installed and in PATH |
| `_spark_detect_scala_version` | Detect Scala version | `scala` | Scala installed |
| `_spark_detect_hadoop_version` | Detect Hadoop version | `hadoop` | Hadoop installed |
| `_spark_default_scala_for_spark` | Default Scala for Spark major | None | Spark version known |
| `jar_matrix_resolve` | Resolve jar coordinates | `_spark_detect_versions` | Env vars set or detectable |
| `jar_matrix_status` | Explain jar resolution | `jar_matrix_resolve` | None |
| `spark_config_status` | Show configuration | `_spark_detect_versions` | None |
| `spark_validate_versions` | Validate Spark/Scala/Hadoop | `hadoop`, `scala` | Versions detectable |
| `spark_versions` | List SDKMAN versions | `sdk` | SDKMAN installed |
| `spark_use_version` | Use SDKMAN Spark | `sdk` | Version installed |
| `spark_default_version` | Set default Spark | `sdk` | Version installed |
| `scala_versions` | List SDKMAN Scala | `sdk` | SDKMAN installed |
| `scala_use_version` | Use SDKMAN Scala | `sdk` | Version installed |
| `scala_default_version` | Set default Scala | `sdk` | Version installed |
| `java_versions` | List SDKMAN Java | `sdk` | SDKMAN installed |
| `java_use_version` | Use SDKMAN Java | `sdk` | Version installed |
| `java_default_version` | Set default Java | `sdk` | Version installed |
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
- Default Scala selection:
  - Spark 2.0–2.3 → Scala 2.11
  - Spark 2.4 → Scala 2.12
  - Spark 3.x → Scala 2.12
  - Spark 4.x → Scala 2.13
- Local jars are searched in:
  - `${JARS_DIR}/spark/<spark_version>/scala-<scala_binary>`
  - `${JARS_DIR}/spark/<spark_version>/hadoop-<hadoop_major>`
  - `${JARS_DIR}/spark/<spark_version>`
