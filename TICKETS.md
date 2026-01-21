# Tickets (Closed)

1) Safe Hadoop start with explicit format flag
- Status: closed
- Notes: `start_hadoop --format` required; default non-destructive

2) Guard destructive ops in YARN/HDFS helpers
- Status: closed
- Notes: `yarn_kill_all_apps --force`, `hdfs_rm --force`

3) Spark dependency versions from variables/detection
- Status: closed
- Notes: uses `SPARK_VERSION` + `SPARK_SCALA_VERSION` or auto-detects

4) Non-destructive spark-env handling
- Status: closed
- Notes: writes `spark-env-zsh.sh` and sources from `spark-env.sh`
