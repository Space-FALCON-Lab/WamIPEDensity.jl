# WamIPEDensity.jl

**The maintained implementation is on [`develop`](https://github.com/Space-FALCON-Lab/WamIPEDensity.jl/tree/develop).**
This `main` branch preserves the historical 0.9.5 source and does not contain the
October 2026 fixes. Use the lab repository's `develop` branch for installation
and new work; the two branches have separate histories.

WamIPEDensity.jl provides Julia access to NOAA WAM-IPE neutral-density data.
See the [maintained documentation sources](https://github.com/Space-FALCON-Lab/WamIPEDensity.jl/tree/develop/docs/src)
for the current API and standalone query examples.

## Installation

Use Julia 1.11 or 1.12 and the maintained `develop` branch of the lab repository:

```sh
git clone --branch develop https://github.com/Space-FALCON-Lab/WamIPEDensity.jl.git
cd WamIPEDensity.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

To add the maintained package to an existing Julia project instead:

```julia
using Pkg
Pkg.add(url="https://github.com/Space-FALCON-Lab/WamIPEDensity.jl.git", rev="develop")
```

From the checkout, start Julia with its project active before running the query
examples:

```sh
julia --project=.
```

If you added the package to another project, run that command from that project's
directory instead. Keep using this Julia session for the query examples.

The changelog below describes this historical branch.

## Contributors

- [Giusy Falcone](https://github.com/gfalcon2)
- [Tarun Ramireddy](https://github.com/Bourbon8464)

## Changelog:
### Updates to Structure and Exports:
- Changed `WAMInterpolator` to have:
    - `root_prefix` field (now supports v1.1 and v1.2)
    - `interpolation` now accepts `:nearest`, `:linear`, `:logz_linear`, `:logz_quadratic`, `:sciml`
- Added an explicit export for `get_density`, `get_density_batch` and `WAMInterpolator`
- Renamed the default variable name from `rho` to `den` to match NOAA NetCDF files

### Updates to AWS and File Access:
- Refactored `_open_nc_from_s3`:
    - Implemented a cache system instead of temperory `.nc` files that gets removed immediately
    - Falls back from `AWSS3.s3_get` to `HTTP.get` streaming if needed
- Added a persistent LRU disk cache in `./cache` 
- Added: `print_cache_stats()` for debugging cache size, usage, and eviction

### Cache System:
- Added: `_FileCache` struct with:
    - Directory, max size, lock, LRU order, active downloads, and serialized metadata
    - Added a persistent `metadata.bin` file to restore cache state between sessions

### Code Handling:
- Added a `_VERSION_WINDOWS` mapping for `v1.1` and `v1.2` depending on time
- Added `_model_for_version()` mapping (`wam10` for v1.2, `gsm10` for v1.1)
- Added Archive rules:
    - `_wrs_archive(dt)` and `_wfs_archive(dt)` to pick correct cycle hours
- Added `_construct_s3_key()` to build exact NOAA S3 paths with timestamps
- Added `_product_fallback_order()` to switch between `wfs`/`wrs` products if one is missing

### Grid and Dataset Loading:
- Refactored `_load_grids()`:
    - Now supports 3D (lon,lat,z) and 4D (lon,lat,z,time) datasets
    - For 3D, synthesises a fake `time` axis from file timestamp

### Time Handling:
- Added `_datetime_floor_10min` and `_surrounding_10min` to snap queries to 10-minute intervals
- Added `_decode_time_units` and `_encode_query_time` for converting between NetCDF time axes and DateTime
- Added `_parse_valid_time_from_key()` to parse valid times directly from filenames (`YYYYMMDD_HHMMSS.nc`)

### Public API:
- get_density()
    - Now automatically finds two nearest files
    - Performs spatial interpolation on each file, then linear interpolation in time between them
- get_density_batch()
    - Vectorised version for multiple times/locations
- get_density_from_key()
    - Loads a specific NetCDF file by its S3 key (or cached version)
- url_to_key()
    - Converts full NOAA HTTPS URL into S3 key (e.g. `v1.2/wfs.../file.nc`)

### Error Handling:
- Added `_validate_query_args()` checks interpolation mode, latitude bounds, finite values, and altitude > 0 km

---

## For Tarun - Documentation and debugging of code:

```
print("\033c") 
using Revise
using WamIPEDensity, Dates

itp = WAMInterpolator(; product="wfs", root_prefix="v1.2", varname="den", interpolation=:sciml)

dt  = DateTime(2024, 5, 11, 18, 12, 22)
lat, lon, alt = -33.4, -153.24, 550.68 
den = get_density(itp, dt, lat, lon, alt) 
@show den

```


```
print("\033c") 
using Revise
using WamIPEDensity, Dates

itp = WAMInterpolator(product="wrs", varname="den", interpolation=:sciml)

dt = DateTime(2024, 5, 11, 18, 12, 22)

lat, lon, alt = -33.4, -153.24, 550.68  # deg N, deg E, km

dt_array = [dt + Minute(10)*i for i in 0:9]

lat_array = fill(lat, length(dt_array))
lon_array = fill(lon, length(dt_array))
alt_array = fill(alt, length(dt_array))

densities = get_density_batch(itp, dt_array, lat_array, lon_array, alt_array)

println("Densities (kg/m^3):")
for (ti, val) in zip(dt_array, densities)
    println("At ", ti, " the density value is ", val)
end

```


