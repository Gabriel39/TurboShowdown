import argparse
import subprocess
import sys
import os
import re
import multiprocessing
import configparser
import matplotlib.pyplot as plt
import numpy as np


def read_properties(file_path):
    """
    Load property file
    Return a map which contains key-values pairs loaded from file.
    """
    config = configparser.ConfigParser()
    config.read(file_path, encoding='utf-8')
    properties = {}
    for section in config.sections():
        for key, value in config.items(section):
            properties[key.upper()] = value
    return properties


def extract_exec_time(output, target):
    """Extract execution time from the snowsql output."""
    if target == 'apache-doris':
        hour_match = re.search(r'(\d+)\s*hour', output.stdout)
        min_match = re.search(r'(\d+)\s*min', output.stdout)
        sec_match = re.search(r'(\d+\.\d+)\s*sec', output.stdout)
        total_seconds = 0.0
        if hour_match:
            total_seconds += int(hour_match.group(1)) * 3600
        if min_match:
            total_seconds += int(min_match.group(1)) * 60
        if sec_match:
            total_seconds += float(sec_match.group(1))
        return total_seconds
    elif target == 'snowflake':
        match = re.search(r"Time Elapsed:\s*([0-9.]+)s", output.stdout)
        return match.group(1).strip('s') if match else None
    elif target == 'clickhouse':
        return output.stderr.strip()
    return None


def get_result_file(target, benchmark, suffix):
    result_dir = f"{target}/{benchmark}/result"
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    return f"{result_dir}/result_{target}_{benchmark}_{suffix}.csv"


def execute_sql_file(props, target, benchmark, type, thread, queue):
    sql_file = '%s/%s/%s.sql' % (target, benchmark, type)
    with open(sql_file, "r") as file:
        queries = [query.strip() for query in file.read().split(";\n") if query.strip()]
    result_file_path = get_result_file(target, benchmark, f"{type}_thread{thread}")

    sql_time_list = []
    with open(result_file_path, "w") as result_file:
        for index, sql in enumerate(queries):
            try:
                output = execute_sql(target, props, sql)
                time_elapsed = extract_exec_time(output, target)
                print(
                    f"Thread {thread} executing SQL: {index}-th SQL in file {result_file_path}\n\t"
                    f"Time Elapsed: {time_elapsed}s, \n")
                result_file.write(f"SQL{index}, {time_elapsed}s\n")
                sql_time_list.append(float(time_elapsed))
            except Exception as e:
                print(e)
                result_file.write(f"SQL{index} Error: {e}\n\n")
                sql_time_list.append(-1.0)
    if queue:
        queue.put(sql_time_list)


def execute_sql(target, props, sql, default_db=False):
    if target == 'apache-doris':
        return execute_doris_sql(props, sql, default_db)
    elif target == 'snowflake':
        return execute_snowflake_sql(props, sql)
    elif target == 'clickhouse':
        return execute_clickhouse_sql(props, sql, default_db)
    return None


def execute_snowflake_sql(props, sql):
    command = [
        "snowsql",
        "--warehouse",
        props.get('WAREHOUSE'),
        "--schemaname",
        "PUBLIC",
        "--dbname",
        props.get('DB'),
        "-q",
        sql,
    ]

    try:
        result = subprocess.run(command, text=True, capture_output=True, check=True)
        return result
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"snowsql command failed: {e.stderr}")


def execute_doris_sql(props, sql, default_db=False):
    command = ["mysql", "-h%s" % props.get('FE_HOST'), "-P%s" % props.get('FE_QUERY_PORT'), "-u%s" % props.get('USER'),
               "-e", sql, "-vvv"]
    if not props.get('PASSWORD').strip() == '':
        command.append("-p%s" % props.get('PASSWORD'))
    if not default_db:
        command.append("-D%s" % props.get('DB'))

    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"Error occurs: {result}"
        )
    return result


def execute_clickhouse_sql(props, sql, default_db=False):
    command = ["clickhouse", "client", "--host", props.get('HOST'), "--user",
               props.get('USER'),
               "--query", sql, "--time"]
    if not props.get('PORT').strip() == '':
        command.append("--port")
        command.append(props.get('PORT'))
    if not props.get('PASSWORD').strip() == '':
        command.append("--password")
        command.append(props.get('PASSWORD'))
    if not default_db:
        command.append("--database")
        command.append(props.get('DB'))

    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"Error occurs: {result}"
        )
    return result


