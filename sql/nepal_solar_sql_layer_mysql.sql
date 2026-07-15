-- ================================================================
-- Nepal Solar Resource Analysis -- SQL Layer (MySQL 8.0+)
--
-- Schema, staging-to-fact load pattern, and eight analytical queries
-- on top of data already validated in the Jupyter notebook (77
-- districts, PVGIS ERA5, 2005-2023, DSCR Scenario A/B, ONI
-- correlation). This re-expresses the same analysis in SQL to
-- demonstrate schema design, window functions, CTEs, and views on
-- real lender-facing data.
--
-- Target: MySQL 8.0+ (required for window functions, CTEs, RANK()).
-- ================================================================


-- ================================================================
-- PART 1: SCHEMA
-- ================================================================

CREATE SCHEMA IF NOT EXISTS nepal_solar;
USE nepal_solar;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS fact_dscr_result;
DROP TABLE IF EXISTS dim_dscr_scenario;
DROP TABLE IF EXISTS fact_oni;
DROP TABLE IF EXISTS fact_variability;
DROP TABLE IF EXISTS fact_scenarios;
DROP TABLE IF EXISTS fact_exceedance;
DROP TABLE IF EXISTS fact_ghi_monthly;
DROP TABLE IF EXISTS fact_ghi_annual;
DROP TABLE IF EXISTS dim_district;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE dim_district (
    district_id   INT AUTO_INCREMENT PRIMARY KEY,
    district_name VARCHAR(50) UNIQUE NOT NULL,
    zone          VARCHAR(50) NOT NULL,
    latitude      DECIMAL(6,3) NOT NULL,
    longitude     DECIMAL(6,3) NOT NULL
);

CREATE TABLE fact_ghi_annual (
    district_id INT NOT NULL,
    year        INT NOT NULL,
    ghi_annual  DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (district_id, year),
    FOREIGN KEY (district_id) REFERENCES dim_district(district_id)
);

CREATE TABLE fact_ghi_monthly (
    district_id INT NOT NULL,
    year        INT NOT NULL,
    month       INT NOT NULL,
    ghi_monthly DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (district_id, year, month),
    FOREIGN KEY (district_id) REFERENCES dim_district(district_id),
    CHECK (month BETWEEN 1 AND 12)
);

CREATE TABLE fact_exceedance (
    district_id INT PRIMARY KEY,
    p50 DECIMAL(8,2),
    p75 DECIMAL(8,2),
    p90 DECIMAL(8,2),
    p99 DECIMAL(8,2),
    FOREIGN KEY (district_id) REFERENCES dim_district(district_id)
);

CREATE TABLE fact_scenarios (
    district_id  INT PRIMARY KEY,
    base_pct     DECIMAL(6,2),   -- % of long-run mean, 2022-2023 window
    downside_pct DECIMAL(6,2),   -- % of long-run mean, 2015-2021 trough
    stress_pct   DECIMAL(6,2),   -- % of long-run mean, 2038 extrapolation (illustrative)
    FOREIGN KEY (district_id) REFERENCES dim_district(district_id)
);

CREATE TABLE fact_variability (
    district_id INT PRIMARY KEY,
    ghi_mean    DECIMAL(8,2),
    ghi_std     DECIMAL(8,2),
    cov_pct     DECIMAL(6,2),
    FOREIGN KEY (district_id) REFERENCES dim_district(district_id)
);

CREATE TABLE fact_oni (
    year      INT PRIMARY KEY,
    season    VARCHAR(10) DEFAULT 'DJF',
    oni_value DECIMAL(4,2)
);

CREATE TABLE dim_dscr_scenario (
    scenario_id     INT AUTO_INCREMENT PRIMARY KEY,
    scenario_name   VARCHAR(20) NOT NULL,   -- 'Scenario A', 'Scenario B'
    capex_per_mw    DECIMAL(12,0) NOT NULL,
    tariff          DECIMAL(5,2) NOT NULL,
    debt_ratio      DECIMAL(4,2) NOT NULL,
    interest_rate   DECIMAL(4,3) NOT NULL,
    loan_term_years INT NOT NULL
);

