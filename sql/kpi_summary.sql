-- KPI summary per A/B version.
-- Retention uses every player. Average rounds are capped at the limit stored in
-- analysis_params (written by notebook 01), so one extreme player cannot skew the mean.
SELECT
    version,
    COUNT(*)                         AS total_players,
    ROUND(AVG(retention_1) * 100, 2) AS d1_retention_pct,
    ROUND(AVG(retention_7) * 100, 2) AS d7_retention_pct,
    ROUND(AVG(MIN(
        sum_gamerounds,
        (SELECT value FROM analysis_params WHERE name = 'rounds_cap')
    )), 1)                           AS avg_rounds_capped
FROM cookie_cats
GROUP BY version;
