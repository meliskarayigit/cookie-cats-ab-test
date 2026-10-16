# Dashboard specification

Single report page, 16:9 (1280 x 720). Control (`gate_30`) is always blue `#4C86B4`, treatment (`gate_40`) is always amber `#E8A33D`. Load `cookie_cats_theme.json` (View > Themes > Browse for themes) so every visual that uses `version` as legend gets these two colors.

## Data model

Source files (all in `data/exports/`): `kpi_summary.csv`, `player_journey.csv`, `round_distribution.csv`, `test_results.csv`.

**Power Query steps**
- `test_results`: select `diff_pp`, `ci_low_pp`, `ci_high_pp`, `p_value`, `relative_change_pct` > Change Type > Using Locale > Decimal Number, English (United States). Otherwise decimals can be misread on non-English systems and the DAX comparisons on `p_value` fail.
- `retention_long`: new query that **references** `kpi_summary`; keep `version`, `d1_retention_pct`, `d7_retention_pct`; select the last two > Unpivot Columns; rename `Attribute` to `metric` and `Value` to `retention_pct`; replace `d1_retention_pct` with `D1` and `d7_retention_pct` with `D7`.
- `dim_version`: Enter Data with two rows: `gate_30` / Control and `gate_40` / Treatment (columns `version`, `group`).

**Relationships.** `dim_version[version]` (one) to `version` (many) in `kpi_summary`, `player_journey`, `round_distribution`, `retention_long`. `test_results` has no relationship (one row per metric, not per version).

## Visuals

| Visual | Type | Table and fields | Filter / formatting |
|---|---|---|---|
| Finding | Card | `[Finding Text]` | font 14, word wrap on |
| Recommendation | Card | `[Recommendation Text]` | font 14, word wrap on |
| Player journey: gate_30 | Funnel | `player_journey`: Group = `stage` (sort by `stage_order`), Values = `players` | visual filter `version = gate_30`; one fixed bar color `#4C86B4` |
| Player journey: gate_40 | Funnel | same fields | visual filter `version = gate_40`; fixed color `#E8A33D` |
| KPI cards, one set per version (4 cards each) | Card | `kpi_summary`: `total_players`, `avg_rounds_capped`, `d1_retention_pct`, `d7_retention_pct` | visual filter on `version`; **same order in both panels**; players 0 decimals, rounds 1 decimal, retention custom format `0.00"%"` |
| Retention by version | Clustered column | `retention_long`: Axis = `metric`, Legend = `dim_version[version]`, Values = `retention_pct` | Y axis starts at 0; data labels 1 decimal |
| Retention gap table | Table | `test_results`: `retention_day`, `diff_pp`, `ci_low_pp`, `ci_high_pp`, `p_value`, `significant` | title "Retention gap, gate_40 - gate_30 (pp)"; rename headers (Day, Gap (pp), CI low, CI high, p-value, Significant); data bars on `diff_pp`; background rule on `significant` (Yes = amber, No = gray); `p_value` 4 decimals |
| D7 relative change | Card | `test_results[relative_change_pct]` | visual filter `retention_day = D7`; 1 decimal |
| D7 p-value | Card | `test_results[p_value]` | visual filter `retention_day = D7`; 4 decimals |
| Rounds played by version | Clustered column | `round_distribution`: Axis = `round_bucket` (Sort by column: `bucket_order`), Legend = `dim_version[version]`, Values = `pct_of_version` | data labels 1 decimal, horizontal; Y axis starts at 0 |

## DAX measures (create on `test_results`)

```dax
Finding Text =
VAR d7  = CALCULATE(MAX(test_results[diff_pp]), test_results[retention_day] = "D7")
VAR rel = CALCULATE(MAX(test_results[relative_change_pct]), test_results[retention_day] = "D7")
VAR p7  = CALCULATE(MAX(test_results[p_value]), test_results[retention_day] = "D7")
VAR p1  = CALCULATE(MAX(test_results[p_value]), test_results[retention_day] = "D1")
RETURN
"gate_40 " & IF(d7 < 0, "lowers", "raises") & " D7 retention by "
    & FORMAT(ABS(d7), "0.00") & " pp (" & FORMAT(ABS(rel), "0.0") & "% relative), "
    & IF(p7 < 0.05, "statistically significant", "not statistically significant")
    & " (p = " & FORMAT(p7, "0.0000") & "). D1: "
    & IF(p1 < 0.05, "significant", "no significant difference")
    & " (p = " & FORMAT(p1, "0.0000") & ")."
```

```dax
Recommendation Text =
VAR p7 = CALCULATE(MAX(test_results[p_value]), test_results[retention_day] = "D7")
VAR d7 = CALCULATE(MAX(test_results[diff_pp]), test_results[retention_day] = "D7")
RETURN
IF(p7 < 0.05 && d7 < 0,
    "Recommendation: keep the gate at level 30. Moving it to level 40 lowers D7 retention.",
IF(p7 < 0.05 && d7 > 0,
    "Recommendation: consider moving the gate to level 40. It raises D7 retention.",
    "Recommendation: no evidence that gate placement changes D7 retention. Decide on other criteria."))
```

## Checklist before taking the screenshot

- Every number on the page comes from one of the four CSVs; D1 and D7 are identical everywhere they appear.
- Card order is the same for control and treatment.
- One color per version on every visual; no per-stage or per-metric colors.
- Every visual has a title; buckets are sorted 0, 1-10, 11-50, 51-100, 100+.
- No visual is selected (no hover toolbar in the screenshot). Save as `powerbi/dashboard.png`.
