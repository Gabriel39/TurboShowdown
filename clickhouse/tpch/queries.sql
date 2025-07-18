-- TPC-H 1
SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity) AS sum_qty,
    sum(l_extendedprice) AS sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) AS sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    avg(l_quantity) AS avg_qty,
    avg(l_extendedprice) AS avg_price,
    avg(l_discount) AS avg_disc,
    count(*) AS count_order
FROM
    lineitem
WHERE
        l_shipdate <= DATE '1998-12-01' - INTERVAL '90' DAY
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;

-- TPC-H 2 (modified)
WITH MinSupplyCost AS (
    SELECT
        ps_partkey,
        MIN(ps_supplycost) AS min_supplycost
    FROM
        partsupp ps
            JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
            JOIN
        nation n ON s.s_nationkey = n.n_nationkey
            JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
            r.r_name = 'EUROPE'
    GROUP BY
        ps_partkey
)
SELECT
    s.s_acctbal,
    s.s_name,
    n.n_name,
    p.p_partkey,
    p.p_mfgr,
    s.s_address,
    s.s_phone,
    s.s_comment
FROM
    part p
        JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
        JOIN
    supplier s ON s.s_suppkey = ps.ps_suppkey
        JOIN
    nation n ON s.s_nationkey = n.n_nationkey
        JOIN
    region r ON n.n_regionkey = r.r_regionkey
        JOIN
    MinSupplyCost msc ON ps.ps_partkey = msc.ps_partkey AND ps.ps_supplycost = msc.min_supplycost
WHERE
        p.p_size = 15
  AND p.p_type LIKE '%BRASS'
  AND r.r_name = 'EUROPE'
ORDER BY
    s.s_acctbal DESC,
    n.n_name,
    s.s_name,
    p.p_partkey;

