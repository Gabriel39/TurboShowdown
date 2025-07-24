drop table if exists lineorder;
CREATE TABLE IF NOT EXISTS `lineorder` (
  `lo_orderkey` int(11) NOT NULL COMMENT "",
  `lo_linenumber` int(11) NOT NULL COMMENT "",
  `lo_custkey` int(11) NOT NULL COMMENT "",
  `lo_partkey` int(11) NOT NULL COMMENT "",
  `lo_suppkey` int(11) NOT NULL COMMENT "",
  `lo_orderdate` int(11) NOT NULL COMMENT "",
  `lo_orderpriority` varchar(16) NOT NULL COMMENT "",
  `lo_shippriority` int(11) NOT NULL COMMENT "",
  `lo_quantity` int(11) NOT NULL COMMENT "",
  `lo_extendedprice` int(11) NOT NULL COMMENT "",
  `lo_ordtotalprice` int(11) NOT NULL COMMENT "",
  `lo_discount` int(11) NOT NULL COMMENT "",
  `lo_revenue` int(11) NOT NULL COMMENT "",
  `lo_supplycost` int(11) NOT NULL COMMENT "",
  `lo_tax` int(11) NOT NULL COMMENT "",
  `lo_commitdate` int(11) NOT NULL COMMENT "",
  `lo_shipmode` varchar(11) NOT NULL COMMENT ""
) ENGINE=OLAP
DUPLICATE KEY(`lo_orderkey`)
COMMENT "OLAP"
PARTITION BY RANGE(`lo_orderdate`)
(
PARTITION p1 VALUES [("-2147483648"), ("19930101")),
PARTITION p2 VALUES [("19930101"), ("19940101")),
PARTITION p3 VALUES [("19940101"), ("19950101")),
PARTITION p4 VALUES [("19950101"), ("19960101")),
PARTITION p5 VALUES [("19960101"), ("19970101")),
PARTITION p6 VALUES [("19970101"), ("19980101")),
PARTITION p7 VALUES [("19980101"), ("19990101"))
)
DISTRIBUTED BY HASH(`lo_orderkey`) BUCKETS 48
PROPERTIES (
  "replication_num" = "1",
  "colocate_with" = "groupa1"
);

drop table if exists customer;
CREATE TABLE IF NOT EXISTS `customer` (
  `c_custkey` int(11) NOT NULL COMMENT "",
  `c_name` varchar(26) NOT NULL COMMENT "",
  `c_address` varchar(41) NOT NULL COMMENT "",
  `c_city` varchar(11) NOT NULL COMMENT "",
  `c_nation` varchar(16) NOT NULL COMMENT "",
  `c_region` varchar(13) NOT NULL COMMENT "",
  `c_phone` varchar(16) NOT NULL COMMENT "",
  `c_mktsegment` varchar(11) NOT NULL COMMENT ""
) ENGINE=OLAP
DUPLICATE KEY(`c_custkey`)
COMMENT "OLAP"
DISTRIBUTED BY HASH(`c_custkey`) BUCKETS 12
PROPERTIES (
  "replication_num" = "1",
  "colocate_with" = "groupa2"
);

drop table if exists dates;
CREATE TABLE IF NOT EXISTS `dates` (
  `d_datekey` int(11) NOT NULL COMMENT "",
  `d_date` varchar(20) NOT NULL COMMENT "",
  `d_dayofweek` varchar(10) NOT NULL COMMENT "",
  `d_month` varchar(11) NOT NULL COMMENT "",
  `d_year` int(11) NOT NULL COMMENT "",
  `d_yearmonthnum` int(11) NOT NULL COMMENT "",
  `d_yearmonth` varchar(9) NOT NULL COMMENT "",
  `d_daynuminweek` int(11) NOT NULL COMMENT "",
  `d_daynuminmonth` int(11) NOT NULL COMMENT "",
  `d_daynuminyear` int(11) NOT NULL COMMENT "",
  `d_monthnuminyear` int(11) NOT NULL COMMENT "",
  `d_weeknuminyear` int(11) NOT NULL COMMENT "",
  `d_sellingseason` varchar(14) NOT NULL COMMENT "",
  `d_lastdayinweekfl` int(11) NOT NULL COMMENT "",
  `d_lastdayinmonthfl` int(11) NOT NULL COMMENT "",
  `d_holidayfl` int(11) NOT NULL COMMENT "",
  `d_weekdayfl` int(11) NOT NULL COMMENT ""
) ENGINE=OLAP
DUPLICATE KEY(`d_datekey`)
COMMENT "OLAP"
DISTRIBUTED BY HASH(`d_datekey`) BUCKETS 1
PROPERTIES (
  "replication_num" = "1",
  "colocate_with" = "groupa3"
);

