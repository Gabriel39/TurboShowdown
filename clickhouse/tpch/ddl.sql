CREATE OR REPLACE TABLE nation (
    n_nationkey  Int32,
    n_name       String,
    n_regionkey  Int32,
    n_comment    String)
ORDER BY (n_nationkey);

CREATE OR REPLACE TABLE region (
    r_regionkey  Int32,
    r_name       String,
    r_comment    String)
ORDER BY (r_regionkey);

CREATE OR REPLACE TABLE part (
      p_partkey     Int32,
      p_name        String,
      p_mfgr        String,
      p_brand       String,
      p_type        String,
      p_size        Int32,
      p_container   String,
      p_retailprice Decimal(15,2),
      p_comment     String)
ORDER BY (p_partkey);

CREATE OR REPLACE TABLE supplier (
      s_suppkey     Int32,
      s_name        String,
      s_address     String,
      s_nationkey   Int32,
      s_phone       String,
      s_acctbal     Decimal(15,2),
      s_comment     String)
ORDER BY (s_suppkey);

CREATE OR REPLACE TABLE partsupp (
      ps_partkey     Int32,
      ps_suppkey     Int32,
      ps_availqty    Int32,
      ps_supplycost  Decimal(15,2),
      ps_comment     String)
ORDER BY (ps_partkey, ps_suppkey);

CREATE OR REPLACE TABLE customer (
      c_custkey     Int32,
      c_name        String,
      c_address     String,
      c_nationkey   Int32,
      c_phone       String,
      c_acctbal     Decimal(15,2),
      c_mktsegment  String,
      c_comment     String)
ORDER BY (c_custkey);

CREATE OR REPLACE TABLE orders  (
     o_orderkey       Int32,
     o_custkey        Int32,
     o_orderstatus    String,
     o_totalprice     Decimal(15,2),
     o_orderdate      Date,
     o_orderpriority  String,
     o_clerk          String,
     o_shippriority   Int32,
     o_comment        String)
ORDER BY (o_orderkey);

CREATE OR REPLACE TABLE lineitem (
      l_orderkey       Int32,
      l_partkey        Int32,
      l_suppkey        Int32,
      l_linenumber     Int32,
      l_quantity       Decimal(15,2),
      l_extendedprice  Decimal(15,2),
      l_discount       Decimal(15,2),
      l_tax            Decimal(15,2),
      l_returnflag     String,
      l_linestatus     String,
      l_shipdate       Date,
      l_commitdate     Date,
      l_receiptdate    Date,
      l_shipinstruct   String,
      l_shipmode       String,
      l_comment        String)
ORDER BY (l_orderkey, l_linenumber);

INSERT INTO nation SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/nation/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO region SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/region/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO part SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/part/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO supplier SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/supplier/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO partsupp SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/partsupp/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO customer SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/customer/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO orders SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/orders/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;
INSERT INTO lineitem SELECT * FROM s3('s3://redshift-downloads/TPC-H/2.18/100GB/lineitem/*', NOSIGN, CSV) SETTINGS format_csv_delimiter = '|', input_format_defaults_for_omitted_fields = 1, input_format_csv_empty_as_default = 1;

CREATE OR REPLACE  VIEW revenue0 (supplier_no, total_revenue) AS
SELECT
    l_suppkey,
    sum(l_extendedprice * (1 - l_discount))
FROM
    lineitem
WHERE
        l_shipdate >= DATE '1996-01-01'
  AND l_shipdate < DATE '1996-01-01' + INTERVAL '3' MONTH
GROUP BY
    l_suppkey;