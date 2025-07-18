# Turbo Showdown [WIP]

Run benchmark on any DBMS.

```shell
usage: benchmark.py [-h] [--load] [--run] --target {apache-doris,snowflake,clickhouse} [{apache-doris,snowflake,clickhouse} ...] --benchmark {clickbench,ssb,tpch,ssb-flat} [--parallelism PARALLELISM] [--draw]

Run benchmark on any DBMS.

optional arguments:
  -h, --help            show this help message and exit
  --load                Only loading data
  --run                 Only run queries
  --target {apache-doris,snowflake,clickhouse} [{apache-doris,snowflake,clickhouse} ...]
                        Run which DBMS
  --benchmark {clickbench,ssb,tpch,ssb-flat}
                        Run which benchmark
  --parallelism PARALLELISM
                        parallelism
  --draw                Draw


```