drop table if exists supplier;
CREATE TABLE IF NOT EXISTS `supplier` (
  `s_suppkey` int(11) NOT NULL COMMENT "",
  `s_name` varchar(26) NOT NULL COMMENT "",
  `s_address` varchar(26) NOT NULL COMMENT "",
  `s_city` varchar(11) NOT NULL COMMENT "",
  `s_nation` varchar(16) NOT NULL COMMENT "",
  `s_region` varchar(13) NOT NULL COMMENT "",
  `s_phone` varchar(16) NOT NULL COMMENT ""
) ENGINE=OLAP
DUPLICATE KEY(`s_suppkey`)
COMMENT "OLAP"
DISTRIBUTED BY HASH(`s_suppkey`) BUCKETS 12
PROPERTIES (
  "replication_num" = "1",
  "colocate_with" = "groupa4"
);

drop table if exists part;
CREATE TABLE IF NOT EXISTS `part` (
  `p_partkey` int(11) NOT NULL COMMENT "",
  `p_name` varchar(23) NOT NULL COMMENT "",
  `p_mfgr` varchar(7) NOT NULL COMMENT "",
  `p_category` varchar(8) NOT NULL COMMENT "",
  `p_brand` varchar(10) NOT NULL COMMENT "",
  `p_color` varchar(12) NOT NULL COMMENT "",
  `p_type` varchar(26) NOT NULL COMMENT "",
  `p_size` int(11) NOT NULL COMMENT "",
  `p_container` varchar(11) NOT NULL COMMENT ""
) ENGINE=OLAP
DUPLICATE KEY(`p_partkey`)
COMMENT "OLAP"
DISTRIBUTED BY HASH(`p_partkey`) BUCKETS 12
PROPERTIES (
  "replication_num" = "1",
  "colocate_with" = "groupa5"
);

INSERT INTO lineorder (
    lo_orderkey,lo_linenumber,lo_custkey,lo_partkey,lo_suppkey,lo_orderdate,lo_orderpriority,lo_shippriority,lo_quantity,lo_extendedprice,lo_ordtotalprice,lo_discount,lo_revenue,lo_supplycost,lo_tax,lo_commitdate,lo_shipmode
) SELECT * FROM S3 (
        "uri" = "s3://bench-dataset/ssb/sf100/lineorder/*",
        "format" = "csv",
        "s3.endpoint" = "https://s3.us-east-1.amazonaws.com",
        "column_separator" = "|",
        csv_schema = "lo_orderkey:int;lo_linenumber:int;lo_custkey:int;lo_partkey:int;lo_suppkey:int;lo_orderdate:int;lo_orderpriority:string;lo_shippriority:int;lo_quantity:int;lo_extendedprice:int;lo_ordtotalprice:int;lo_discount:int;lo_revenue:int;lo_supplycost:int;lo_tax:int;lo_commitdate:int;lo_shipmode:STRING",
        "compress_type"="gz"
);

INSERT INTO customer (
    c_custkey,c_name,c_address,c_city,c_nation,c_region,c_phone,c_mktsegment
)SELECT * FROM S3 (
        "uri" = "s3://bench-dataset/ssb/sf100/customer/*",
        "format" = "csv",
        "s3.endpoint" = "https://s3.us-east-1.amazonaws.com",
        "column_separator" = "|",
        csv_schema = "c_custkey:int;c_name:string;c_address:string;c_city:string;c_nation:string;c_region:string;c_phone:string;c_mktsegment:string",
        "compress_type"="gz"
);

