"""
Phase 3, Step 1: MERRA-2 aerosol data extraction.

Downloads MERRA-2 M2TMNXAER monthly granules to local disk before
reading them, rather than streaming over HTTP. Streaming makes
thousands of small byte-range requests per file, unreliable on a
slow or high-latency connection; downloading whole files first avoids
that, at the cost of roughly 200-400 MB local storage for the 228
monthly granules covering 2005-2023.

Requires EARTHDATA_USERNAME and EARTHDATA_PASSWORD set as environment
variables, and the "NASA GESDISC DATA ARCHIVE" application authorized
on the Earthdata account's Applications tab.

Package dependencies specific to this script, not part of the main
notebook's requirements.txt: earthaccess, xarray, netCDF4, h5netcdf,
h5py, dask.
"""
import earthaccess
import xarray as xr
import pandas as pd
import os

# ------------------------------------------------------------------
# 1. Authenticate (reads from environment variables)
# ------------------------------------------------------------------
earthaccess.login(strategy="environment")

# ------------------------------------------------------------------
# 2. Define bounding box and time range
# ------------------------------------------------------------------
BBOX = (74.0, 20.0, 92.0, 31.0)
START_DATE = "2005-01-01"
END_DATE = "2023-12-31"

# ------------------------------------------------------------------
# 3. Search for granules
# ------------------------------------------------------------------
results = earthaccess.search_data(
    short_name="M2TMNXAER",
    version="5.12.4",
    temporal=(START_DATE, END_DATE),
    bounding_box=BBOX,
)
print(f"Found {len(results)} monthly granules.")

# ------------------------------------------------------------------
# 4. Download to a local folder instead of streaming
# ------------------------------------------------------------------
DOWNLOAD_DIR = "data/merra2_raw"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

print(f"Downloading {len(results)} files to {DOWNLOAD_DIR}/ ...")
print("This can take a while. If it times out partway through, rerun this")
print("script; earthaccess skips files already on disk and resumes rather")
print("than starting over.")

local_files = earthaccess.download(results, DOWNLOAD_DIR)
print(f"\nDownload complete. {len(local_files)} local files ready.")

# ------------------------------------------------------------------
# 5. Open from local disk (fast, no network involved from here on)
# ------------------------------------------------------------------
ds = xr.open_mfdataset(local_files, combine="by_coords", engine="h5netcdf")
varnames = ["TOTEXTTAU", "BCEXTTAU", "DUEXTTAU", "SUEXTTAU", "OCEXTTAU"]
sub = ds[varnames].sel(
    lon=slice(BBOX[0], BBOX[2]),
    lat=slice(BBOX[1], BBOX[3]),
)

monthly_mean = sub.mean(dim=["lat", "lon"]).to_dataframe().reset_index()
monthly_mean["year"] = monthly_mean["time"].dt.year

annual = (
    monthly_mean.groupby("year")[varnames]
    .mean()
    .rename(columns={
        "TOTEXTTAU": "aod_total_550nm",
        "BCEXTTAU": "aod_black_carbon",
        "DUEXTTAU": "aod_dust",
        "SUEXTTAU": "aod_sulfate",
        "OCEXTTAU": "aod_organic_carbon",
    })
    .reset_index()
)

annual.to_csv("data/nepal_aerosol_aod_annual.csv", index=False)
print(annual)
print("\nSaved data/nepal_aerosol_aod_annual.csv")