# Nepal Solar Resource Analysis

A solar resource and financial risk analysis of Nepal's utility-scale solar
development potential, built on PVGIS ERA5 satellite-reanalysis irradiance
data (2005-2023) and structured to meet the credibility bar expected by
development finance institutions such as ADB, the World Bank, and IFC.

**Stack:** Python (resource and statistical analysis) then SQL (relational
modeling and analytical queries) then Tableau (public interactive
visualization) then Power BI (DAX-driven scenario modeling).

*This analysis is independent and not affiliated with any government
body, financing institution, or project developer.*

---

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | 33 districts, 2005-2023, GHI trend and variability | Complete |
| Phase 2 | All 77 districts, P50-P99 exceedance, trough risk scoring, DSCR financial model | Complete |
| Phase 3 | Aerosol attribution (MERRA-2), NASA POWER cross-validation, Mann-Kendall/FDR trend re-test | Complete |
| SQL layer | Schema, staging load, DSCR fact load, 8 analytical queries (MySQL 8) | Complete |
| Tableau Public dashboard | Zone trend, district variability rankings, DSCR sensitivity tables | Complete |
| Power BI report | DAX measures, live what-if DSCR model, scenario-constrained sliders | Complete |

---

## Phase 1: GHI Trend and Variability Analysis (33 districts, 2005-2023)

| | |
|---|---|
| **Data source** | PVGIS ERA5, European Commission Joint Research Centre |
| **Coverage** | 33 districts across Nepal's Terai, Hill, and Mountain solar resource zones |
| **Period** | 2005 to 2023 |
| **Variable** | Global Horizontal Irradiance (GHI), Direct Normal Irradiance (DNI) |

### Key Finding

Nepal's annual solar resource is not stable. All 33 districts show
significant year-on-year variability across the 2005-2023 period.

The most important pattern is a sustained low-resource trough that
ran from roughly 2015 to 2021. During that period, most Terai and
Hill zones fell 8-13% below their 2005 baseline and stayed there.
Not for a single year. For approximately six consecutive years. The
resource recovered toward 2005 levels by 2022-2023.

The net change from 2005 to 2023 averages -1.4% across all 33
districts. Seven districts show a net gain. Twenty-six show a net
decline. The range is +2.5% (Jhapa, Eastern Terai) to -3.8% (Dolpa,
High Mountain). But the six-year trough is what matters for project
financing, not the 19-year average.

A project financed in 2010 using 2005-2010 historical GHI averages
as the yield basis would have received 8-13% less generation than
assumed every year from 2015 to 2021. Standard P50 yield estimates
do not model sustained multi-year resource troughs. This analysis
documents that such a trough happened.

### Phase 1 Charts

| Chart | Description |
|-------|-------------|
| `chart1_ghi_ranking.png` | Average annual GHI per district (2005-2023 mean), ranked highest to lowest, color-coded by zone |
| `chart2_zone_trends.png` | Annual GHI trend by zone, with linear regression lines and trough period marked |
| `chart3_ghi_decline.png` | Net GHI change per district from 2005 to 2023 endpoint |
| `chart4_monthly_heatmap.png` | Monthly GHI profile across all 33 districts |

### Phase 1 Data Files

| File | Description |
|------|-------------|
| `nepal_ghi_annual_by_district.csv` | Average annual GHI per district (2005-2023 mean) |
| `nepal_ghi_monthly_by_district.csv` | Average monthly GHI per district |
| `nepal_ghi_yearly_trend.csv` | Annual GHI per district per year (19-year series) |
| `nepal_ghi_decline_summary.csv` | Net change per district, 2005 vs 2023 endpoint |
| `nepal_ghi_variability.csv` | Inter-annual variability per district (coefficient of variation) |

### Phase 1 Methodology

- **API:** PVGIS v5.3 MRcalc endpoint
- **Database:** PVGIS-ERA5 (ECMWF reanalysis)
- **Parameters:** `horirrad=1` (GHI), `mr_dni=1` (DNI)
- **Spatial resolution:** ERA5 (~25 km grid). District centroids used as query points.
- **Temporal:** Monthly totals aggregated to annual totals per year.
- **Trend method:** Two approaches used together. First, endpoint comparison:
  percentage change from 2005 to 2023. Second, linear regression (OLS) slope
  over the full 19-year period, shown as dashed lines in Chart 2. Using both
  avoids the endpoint sensitivity problem of the comparison method alone.