INSERT INTO dates (
    d_datekey,d_date,d_dayofweek,d_month,d_year,d_yearmonthnum,d_yearmonth,d_daynuminweek,d_daynuminmonth,d_daynuminyear,d_monthnuminyear,d_weeknuminyear,d_sellingseason,d_lastdayinweekfl,d_lastdayinmonthfl,d_holidayfl,d_weekdayfl
) SELECT * FROM S3 (
        "uri" = "s3://bench-dataset/ssb/sf100/date/*",
        "format" = "csv",
        "s3.endpoint" = "https://s3.us-east-1.amazonaws.com",
        "column_separator" = "|",
        csv_schema = "d_datekey:int;d_date:string;d_dayofweek:string;d_month:string;d_year:int;d_yearmonthnum:int;d_yearmonth:string;d_daynuminweek:int;d_daynuminmonth:int;d_daynuminyear:int;d_monthnuminyear:int;d_weeknuminyear:int;d_sellingseason:string;d_lastdayinweekfl:int;d_lastdayinmonthfl:int;d_holidayfl:int;d_weekdayfl:int",
        "compress_type"="gz"
);

INSERT INTO supplier (
    s_suppkey,s_name,s_address,s_city,s_nation,s_region,s_phone
)
SELECT * FROM S3 (
        "uri" = "s3://bench-dataset/ssb/sf100/supplier/*",
        "format" = "csv",
        "s3.endpoint" = "https://s3.us-east-1.amazonaws.com",
        "column_separator" = "|",
        csv_schema = "s_suppkey:int;s_name:string;s_address:string;s_city:string;s_nation:string;s_region:string;s_phone:string",
        "compress_type"="gz"
);

INSERT INTO part (
    p_partkey,p_name,p_mfgr,p_category,p_brand,p_color,p_type,p_size,p_container
)
SELECT * FROM S3 (
        "uri" = "s3://bench-dataset/ssb/sf100/part/*",
        "format" = "csv",
        "s3.endpoint" = "https://s3.us-east-1.amazonaws.com",
        "column_separator" = "|",
        csv_schema = "p_partkey:int;p_name:string;p_mfgr:string;p_category:string;p_brand:string;p_color:string;p_type:string;p_size:int;p_container:string",
        "compress_type"="gz"
);

drop table if exists lineorder_flat;
CREATE TABLE IF NOT EXISTS `lineorder_flat` (
    `LO_ORDERDATE` int(11) NOT NULL COMMENT "",
    `LO_ORDERKEY` int(11) NOT NULL COMMENT "",
    `LO_LINENUMBER` tinyint(4) NOT NULL COMMENT "",
    `LO_CUSTKEY` int(11) NOT NULL COMMENT "",
    `LO_PARTKEY` int(11) NOT NULL COMMENT "",
    `LO_SUPPKEY` int(11) NOT NULL COMMENT "",
    `LO_ORDERPRIORITY` varchar(100) NOT NULL COMMENT "",
    `LO_SHIPPRIORITY` tinyint(4) NOT NULL COMMENT "",
    `LO_QUANTITY` tinyint(4) NOT NULL COMMENT "",
    `LO_EXTENDEDPRICE` int(11) NOT NULL COMMENT "",
    `LO_ORDTOTALPRICE` int(11) NOT NULL COMMENT "",
    `LO_DISCOUNT` tinyint(4) NOT NULL COMMENT "",
    `LO_REVENUE` int(11) NOT NULL COMMENT "",
    `LO_SUPPLYCOST` int(11) NOT NULL COMMENT "",
    `LO_TAX` tinyint(4) NOT NULL COMMENT "",
    `LO_COMMITDATE` date NOT NULL COMMENT "",
    `LO_SHIPMODE` varchar(100) NOT NULL COMMENT "",
    `C_NAME` varchar(100) NOT NULL COMMENT "",
    `C_ADDRESS` varchar(100) NOT NULL COMMENT "",
    `C_CITY` varchar(100) NOT NULL COMMENT "",
    `C_NATION` varchar(100) NOT NULL COMMENT "",
    `C_REGION` varchar(100) NOT NULL COMMENT "",
    `C_PHONE` varchar(100) NOT NULL COMMENT "",
    `C_MKTSEGMENT` varchar(100) NOT NULL COMMENT "",
    `S_NAME` varchar(100) NOT NULL COMMENT "",
    `S_ADDRESS` varchar(100) NOT NULL COMMENT "",
    `S_CITY` varchar(100) NOT NULL COMMENT "",
    `S_NATION` varchar(100) NOT NULL COMMENT "",
    `S_REGION` varchar(100) NOT NULL COMMENT "",
    `S_PHONE` varchar(100) NOT NULL COMMENT "",
    `P_NAME` varchar(100) NOT NULL COMMENT "",
    `P_MFGR` varchar(100) NOT NULL COMMENT "",
    `P_CATEGORY` varchar(100) NOT NULL COMMENT "",
    `P_BRAND` varchar(100) NOT NULL COMMENT "",
    `P_COLOR` varchar(100) NOT NULL COMMENT "",
    `P_TYPE` varchar(100) NOT NULL COMMENT "",
    `P_SIZE` tinyint(4) NOT NULL COMMENT "",
    `P_CONTAINER` varchar(100) NOT NULL COMMENT ""
    ) ENGINE=OLAP
    DUPLICATE KEY(`LO_ORDERDATE`, `LO_ORDERKEY`)
    COMMENT "OLAP"
    PARTITION BY RANGE(`LO_ORDERDATE`)
