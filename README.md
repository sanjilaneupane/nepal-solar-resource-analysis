# Nepal Solar Resource Analysis
## Phase 1: GHI Trend and Variability Analysis for 33 Districts (2005-2023)
| | |
|---|---|
| **Data source** | PVGIS ERA5, European Commission Joint Research Centre |
| **Coverage** | 33 districts across Nepal's Terai, Hill, and Mountain solar resource zones |
| **Period** | 2005 to 2023 |
| **Variable** | Global Horizontal Irradiance (GHI), Direct Normal Irradiance (DNI) |

---

## Key Finding

Nepal's annual solar resource is not stable. All 33 districts show
significant year-on-year variability across the 2005-2023 period.

The most important pattern is a sustained low-resource trough that
ran from roughly 2015 to 2021. During that period, most Terai and
Hill zones fell 10-13% below their 2005 baseline and stayed there.
Not for a single year. For approximately seven consecutive years. The
resource recovered toward 2005 levels by 2022-2023.

The net change from 2005 to 2023 averages -1.4% across all 33
districts. Seven districts show a net gain. Twenty-six show a net
decline. The range is +2.5% (Jhapa, Eastern Terai) to -3.8% (Dolpa,
High Mountain). But the seven-year trough is what matters for project
financing, not the 19-year average.

Most of Nepal's utility scale solar projects were commissioned between
2020 and 2023, confirmed against the DOED licensing registry. A project 
financed on pre-trough historical resource averages would have received 
10-13% less generation than assumed every year from 2015 to 2021. Standard 
P50 yield estimates do not model sustained multi-year resource troughs. This
analysis documents that such a trough happened.

---

## Charts

| Chart | Description |
|-------|-------------|
| `chart1_ghi_ranking.png` | Average annual GHI per district (2005-2023 mean), ranked highest to lowest, color-coded by zone |
| `chart2_zone_trends.png` | Annual GHI trend by zone, with linear regression lines and trough period marked |
| `chart3_ghi_decline.png` | Net GHI change per district from 2005 to 2023 endpoint |
| `chart4_monthly_heatmap.png` | Monthly GHI profile across all 33 districts |

---

## Data Files

| File | Description |
|------|-------------|
| `nepal_ghi_annual_by_district.csv` | Average annual GHI per district (2005-2023 mean) |
| `nepal_ghi_monthly_by_district.csv` | Average monthly GHI per district |
| `nepal_ghi_yearly_trend.csv` | Annual GHI per district per year (19-year series) |
| `nepal_ghi_decline_summary.csv` | Net change per district, 2005 vs 2023 endpoint |
| `nepal_ghi_variability.csv` | Inter-annual variability per district (coefficient of variation) |

---

## Methodology

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

---

## Citation

Huld T., Muller R., Gambardella A. (2012). A new solar radiation database
for estimating PV performance in Europe and Africa. Solar Energy, 86(6),
1803-1815.

---

## Repository Structure

```
nepal-solar-resource-analysis/
├── Nepal_Solar_Resource_Analysis.ipynb
├── README.md
├── requirements.txt
├── data/
│   ├── nepal_ghi_annual_by_district.csv
│   ├── nepal_ghi_monthly_by_district.csv
│   ├── nepal_ghi_yearly_trend.csv
│   ├── nepal_ghi_decline_summary.csv
│   └── nepal_ghi_variability.csv
└── charts/
    ├── chart1_ghi_ranking.png
    ├── chart2_zone_trends.png
    ├── chart3_ghi_decline.png
    └── chart4_monthly_heatmap.png

```


---

## How to Run

```bash
pip install requests pandas matplotlib seaborn numpy scipy
jupyter notebook Nepal_Solar_Resource_Analysis.ipynb
```

No API key required. PVGIS ERA5 is a free public dataset.

---

## Data Source

European Commission, Joint Research Centre (JRC).
PVGIS ERA5 solar radiation database.
https://re.jrc.ec.europa.eu/pvg_tools/en/

---

## Phase Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | 33 districts, 2005-2023, GHI trend and variability | Complete |
| Phase 2 | All 77 districts, baseline sensitivity analysis | Planned |
| Phase 3 | Aerosol attribution using MERRA-2 AOD data | Planned |

*This analysis is independent and not affiliated with any government
body, financing institution, or project developer.*