- **Variability metric:** Coefficient of variation (CoV) = standard deviation
  divided by mean, expressed as a percentage over the 19-year period per district.

### Citation

Huld T., Muller R., Gambardella A. (2012). A new solar radiation database
for estimating PV performance in Europe and Africa. Solar Energy, 86(6),
1803-1815.

---

## Phase 2: National Coverage and Financial Risk Model (77 districts)

Phase 2 extends coverage to all 77 districts and moves from resource
characterization to financial risk quantification. It adds P50-P99
exceedance modeling, trough duration risk scoring, and a zone-level summary
across the full national dataset.

The 2015-2021 trough is independently validated through three statistical
tests: bootstrap resampling, a Wald-Wolfowitz runs test, and a permutation
test on run length, reconciled against a systematic enumeration of every
sustained below-average period in the 19-year record. An ENSO/ONI
correlation test (Pearson r = -0.137, p = 0.576) rules out that mechanism
as the trough's primary driver, leaving aerosol loading from the
Indo-Gangetic Plain as the as the attribution question tested directly in Phase 3, below. An inter-district correlation matrix (average pairwise r = 0.824) tests and substantiates the use of a system-wide resource basis in the financial model, while identifying specific districts (Humla, Mugu, Dolpa, Jumla) where correlation with the rest of the network is materially weaker and that basis does not hold as cleanly.

The financial core of Phase 2 is a two-scenario debt service coverage ratio
(DSCR) model: Scenario A represents Nepal's generation-1 solar cohort at
the pre-2022 regulated tariff (tariff range NPR 6.50-7.50/kWh, CAPEX
75-95M/MW, 12-year term), and Scenario B represents current projects
financed under competitive tariff bidding (approximately 2023-2026; tariff
range NPR 5.00-6.00/kWh, CAPEX 60-85M/MW, 15-year term), both tested at
75% debt across a CAPEX and tariff sensitivity grid, three resource cases
(P50, trough average, worst-year), and multiple project years (1, 5, 10)
to capture degradation. Every null or negative result, including the ENSO
test, the district-level risk-tier scoring that never classifies a
district above Low risk, and the marginal significance of the runs test,
is reported plainly rather than omitted.

### Phase 2 Data Files

| File | Description |
|------|-------------|
| `nepal_districts_lookup.csv` | District name, zone, latitude, longitude for all 77 districts |
| `nepal_ghi_yearly_trend_77.csv` | Annual GHI per district per year, national coverage |
| `nepal_ghi_p90_estimates_77.csv` | P50/P75/P90/P99 exceedance estimates per district |
| `nepal_ghi_variability_77.csv` | Mean, standard deviation, and CoV per district |
| `nepal_ghi_scenarios_77.csv` | Base/downside/stress resource scenarios per district |
| `nepal_oni_annual.csv` | Annual DJF Oceanic Nino Index, 2005-2023, for the ENSO correlation test |
| `nepal_dscr_full_77.csv` | DSCR results for both financing scenarios and their CAPEX/tariff sensitivity grids, long format |

### Phase 2 Charts

| Chart | Description |
|-------|-------------|
| `chart1_ghi_ranking_77.png` | Average annual GHI per district (2005-2023 mean), all 77 districts, ranked highest to lowest, color-coded by zone |
| `chart2_zone_trends_77.png` | Annual GHI trend and percent change from 2005 baseline by zone, all 77 districts, with the 2015-2021 trough period marked |
| `chart3_net_change_77.png` | Net GHI change per district from 2005 to 2023 endpoint, all 77 districts |
| `chart4_monthly_heatmap_77.png` | Monthly GHI profile across all 77 districts, ranked by annual GHI |
| `chart5_p90_ratio_77.png` | Annual P90/P50 GHI ratio by district, lower ratio indicating higher inter-annual resource risk |
| `chart5b_p90_monsoon_ratio_77.png` | Monsoon-season (Jun-Sep) P90/P50 GHI ratio by district, isolating cash-flow risk during the monsoon period specifically |
| `chart6_monthly_cov_heatmap_77.png` | Inter-annual coefficient of variation by month and district |
| `chart7a_dscr_heatmap_scenario_a.png` | DSCR sensitivity, tariff by CAPEX, Scenario A (generation-1, pre-2022 regulated tariff) |
| `chart7b_dscr_heatmap_scenario_b.png` | DSCR sensitivity, tariff by CAPEX, Scenario B (competitive tariff bidding, approximately 2023-2026) |
| `chart8_ghi_vs_enso.png` | System-wide GHI anomaly against the Oceanic Nino Index (ONI), dual-axis, testing ENSO as a driver of the 2015-2021 trough |
| `chart9_correlation_matrix.png` | Inter-district annual GHI anomaly correlation matrix, all 77 districts |