-- TPC-H 3
SELECT
    l_orderkey,
    sum(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderdate,
    o_shippriority
FROM
    customer,
    orders,
    lineitem
WHERE
        c_mktsegment = 'BUILDING'
  AND c_custkey = o_custkey
  AND l_orderkey = o_orderkey
  AND o_orderdate < DATE '1995-03-15'
  AND l_shipdate > DATE '1995-03-15'
GROUP BY
    l_orderkey,
    o_orderdate,
    o_shippriority
ORDER BY
    revenue DESC,
    o_orderdate;

-- TPC-H 4 (modified)
WITH ValidLineItems AS (
    SELECT
        l_orderkey
    FROM
        lineitem
    WHERE
            l_commitdate < l_receiptdate
    GROUP BY
        l_orderkey
)
SELECT
    o.o_orderpriority,
    COUNT(*) AS order_count
FROM
    orders o
        JOIN
    ValidLineItems vli ON o.o_orderkey = vli.l_orderkey
WHERE
        o.o_orderdate >= DATE '1993-07-01'
  AND o.o_orderdate < DATE '1993-07-01' + INTERVAL '3' MONTH
GROUP BY
    o.o_orderpriority
ORDER BY
    o.o_orderpriority;

-- TPC-H 5
SELECT
    n_name,
    sum(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    customer,
    orders,
    lineitem,
    supplier,
    nation,
    region
WHERE
        c_custkey = o_custkey
  AND l_orderkey = o_orderkey
  AND l_suppkey = s_suppkey
  AND c_nationkey = s_nationkey
  AND s_nationkey = n_nationkey
  AND n_regionkey = r_regionkey
  AND r_name = 'ASIA'
  AND o_orderdate >= DATE '1994-01-01'
  AND o_orderdate < DATE '1994-01-01' + INTERVAL '1' year
GROUP BY
    n_name
ORDER BY
    revenue DESC;

-- TPC-H 6 (modified)
SELECT
    sum(l_extendedprice * l_discount) AS revenue
FROM
    lineitem
WHERE
        l_shipdate >= DATE '1994-01-01'
  AND l_shipdate < DATE '1994-01-01' + INTERVAL '1' year
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

-- TPC-H 7
SELECT
    supp_nation,
    cust_nation,
    l_year,
    sum(volume) AS revenue
FROM (
         SELECT
             n1.n_name AS supp_nation,
             n2.n_name AS cust_nation,
             extract(year FROM l_shipdate) AS l_year,
             l_extendedprice * (1 - l_discount) AS volume
         FROM
             supplier,
             lineitem,
             orders,
             customer,
             nation n1,
             nation n2
         WHERE
                 s_suppkey = l_suppkey
           AND o_orderkey = l_orderkey
           AND c_custkey = o_custkey
           AND s_nationkey = n1.n_nationkey
           AND c_nationkey = n2.n_nationkey
           AND (
                 (n1.n_name = 'FRANCE' AND n2.n_name = 'GERMANY')
                 OR (n1.n_name = 'GERMANY' AND n2.n_name = 'FRANCE')
             )
           AND l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
     ) AS shipping
GROUP BY
    supp_nation,
    cust_nation,
    l_year
ORDER BY
    supp_nation,
    cust_nation,
    l_year;

-- TPC-H 8
SELECT
    o_year,
    sum(CASE
            WHEN nation = 'BRAZIL'
                THEN volume
            ELSE 0
        END) / sum(volume) AS mkt_share
FROM (
         SELECT
             extract(year FROM o_orderdate) AS o_year,
             l_extendedprice * (1 - l_discount) AS volume,
             n2.n_name AS nation
         FROM
             part,
             supplier,
             lineitem,
             orders,
             customer,
             nation n1,
             nation n2,
             region
         WHERE
                 p_partkey = l_partkey
           AND s_suppkey = l_suppkey
           AND l_orderkey = o_orderkey
           AND o_custkey = c_custkey
           AND c_nationkey = n1.n_nationkey
           AND n1.n_regionkey = r_regionkey
           AND r_name = 'AMERICA'
           AND s_nationkey = n2.n_nationkey
           AND o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
           AND p_type = 'ECONOMY ANODIZED STEEL'
     ) AS all_nations
GROUP BY
    o_year
ORDER BY
    o_year;

-- TPC-H 9
SELECT
    nation,
    o_year,
    sum(amount) AS sum_profit
FROM (
         SELECT
             n_name AS nation,
             extract(year FROM o_orderdate) AS o_year,
             l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity AS amount
         FROM
             part,
             supplier,
             lineitem,
             partsupp,
             orders,
             nation
         WHERE
                 s_suppkey = l_suppkey
           AND ps_suppkey = l_suppkey
           AND ps_partkey = l_partkey
           AND p_partkey = l_partkey
           AND o_orderkey = l_orderkey
           AND s_nationkey = n_nationkey
           AND p_name LIKE '%green%'
     ) AS profit
GROUP BY
    nation,
    o_year
ORDER BY
    nation,
    o_year DESC;

-- TPC-H 10
SELECT
    c_custkey,
    c_name,
    sum(l_extendedprice * (1 - l_discount)) AS revenue,
    c_acctbal,
    n_name,
    c_address,
    c_phone,
    c_comment
FROM
    customer,
    orders,
    lineitem,
    nation
WHERE
        c_custkey = o_custkey
  AND l_orderkey = o_orderkey
  AND o_orderdate >= DATE '1993-10-01'
  AND o_orderdate < DATE '1993-10-01' + INTERVAL '3' MONTH
  AND l_returnflag = 'R'
  AND c_nationkey = n_nationkey
GROUP BY
    c_custkey,
    c_name,
    c_acctbal,
    c_phone,
    n_name,
    c_address,
    c_comment
ORDER BY
    revenue DESC;

-- TPC-H 11
SELECT
    ps_partkey,
    sum(ps_supplycost * ps_availqty) AS value
FROM
    partsupp,
    supplier,
    nation
WHERE
    ps_suppkey = s_suppkey
  AND s_nationkey = n_nationkey
  AND n_name = 'GERMANY'
GROUP BY
    ps_partkey
HAVING
    sum(ps_supplycost * ps_availqty) > (
    SELECT
    sum(ps_supplycost * ps_availqty) * 0.0001
    FROM
    partsupp,
    supplier,
    nation
    WHERE
    ps_suppkey = s_suppkey
   AND s_nationkey = n_nationkey
   AND n_name = 'GERMANY'
    )
ORDER BY
    value DESC;

-- TPC-H 12
SELECT
    l_shipmode,
    sum(CASE
            WHEN o_orderpriority = '1-URGENT'
                OR o_orderpriority = '2-HIGH'
                THEN 1
            ELSE 0
        END) AS high_line_count,
    sum(CASE
            WHEN o_orderpriority <> '1-URGENT'
                AND o_orderpriority <> '2-HIGH'
                THEN 1
            ELSE 0
        END) AS low_line_count
FROM
    orders,
    lineitem
WHERE
        o_orderkey = l_orderkey
  AND l_shipmode in ('MAIL', 'SHIP')
  AND l_commitdate < l_receiptdate
  AND l_shipdate < l_commitdate
  AND l_receiptdate >= DATE '1994-01-01'
  AND l_receiptdate < DATE '1994-01-01' + INTERVAL '1' year
GROUP BY
    l_shipmode
ORDER BY
    l_shipmode;

-- TPC-H 13
SELECT
    c_count,
    count(*) AS custdist
FROM (
         SELECT
             c_custkey,
             count(o_orderkey) as c_count
         FROM
             customer LEFT OUTER JOIN orders ON
                         c_custkey = o_custkey
                     AND o_comment NOT LIKE '%special%requests%'
         GROUP BY
             c_custkey
     ) AS c_orders
GROUP BY
    c_count
ORDER BY
    custdist DESC,
    c_count DESC;

-- TPC-H 14
SELECT
            100.00 * sum(CASE
                             WHEN p_type LIKE 'PROMO%'
                                 THEN l_extendedprice * (1 - l_discount)
                             ELSE 0
            END) / sum(l_extendedprice * (1 - l_discount)) AS promo_revenue
FROM
    lineitem,
    part
WHERE
        l_partkey = p_partkey
  AND l_shipdate >= DATE '1995-09-01'
  AND l_shipdate < DATE '1995-09-01' + INTERVAL '1' MONTH;

-- TPC-H 15
SELECT
    s_suppkey,
    s_name,
    s_address,
    s_phone,
    total_revenue
FROM
    supplier,
    revenue0
WHERE
        s_suppkey = supplier_no
  AND total_revenue = (
    SELECT
        max(total_revenue)
    FROM
        revenue0
)
ORDER BY
    s_suppkey;

-- TPC-H 16
SELECT
    p_brand,
    p_type,
    p_size,
    count(distinct ps_suppkey) AS supplier_cnt
FROM
    partsupp,
    part
WHERE
        p_partkey = ps_partkey
  AND p_brand <> 'Brand#45'
  AND p_type NOT LIKE 'MEDIUM POLISHED%'
  AND p_size in (49, 14, 23,  45, 19, 3, 36, 9)
  AND ps_suppkey NOT in (
    SELECT
        s_suppkey
    FROM
        supplier
    WHERE
            s_comment LIKE '%Customer%Complaints%'
)
GROUP BY
    p_brand,
    p_type,
    p_size
ORDER BY
    supplier_cnt DESC,
    p_brand,
    p_type,
    p_size;

-- TPC-H 17 (modified)
WITH AvgQuantity AS (
    SELECT
        l_partkey,
        AVG(l_quantity) * 0.2 AS avg_quantity
    FROM
        lineitem
    GROUP BY
        l_partkey
)
SELECT
        SUM(l.l_extendedprice) / 7.0 AS avg_yearly
FROM
    lineitem l
        JOIN
    part p ON p.p_partkey = l.l_partkey
        JOIN
    AvgQuantity aq ON l.l_partkey = aq.l_partkey
WHERE
        p.p_brand = 'Brand#23'
  AND p.p_container = 'MED BOX'
  AND l.l_quantity < aq.avg_quantity;

-- TPC-H 18
SELECT
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice,
    sum(l_quantity)
FROM
    customer,
    orders,
    lineitem
WHERE
        o_orderkey in (
        SELECT
            l_orderkey
        FROM
            lineitem
        GROUP BY
            l_orderkey
        HAVING
                sum(l_quantity) > 300
    )
  AND c_custkey = o_custkey
  AND o_orderkey = l_orderkey
GROUP BY
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice
ORDER BY
    o_totalprice DESC,
    o_orderdate;

-- TPC-H 19
SELECT
    sum(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    lineitem,
    part
WHERE
    (
                p_partkey = l_partkey
            AND p_brand = 'Brand#12'
            AND p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
            AND l_quantity >= 1 AND l_quantity <= 1 + 10
            AND p_size BETWEEN 1 AND 5
            AND l_shipmode in ('AIR', 'AIR REG')
            AND l_shipinstruct = 'DELIVER IN PERSON'
        )
   OR
    (
                p_partkey = l_partkey
            AND p_brand = 'Brand#23'
            AND p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
            AND l_quantity >= 10 AND l_quantity <= 10 + 10
            AND p_size BETWEEN 1 AND 10
            AND l_shipmode in ('AIR', 'AIR REG')
            AND l_shipinstruct = 'DELIVER IN PERSON'
        )
   OR
    (
                p_partkey = l_partkey
            AND p_brand = 'Brand#34'
            AND p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
            AND l_quantity >= 20 AND l_quantity <= 20 + 10
            AND p_size BETWEEN 1 AND 15
            AND l_shipmode in ('AIR', 'AIR REG')
            AND l_shipinstruct = 'DELIVER IN PERSON'
        );

-- TPC-H 20
SELECT
    s_name,
    s_address
FROM
    supplier,
    nation
WHERE
        s_suppkey in (
        SELECT
            ps_suppkey
        FROM
            partsupp
        WHERE
                ps_partkey in (
                SELECT
                    p_partkey
                FROM
                    part
                WHERE
                        p_name LIKE 'forest%'
            )
          AND ps_availqty > (
            SELECT
                    0.5 * sum(l_quantity)
            FROM
                lineitem
            WHERE
                    l_partkey = ps_partkey
              AND l_suppkey = ps_suppkey
              AND l_shipdate >= DATE '1994-01-01'
              AND l_shipdate < DATE '1994-01-01' + INTERVAL '1' year
        )
    )
  AND s_nationkey = n_nationkey
  AND n_name = 'CANADA'
ORDER BY
    s_name
SETTINGS allow_experimental_correlated_subqueries = 1;

-- TPC-H 21
SELECT
    s_name,
    count(*) AS numwait
FROM
    supplier,
    lineitem l1,
    orders,
    nation
WHERE
        s_suppkey = l1.l_suppkey
  AND o_orderkey = l1.l_orderkey
  AND o_orderstatus = 'F'
  AND l1.l_receiptdate > l1.l_commitdate
  AND EXISTS (
        SELECT
            *
        FROM
            lineitem l2
        WHERE
                l2.l_orderkey = l1.l_orderkey
          AND l2.l_suppkey <> l1.l_suppkey
    )
  AND NOT EXISTS (
        SELECT
            *
        FROM
            lineitem l3
        WHERE
                l3.l_orderkey = l1.l_orderkey
          AND l3.l_suppkey <> l1.l_suppkey
          AND l3.l_receiptdate > l3.l_commitdate
    )
  AND s_nationkey = n_nationkey
  AND n_name = 'SAUDI ARABIA'
GROUP BY
    s_name
ORDER BY
    numwait DESC,
    s_name
SETTINGS allow_experimental_correlated_subqueries = 1;

-- TPC-H 22
SELECT
    cntrycode,
    count(*) AS numcust,
    sum(c_acctbal) AS totacctbal
FROM (
         SELECT
             substring(c_phone FROM 1 for 2) AS cntrycode,
             c_acctbal
         FROM
             customer
         WHERE
                 substring(c_phone FROM 1 for 2) in
                 ('13', '31', '23', '29', '30', '18', '17')
           AND c_acctbal > (
             SELECT
                 avg(c_acctbal)
             FROM
                 customer
             WHERE
                     c_acctbal > 0.00
               AND substring(c_phone FROM 1 for 2) in
                   ('13', '31', '23', '29', '30', '18', '17')
         )
           AND NOT EXISTS (
                 SELECT
                     *
                 FROM
                     orders
                 WHERE
                         o_custkey = c_custkey
             )
     ) AS custsale
GROUP BY
    cntrycode
ORDER BY
    cntrycode
SETTINGS allow_experimental_correlated_subqueries = 1;
