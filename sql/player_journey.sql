-- Player journey: how many players installed, and how many came back on day 1 and day 7.
-- All 90,189 players are kept: filtering on post-install behaviour would bias retention.
SELECT
    version,
    COUNT(*)         AS installed,
    SUM(retention_1) AS returned_day1,
    SUM(retention_7) AS returned_day7
FROM cookie_cats
GROUP BY version;