(
    PARTITION p1992 VALUES [("-2147483648"), ("19930101")),
    PARTITION p1993 VALUES [("19930101"), ("19940101")),
    PARTITION p1994 VALUES [("19940101"), ("19950101")),
    PARTITION p1995 VALUES [("19950101"), ("19960101")),
    PARTITION p1996 VALUES [("19960101"), ("19970101")),
    PARTITION p1997 VALUES [("19970101"), ("19980101")),
    PARTITION p1998 VALUES [("19980101"), ("19990101"))
)
DISTRIBUTED BY HASH(`LO_ORDERKEY`) BUCKETS 48
PROPERTIES (
   "replication_num" = "1",
   "colocate_with" = "groupxx1"
);

INSERT INTO lineorder_flat
SELECT
  l.LO_ORDERDATE AS LO_ORDERDATE,
  l.LO_ORDERKEY AS LO_ORDERKEY,
  l.LO_LINENUMBER AS LO_LINENUMBER,
  l.LO_CUSTKEY AS LO_CUSTKEY,
  l.LO_PARTKEY AS LO_PARTKEY,
  l.LO_SUPPKEY AS LO_SUPPKEY,
  l.LO_ORDERPRIORITY AS LO_ORDERPRIORITY,
  l.LO_SHIPPRIORITY AS LO_SHIPPRIORITY,
  l.LO_QUANTITY AS LO_QUANTITY,
  l.LO_EXTENDEDPRICE AS LO_EXTENDEDPRICE,
  l.LO_ORDTOTALPRICE AS LO_ORDTOTALPRICE,
  l.LO_DISCOUNT AS LO_DISCOUNT,
  l.LO_REVENUE AS LO_REVENUE,
  l.LO_SUPPLYCOST AS LO_SUPPLYCOST,
  l.LO_TAX AS LO_TAX,
  l.LO_COMMITDATE AS LO_COMMITDATE,
  l.LO_SHIPMODE AS LO_SHIPMODE,
  c.C_NAME AS C_NAME,
  c.C_ADDRESS AS C_ADDRESS,
  c.C_CITY AS C_CITY,
  c.C_NATION AS C_NATION,
  c.C_REGION AS C_REGION,
  c.C_PHONE AS C_PHONE,
  c.C_MKTSEGMENT AS C_MKTSEGMENT,
  s.S_NAME AS S_NAME,
  s.S_ADDRESS AS S_ADDRESS,
  s.S_CITY AS S_CITY,
  s.S_NATION AS S_NATION,
  s.S_REGION AS S_REGION,
  s.S_PHONE AS S_PHONE,
  p.P_NAME AS P_NAME,
  p.P_MFGR AS P_MFGR,
  p.P_CATEGORY AS P_CATEGORY,
  p.P_BRAND AS P_BRAND,
  p.P_COLOR AS P_COLOR,
  p.P_TYPE AS P_TYPE,
  p.P_SIZE AS P_SIZE,
  p.P_CONTAINER AS P_CONTAINER
FROM lineorder AS l
        INNER JOIN customer AS c ON c.C_CUSTKEY = l.LO_CUSTKEY
        INNER JOIN supplier AS s ON s.S_SUPPKEY = l.LO_SUPPKEY
        INNER JOIN part AS p ON p.P_PARTKEY = l.LO_PARTKEY;