CREATE TABLE fact_dscr_result (
    scenario_id   INT NOT NULL,
    project_year  INT NOT NULL,
    resource_case VARCHAR(30) NOT NULL,     -- 'P50', 'Trough', 'Worst'
    dscr_value    DECIMAL(6,3) NOT NULL,
    status        VARCHAR(20) NOT NULL,
    PRIMARY KEY (scenario_id, project_year, resource_case),
    FOREIGN KEY (scenario_id) REFERENCES dim_dscr_scenario(scenario_id)
);


-- ================================================================
-- PART 2: LOADING
-- CSVs are staged via MySQL Workbench's Table Data Import Wizard
-- (district_name/location-keyed, not district_id-keyed), then moved
-- into the dimensional model with the inserts below.
-- ================================================================

-- 2.1 -- source: nepal_districts_lookup.csv -> stg_districts
INSERT INTO dim_district (district_name, zone, latitude, longitude)
SELECT DISTINCT district_name, zone, latitude, longitude FROM stg_districts;

-- 2.2 -- source: nepal_ghi_yearly_trend_77.csv -> stg_ghi_annual
INSERT INTO fact_ghi_annual (district_id, year, ghi_annual)
SELECT d.district_id, s.year, s.GHI_annual
FROM stg_ghi_annual s
JOIN dim_district d ON d.district_name = s.location;

-- 2.3 -- source: nepal_ghi_p90_estimates_77.csv -> stg_exceedance
-- Staging table carries 9 columns (raw stats + percentiles); only
-- the four percentile columns are needed here.
INSERT INTO fact_exceedance (district_id, p50, p75, p90, p99)
SELECT d.district_id, s.p50, s.p75, s.p90, s.p99
FROM stg_exceedance s
JOIN dim_district d ON d.district_name = s.location;

-- 2.4 -- source: nepal_ghi_variability_77.csv -> stg_variability
INSERT INTO fact_variability (district_id, ghi_mean, ghi_std, cov_pct)
SELECT d.district_id, s.ghi_mean, s.ghi_std, s.cov_pct
FROM stg_variability s
JOIN dim_district d ON d.district_name = s.location;

-- 2.5 -- source: nepal_ghi_scenarios_77.csv -> stg_scenarios
INSERT INTO fact_scenarios (district_id, base_pct, downside_pct, stress_pct)
SELECT d.district_id, s.base_pct, s.downside_pct, s.stress_pct
FROM stg_scenarios s
JOIN dim_district d ON d.district_name = s.location;