def execute_ddl(target, props):
    """Set up the database by dropping and creating it."""
    drop_query = f"DROP DATABASE IF EXISTS {props.get('DB')}"
    create_query = f"CREATE DATABASE {props.get('DB')}"
    execute_sql(target, props, drop_query, True)
    execute_sql(target, props, create_query, True)
    print(f"Database '{props.get('DB')}' has been set up.")


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Run benchmark on any DBMS."
    )
    parser.add_argument(
        "--load", action="store_true", help="Only loading data"
    )
    parser.add_argument(
        "--run", action="store_true", help="Only run queries"
    )
    parser.add_argument(
        "--target", required=True, nargs='+', help="Run which DBMS", choices=['apache-doris', 'snowflake', 'clickhouse']
    )
    parser.add_argument(
        "--benchmark", required=True, help="Run which benchmark", choices=['clickbench', 'ssb', 'tpch', 'ssb-flat']
    )
    parser.add_argument(
        "--parallelism", default=1, type=int, help="parallelism"
    )
    parser.add_argument(
        "--draw", action="store_true", help="Draw"
    )
    return parser.parse_args()


def main():
    args = parse_arguments()
    sql_time_avg = {}
    categories = []
    for target in args.target:
        conf_file = f'properties/{target}.properties'
        if not os.path.exists(conf_file):
            print("Configuration file not found: %s." % conf_file)
            sys.exit(1)
        prop = read_properties(conf_file)
        if not os.path.exists('%s/%s' % (target, args.benchmark)):
            print("Path not found: %s/%s." % (target, args.benchmark))
            sys.exit(1)
        if args.load:
            execute_ddl(target, prop)
            execute_sql_file(prop, target, args.benchmark, 'ddl', 0, None)
        if args.run:
            processes = []
            queue = multiprocessing.Queue()
            for i in range(args.parallelism):
                p = multiprocessing.Process(target=execute_sql_file,
                                            args=(prop, target, args.benchmark, 'queries', i, queue))
                processes.append(p)
                p.start()
            for p in processes:
                p.join()
            sql_time_avg[target] = []
            sql_time_summary = []
            categories = []
            details = []
            sql_time_list = queue.get()
            for t_list in sql_time_list:
                details.append([])
            sql_idx = 0
            for t in sql_time_list:
                if t > 0.0:
                    details[sql_idx].append(t)
                sql_idx += 1
            while not queue.empty():
                sql_time_list = queue.get()
                sql_idx = 0
                for t in sql_time_list:
                    if t > 0.0:
                        details[sql_idx].append(t)
                    sql_idx += 1
            for i in range(len(details)):
                if len(details[i]) > 0:
                    sql_time_avg[target].append(sum(details[i]) / len(details[i]))
                    sql_time_summary.append([min(details[i]), max(details[i]), sum(details[i]) / len(details[i])])
                else:
                    sql_time_avg[target].append(-1.0)
                    sql_time_summary.append([-1.0, -1.0, -1.0])
                categories.append(f'SQL_{i}')
            result_file_path = get_result_file(target, args.benchmark, "summary")
            with open(result_file_path, "w") as result_file:
                idx = 0
                for items in sql_time_summary:
                    result_file.write(f"SQL{idx}, {items[0]}, {items[1]}, {items[2]}\n")  # min.max.avg
                    idx += 1
    if args.draw:
        plt.figure(figsize=(12, 6))
        width = 0.35
        x = np.arange(len(categories))
        num_targets = len(args.target)
        idx = 0
        for k, v in sql_time_avg.items():
            rects = plt.bar(x - width / 2 + width / num_targets * idx, v, width, label=k)
            plt.bar_label(rects, padding=3)
            idx += 1

        plt.title(f'{args.benchmark} Comparison ({"|".join(args.target)})', fontsize=16)
        plt.xlabel('SQL', fontsize=12)
        plt.ylabel('Average Time(Seconds)', fontsize=12)
        plt.xticks(x, categories)
        plt.legend()
        plt.tight_layout()
        plt.savefig('result.svg')


if __name__ == "__main__":
    main()