---

## Phase 3: Independent Validation of the 2015-2021 Trough

Phase 2 validated the 2015-2021 GHI trough through bootstrap resampling,
a Wald-Wolfowitz runs test, and a permutation test on run length, and
ruled out El Nino/La Nina cycles as a driver (ONI correlation
r = -0.137, p = 0.576). Phase 3 stress-tests the finding three further
ways: testing the remaining candidate physical driver (aerosol
loading), cross-checking the trough against a second, independently-
sourced dataset, and re-testing the underlying trend with a method that
corrects for the multiple-comparisons problem of running 77 independent
per-district significance tests.

**Aerosol attribution (NASA MERRA-2 AOD).** Same-year AOD vs. GHI
anomaly correlation is weak and non-significant (r = -0.136,
p = 0.579). Trough-period AOD (2015-2021 mean 0.3611) is not
significantly elevated relative to the rest of the record (mean 0.3487;
Welch's t = 1.403, p = 0.180). The causally relevant lag test, AOD
leading GHI by one year, is a clean null (r = 0.036, p = 0.887); the
one nominally significant raw result (AOD lagging GHI, p = 0.007) runs
in the wrong time direction for causality and weakens substantially
once both series are detrended (p = 0.084). Aerosol loading from the
Indo-Gangetic Plain is ruled out as the trough's primary driver, at the
same confidence tier as the ENSO test.

**Independent cross-validation (NASA POWER).** Every result up to this
point rested on one dataset, PVGIS ERA5. NASA POWER estimates solar
irradiance through a satellite radiative-transfer retrieval (CERES/
GEWEX SRB), a methodologically distinct approach from ERA5's data-
assimilation reanalysis. POWER's solar variables are not derived from
MERRA-2. ERA5 and POWER agree closely at the system level (r = 0.757,
p = 0.0002). POWER's own data independently confirms the trough: -3.19%
mean anomaly during 2015-2021 versus -0.44% for the remaining years
(Welch's t = -2.344, p = 0.034). At district level, 76 of 77 districts
individually show statistically significant agreement between the two
products (r ranging from 0.424 to 0.909); only one district sits above
the conventional significance threshold (p = 0.0705), and even there
the correlation is positive, not contradictory.

**Trend re-test, corrected for multiple comparisons (Mann-Kendall /
Sen's slope).** The Phase 1/2 trend figures (-1.4% for 33 districts,
-1.7% for 77) are two-point endpoint comparisons, sensitive to
whichever years sit at the record's start and end. A rank-based
Mann-Kendall test on the full 19-year system-wide series finds no
statistically significant monotonic trend (Tau = -0.228, p = 0.184), as expected, since a mid-record trough followed by recovery is a
different shape than a steady decline. Sen's slope estimates a -3.89
kWh/m²/year rate (-70.1 kWh/m² total over 18 intervals, 4.07% of the
2005 level). At district level, 10 of 77 districts show a
statistically significant individual trend before correction, close
to the ~3.9 expected by chance alone across 77 independent tests at
this threshold; after Benjamini-Hochberg false discovery rate
correction, zero districts remain significant, consistent with the
trough being a shared, system-wide event rather than a handful of
noisy districts.

**Synthesis: four independent tests, one finding.**

| Test | Tests whether the trough is... | Result |
|---|---|---|
| ENSO/ONI correlation (Phase 2) | ...driven by El Nino/La Nina | r = -0.137, p = 0.576 - ruled out |
| Aerosol loading (Phase 3) | ...driven by Indo-Gangetic aerosol | leading-year r = 0.036, p = 0.887 - ruled out |
| NASA POWER cross-validation (Phase 3) | ...an ERA5-specific artifact | r = 0.757, p = 0.0002; trough t = -2.344, p = 0.034 - confirmed independently |
| Mann-Kendall + FDR correction (Phase 3) | ...a multiple-testing false positive | 0 of 77 districts significant after correction - system-wide, not noise |

None of these tests identifies *why* the trough happened. That
remains an open question, and no recurrence probability is claimed.
Together, they establish that the trough is not a product of the
dataset used to detect it, not explained by either candidate physical
mechanism tested, and not an artifact of testing enough districts that
something looks significant by chance.

**Implication for forecasting.** ERA5 and NASA POWER are two of the
most widely used open-access sources for solar resource estimation,
built on different measurement methodologies (assimilation-based
reanalysis versus satellite radiative-transfer retrieval). Both
independently reproduce the same 2015-2021 trough. This does not
establish that the trough will recur, no mechanism has been confirmed,
but it does establish that the trough is not an artifact of choosing
one dataset over the other. A yield forecast built on either source
already carries this signal in its historical record. The practical
consequence: resource assessments drawing on ERA5 or NASA POWER should
test explicitly for sustained multi-year troughs, not rely on
single-year P50/P90 exceedance alone, since exceedance statistics do
not surface a multi-year, sub-baseline run the way a duration-based
test does.

### Phase 3 Data Files

| File | Description |
|------|-------------|
| `nepal_aerosol_aod_annual.csv` | Annual system-wide MERRA-2 AOD (550nm), 2005-2023, for the aerosol correlation test |
| `nepal_ghi_power_annual_77.csv` | NASA POWER annual GHI per district per year, national coverage, for cross-validation |
| `nepal_ghi_era5_vs_power_concordance_77.csv` | Per-district ERA5-vs-POWER correlation and significance |
| `nepal_ghi_mann_kendall_77.csv` | Per-district Mann-Kendall trend, Sen's slope, and FDR-corrected significance |

### Phase 3 Charts

| Chart | Description |
|-------|-------------|
| `chart10_ghi_vs_aod.png` | System-wide GHI anomaly against MERRA-2 aerosol optical depth (AOD), dual-axis, testing aerosol loading as a driver of the 2015-2021 trough |

## SQL Layer

The relational layer (`sql/nepal_solar_sql_layer_mysql.sql`) re-implements
the core Python analysis in MySQL 8: schema design, window functions
(`LAG`, `RANK`, moving averages), gaps-and-islands trough detection, and a
zone-level summary, to prove the same numbers hold up under a second,
independently-verified computation path. It also loads the full DSCR
sensitivity grid (`dim_dscr_scenario`, `fact_dscr_result`), so covenant
breaches can be queried directly in SQL rather than only read off the
Python heatmaps.

**Implementation note:** this layer is written for MySQL 8.0+.
MySQL has no native materialized view support, so `zone_summary`
is implemented as a standard `VIEW` (recomputes on query, at no noticeable
cost for 77 rows); empirical percentiles use `PERCENT_RANK()` rather than
`PERCENTILE_CONT()` for compatibility with MySQL builds prior to 8.0.31.
Query 3.5 also cross-checks the SQL-derived empirical percentile against the
Python notebook's parametric (normal-distribution) percentile. The two
methods disagree by roughly 0.3-1.3% on sampled districts, which is expected
given a 19-observation series feeding a tail estimate, and is documented
rather than reconciled away.

The DSCR staging table (`stg_dscr`) is defined explicitly rather than left
to the Import Wizard's type inference, so CAPEX, tariff, and DSCR figures
load as fixed-precision `DECIMAL` rather than float. `dim_dscr_scenario`
holds one row per distinct scenario definition (CAPEX, tariff, debt ratio,
interest rate, loan term); `fact_dscr_result` resolves `scenario_id` by
joining back to `dim_dscr_scenario` on those five defining columns.

**To reproduce:**
1. Run Part 1 of `sql/nepal_solar_sql_layer_mysql.sql` in MySQL Workbench
   (8.0+) to create the schema and 9 tables.
2. Import each Phase 2 CSV in `data/` as a staging table via Workbench's
   Table Data Import Wizard:
   - `nepal_districts_lookup.csv` into `stg_districts`
   - `nepal_ghi_yearly_trend_77.csv` into `stg_ghi_annual`
   - `nepal_ghi_p90_estimates_77.csv` into `stg_exceedance`
   - `nepal_ghi_variability_77.csv` into `stg_variability`
   - `nepal_ghi_scenarios_77.csv` into `stg_scenarios`
   - `nepal_oni_annual.csv` directly into the existing `fact_oni` table
   - `nepal_dscr_full_77.csv` into `stg_dscr`
3. Run the Part 2 `INSERT` statements to move staged data into the
   dimensional model, including the two-step `dim_dscr_scenario` /
   `fact_dscr_result` load.
4. Run the eight Part 3 queries. Results are saved in
   `sql/query_results/`.

---

## Tableau Public Dashboard

**Live:** https://public.tableau.com/app/profile/s.neupane/viz/NepalSolarResourceAnalysis-InteractiveDashboard/Dashboard

A zone-level trend chart shows percentage change in GHI from the 2005
baseline across Nepal's 13 solar resource zones (a physiographic
Mountain-Hill-Terai grouping used for this analysis, not an official
government classification), with the 2015-2021 trough period shaded for
reference. Two ranked bar charts show the 30 most and 30 least variable
districts by coefficient of variation. Two DSCR sensitivity tables (tariff
on rows, CAPEX on columns) show the covenant ratio across the full tested
grid for Scenario A and Scenario B, with a diverging color scale centered
near the 1.20 covenant line. Published as a static extract, so it renders
correctly with no dependency on the underlying MySQL database staying
online.

---

## Power BI Report

This report is not published via Power BI's "Publish to Web" feature.
Instead, the report is distributed two ways:

- **`powerbi/nepal_solar_dscr_model.pbix`**, the full interactive file.
  Anyone with Power BI Desktop (free) can open it and use the live DSCR
  tool as designed: Tariff, CAPEX, Project Year, and Resource Case
  selectors, with two scenario-specific parameter sets and a Reset to
  Defaults bookmark.
- **`powerbi/nepal_solar_dscr_model.pdf`**, a static export for anyone who
  wants to see the tool without installing Power BI Desktop. It captures
  the report's default view plus the Scenario A and Scenario B toggled
  states as separate pages. Sliders and buttons are not functional in this
  format.

DAX measures included: YoY GHI change, coefficient of variation, and
P90/P50 ratio, plus a live what-if DSCR model driven by Tariff, CAPEX,
Project Year, and Resource Case selectors.

Tariff and CAPEX parameters are scenario-specific. Scenario A is bounded
to its own tested grid (Tariff 6.50-7.50, CAPEX 75M-95M/MW), Scenario B to
its own (Tariff 5.00-6.00, CAPEX 60M-85M/MW). Two toggle buttons switch
between scenarios via bookmarks that swap both the active parameter set
and which slider pair is visible, so any tariff/CAPEX combination shown
under a given scenario sits inside that scenario's validated grid. Loan
term (12-year Scenario A, 15-year Scenario B) is applied automatically
inside the DSCR measure based on the selected scenario. A Reset to
Defaults bookmark restores Scenario A, Project Year 1, CAPEX 75M, Tariff
6.90, and the P50 resource case as the baseline view.

---

## Repository Structure

```
nepal-solar-resource-analysis/
├── Nepal_Solar_Resource_Analysis.ipynb
├── README.md
├── requirements.txt
├── data/
│   ├── nepal_ghi_annual_by_district.csv            (Phase 1, 33 districts)
│   ├── nepal_ghi_monthly_by_district.csv           (Phase 1, 33 districts)
│   ├── nepal_ghi_yearly_trend.csv                  (Phase 1, 33 districts)
│   ├── nepal_ghi_decline_summary.csv               (Phase 1, 33 districts)
│   ├── nepal_ghi_variability.csv                   (Phase 1, 33 districts)
│   ├── nepal_districts_lookup.csv                  (Phase 2, 77 districts)
│   ├── nepal_ghi_yearly_trend_77.csv               (Phase 2, 77 districts)
│   ├── nepal_ghi_p90_estimates_77.csv              (Phase 2, 77 districts)
│   ├── nepal_ghi_variability_77.csv                (Phase 2, 77 districts)
│   ├── nepal_ghi_scenarios_77.csv                  (Phase 2, 77 districts)
│   ├── nepal_oni_annual.csv                        (Phase 2, ENSO correlation test)
│   ├── nepal_dscr_full_77.csv                      (Phase 2c, DSCR scenarios and sensitivity grids)
│   ├── nepal_aerosol_aod_annual.csv                (Phase 3, MERRA-2 AOD)
│   ├── nepal_ghi_power_annual_77.csv               (Phase 3, NASA POWER cross-validation)
│   ├── nepal_ghi_era5_vs_power_concordance_77.csv  (Phase 3, per-district concordance)
│   └── nepal_ghi_mann_kendall_77.csv               (Phase 3, Mann-Kendall/FDR trend re-test)
├── scripts/
│   └── phase3_step1_merra2_extraction.py            (one-time, offline MERRA-2 download; not part of Restart & Run All)
├── charts/
│   ├── chart1_ghi_ranking.png                       (Phase 1)
│   ├── chart2_zone_trends.png                       (Phase 1)
│   ├── chart3_ghi_decline.png                       (Phase 1)
│   ├── chart4_monthly_heatmap.png                   (Phase 1)
│   ├── chart1_ghi_ranking_77.png                    (Phase 2)
│   ├── chart2_zone_trends_77.png                    (Phase 2)
│   ├── chart3_net_change_77.png                     (Phase 2)
│   ├── chart4_monthly_heatmap_77.png                (Phase 2)
│   ├── chart5_p90_ratio_77.png                      (Phase 2b)
│   ├── chart5b_p90_monsoon_ratio_77.png             (Phase 2b)
│   ├── chart6_monthly_cov_heatmap_77.png            (Phase 2b)
│   ├── chart7a_dscr_heatmap_scenario_a.png          (Phase 2c)
│   ├── chart7b_dscr_heatmap_scenario_b.png          (Phase 2c)
│   ├── chart8_ghi_vs_enso.png                       (Phase 2d)
│   ├── chart9_correlation_matrix.png                (Phase 2d)
│   └── chart10_ghi_vs_aod.png                       (Phase 3)
├── sql/
│   ├── nepal_solar_sql_layer_mysql.sql
│   └── query_results/
│       ├── 3.1_yoy_change.csv
│       ├── 3.2_rolling_3yr_avg.csv
│       ├── 3.3_net_change_ranked.csv
│       ├── 3.4_trough_duration.csv
│       ├── 3.5_empirical_p50_p90.csv
│       ├── 3.6_zone_summary.csv
│       ├── 3.7_dscr_breaches.csv
│       └── 3.8_ghi_vs_oni.csv
├── tableau/
│   ├── nepal_solar_dashboard.twbx (or tableau_dashboard_link.txt if the file is too large)as the attribution question tested directly in Phase 3, below
│   └── dashboard_screenshot.png
└── powerbi/
    ├── nepal_solar_dscr_model.pbix
    ├── nepal_solar_dscr_model.pdf
   └── dashboard_screenshot.png
---

## How to Run

```bash
pip install -r requirements.txt
jupyter notebook Nepal_Solar_Resource_Analysis.ipynb
```

No API key required. PVGIS ERA5 is a free public dataset.

For the SQL layer, see "To reproduce" above. Requires MySQL Workbench 8.0+.

For the Power BI report, open `powerbi/nepal_solar_dscr_model.pbix` in
Power BI Desktop (free), or view `powerbi/nepal_solar_dscr_model.pdf` for
a non-interactive preview.

---

## Data Source

European Commission, Joint Research Centre (JRC).
PVGIS ERA5 solar radiation database.
https://re.jrc.ec.europa.eu/pvg_tools/en/


NASA Langley Research Center (LaRC), POWER Project.
https://power.larc.nasa.gov/

NASA Global Modeling and Assimilation Office (GMAO).
MERRA-2 M2TMNXAER: 2d, Monthly Mean, Time-Averaged, Single-Level,
Assimilation, Aerosol Diagnostics.
https://disc.gsfc.nasa.gov/


---

*Phase 1 published; Phase 2, SQL layer, Tableau dashboard, Power BI
report, and Phase 3 added July 2026.*