-- 2.6 -- source: nepal_oni_annual.csv, imported directly into fact_oni
-- (no district join; loaded via the wizard's "use existing table" option).

-- 2.7 -- source: nepal_dscr_full_77.csv -> stg_dscr
-- Unlike the staging tables above, stg_dscr is created explicitly rather
-- than left to the Import Wizard's type inference, so CAPEX, tariff, and
-- DSCR figures load as fixed-precision DECIMAL rather than float.
DROP TABLE IF EXISTS stg_dscr;
CREATE TABLE stg_dscr (
    scenario_name   VARCHAR(20)   NOT NULL,
    capex_per_mw    DECIMAL(12,0) NOT NULL,
    tariff          DECIMAL(5,2)  NOT NULL,
    debt_ratio      DECIMAL(4,2)  NOT NULL,
    interest_rate   DECIMAL(4,3)  NOT NULL,
    loan_term_years INT           NOT NULL,
    project_year    INT           NOT NULL,
    resource_case   VARCHAR(30)   NOT NULL,
    ghi_value       DECIMAL(8,2),
    dscr_value      DECIMAL(6,3)  NOT NULL,
    status          VARCHAR(20)   NOT NULL
);
-- nepal_dscr_full_77.csv loads into stg_dscr here via the Import Wizard,
-- "use existing table," before the two inserts below run.

-- 2.8 -- populate dim_dscr_scenario: one row per distinct scenario
-- definition (CAPEX, tariff, debt ratio, interest rate, loan term)
INSERT INTO dim_dscr_scenario (scenario_name, capex_per_mw, tariff, debt_ratio, interest_rate, loan_term_years)
SELECT DISTINCT scenario_name, capex_per_mw, tariff, debt_ratio, interest_rate, loan_term_years
FROM stg_dscr;

-- 2.9 -- populate fact_dscr_result, resolving scenario_id by joining
-- back to dim_dscr_scenario on the same five defining columns
INSERT INTO fact_dscr_result (scenario_id, project_year, resource_case, dscr_value, status)
SELECT s.scenario_id, g.project_year, g.resource_case, g.dscr_value, g.status
FROM stg_dscr g
JOIN dim_dscr_scenario s
  ON s.scenario_name = g.scenario_name
 AND s.capex_per_mw = g.capex_per_mw
 AND s.tariff = g.tariff
 AND s.debt_ratio = g.debt_ratio
 AND s.interest_rate = g.interest_rate
 AND s.loan_term_years = g.loan_term_years;

-- ================================================================
-- PART 3: ANALYTICAL QUERIES
-- ================================================================

-- 3.1 Year-over-year GHI change per district (window function: LAG)
SELECT
    d.district_name, d.zone, f.year, f.ghi_annual,
    f.ghi_annual - LAG(f.ghi_annual) OVER (PARTITION BY f.district_id ORDER BY f.year) AS yoy_change,
    ROUND(100.0 * (f.ghi_annual - LAG(f.ghi_annual) OVER (PARTITION BY f.district_id ORDER BY f.year))
          / NULLIF(LAG(f.ghi_annual) OVER (PARTITION BY f.district_id ORDER BY f.year), 0), 2) AS yoy_pct_change
FROM fact_ghi_annual f
JOIN dim_district d ON d.district_id = f.district_id
ORDER BY d.district_name, f.year;

-- 3.2 Rolling 3-year average per district (window function: moving frame)
SELECT
    d.district_name, f.year, f.ghi_annual,
    ROUND(AVG(f.ghi_annual) OVER (
        PARTITION BY f.district_id ORDER BY f.year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS rolling_3yr_avg
FROM fact_ghi_annual f
JOIN dim_district d ON d.district_id = f.district_id
ORDER BY d.district_name, f.year;

-- 3.3 Net change 2005 vs 2023, ranked (CTE + RANK)
WITH baseline AS (
    SELECT district_id, ghi_annual AS ghi_2005 FROM fact_ghi_annual WHERE year = 2005
),
endpoint AS (
    SELECT district_id, ghi_annual AS ghi_2023 FROM fact_ghi_annual WHERE year = 2023
)
SELECT
    d.district_name, d.zone, b.ghi_2005, e.ghi_2023,
    ROUND(100.0 * (e.ghi_2023 - b.ghi_2005) / b.ghi_2005, 2) AS pct_change,
    RANK() OVER (ORDER BY (e.ghi_2023 - b.ghi_2005) / b.ghi_2005 ASC) AS decline_rank
FROM baseline b
JOIN endpoint e ON e.district_id = b.district_id
JOIN dim_district d ON d.district_id = b.district_id
ORDER BY pct_change ASC;

-- 3.4 Trough duration per district: max consecutive years below 95% of
-- long-run mean (gaps-and-islands pattern). This threshold does not
-- classify any district above Low risk, a property of the 95% cutoff
-- itself, documented alongside the trough detection methodology in
-- the notebook.
WITH district_mean AS (
    SELECT district_id, AVG(ghi_annual) AS long_run_mean
    FROM fact_ghi_annual GROUP BY district_id
),
flagged AS (
    SELECT f.district_id, f.year,
        CASE WHEN f.ghi_annual < 0.95 * m.long_run_mean THEN 1 ELSE 0 END AS below_threshold
    FROM fact_ghi_annual f
    JOIN district_mean m ON m.district_id = f.district_id
),
grouped AS (
    SELECT district_id, year, below_threshold,
        year - ROW_NUMBER() OVER (PARTITION BY district_id, below_threshold ORDER BY year) AS grp
    FROM flagged
),
runs AS (
    SELECT district_id, grp, COUNT(*) AS run_length
    FROM grouped
    WHERE below_threshold = 1
    GROUP BY district_id, grp
)
SELECT d.district_name, COALESCE(MAX(r.run_length), 0) AS max_consecutive_years_below_threshold
FROM dim_district d
LEFT JOIN runs r ON r.district_id = d.district_id
GROUP BY d.district_name
ORDER BY max_consecutive_years_below_threshold DESC;

-- 3.5 Empirical P50/P90 directly from the annual series (order-statistic
-- method via PERCENT_RANK, portable across all MySQL 8.0+ builds; use
-- PERCENTILE_CONT directly on 8.0.31+). Deliberately kept separate from
-- fact_exceedance, which uses a normal-distribution assumption computed
-- in Python -- the two methods disagree by roughly 0.3-1.3% on sampled
-- districts, expected given a 19-observation series for a tail estimate.
WITH ranked AS (
    SELECT d.district_name, f.ghi_annual,
        PERCENT_RANK() OVER (PARTITION BY f.district_id ORDER BY f.ghi_annual) AS pct_rank
    FROM fact_ghi_annual f
    JOIN dim_district d ON d.district_id = f.district_id
)
SELECT district_name,
    MIN(CASE WHEN pct_rank >= 0.5 THEN ghi_annual END) AS empirical_p50,
    MIN(CASE WHEN pct_rank >= 0.1 THEN ghi_annual END) AS empirical_p90
FROM ranked
GROUP BY district_name
ORDER BY empirical_p50 DESC;

-- 3.6 Zone-level summary. Implemented as a standard VIEW (MySQL has no
-- materialized view feature); at 77 districts this recomputes with no
-- noticeable cost, and downstream tools always see current data with
-- no manual refresh step needed.
CREATE OR REPLACE VIEW zone_summary AS
SELECT
    d.zone,
    COUNT(DISTINCT d.district_id) AS n_districts,
    ROUND(AVG(v.ghi_mean), 0) AS zone_mean_ghi,
    ROUND(AVG(v.cov_pct), 2) AS zone_avg_cov_pct,
    ROUND(AVG(e.p90 / NULLIF(e.p50, 0)), 3) AS zone_avg_p90_p50_ratio
FROM dim_district d
JOIN fact_variability v ON v.district_id = d.district_id
JOIN fact_exceedance e ON e.district_id = d.district_id
GROUP BY d.zone
ORDER BY zone_avg_cov_pct DESC;


-- 3.7 DSCR covenant breaches across both scenarios (join dim + fact)
SELECT
    s.scenario_name, s.tariff, s.capex_per_mw,
    r.project_year, r.resource_case, r.dscr_value, r.status
FROM fact_dscr_result r
JOIN dim_dscr_scenario s ON s.scenario_id = r.scenario_id
WHERE r.dscr_value < 1.20
ORDER BY r.dscr_value ASC;

-- 3.8 System-wide GHI anomaly against ONI, ready for a dual-axis chart
-- in Tableau or Power BI without redoing the join in Python.
SELECT
    o.year, o.oni_value, ROUND(AVG(f.ghi_annual), 1) AS system_wide_ghi
FROM fact_oni o
JOIN fact_ghi_annual f ON f.year = o.year
GROUP BY o.year, o.oni_value
ORDER BY o.year;
