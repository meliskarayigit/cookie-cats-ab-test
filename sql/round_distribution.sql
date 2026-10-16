-- Distribution of rounds played in the first 14 days, per A/B version.
-- pct_of_version is used instead of raw counts because the two groups differ slightly in size.
-- bucket_order lets Power BI sort the buckets logically (0, 1-10, 11-50, 51-100, 100+).
WITH bucketed AS (
    SELECT
        version,
        CASE WHEN sum_gamerounds = 0   THEN '0'
             WHEN sum_gamerounds <= 10  THEN '1-10'
             WHEN sum_gamerounds <= 50  THEN '11-50'
             WHEN sum_gamerounds <= 100 THEN '51-100'
             ELSE '100+' END AS round_bucket,
        CASE WHEN sum_gamerounds = 0   THEN 1
             WHEN sum_gamerounds <= 10  THEN 2
             WHEN sum_gamerounds <= 50  THEN 3
             WHEN sum_gamerounds <= 100 THEN 4
             ELSE 5 END AS bucket_order
    FROM cookie_cats
)
SELECT
    version,
    round_bucket,
    bucket_order,
    COUNT(*) AS player_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY version), 2) AS pct_of_version
FROM bucketed
GROUP BY version, round_bucket, bucket_order
ORDER BY version, bucket_order;
