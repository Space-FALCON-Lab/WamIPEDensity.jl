# WamIPEDensity.jl

`WamIPEDensity.jl` is the density-focused WAM-IPE access layer used by Space Falcon Lab tooling. It downloads NOAA WAM-IPE NetCDF products, keeps them in a local cache, interpolates them in space and time, and exposes a small Julia API for point, batch, and trajectory density queries.

Use the maintained `develop` branch of the
[lab repository](https://github.com/Space-FALCON-Lab/WamIPEDensity.jl/tree/develop);
`main` preserves an older implementation. This package supports standalone
density queries and explicit data analysis alongside SpaceAGORA runs. A built-in
SpaceAGORA atmosphere adapter is not currently available; see
[SpaceAGORA status](spaceagora.md).

The examples below use UTC `DateTime` values, latitude and longitude in degrees, and altitude in kilometres unless noted otherwise.

```julia
using Dates
using WamIPEDensity

itp = WAMInterpolator(product="wfs", varname="den", interpolation=:sciml)
dt = DateTime(2025, 9, 30, 18, 12, 22)

rho = get_density(itp, dt, -33.4, -153.24, 400.0)
```

## What the package provides

- `WAMInterpolator`: configuration for the NOAA WAM-IPE forecast or nowcast product.
- `get_density`: one density value at one time and location.
- `get_density_batch`: repeated point queries.
- `get_density_trajectory_optimised`: trajectory queries grouped by the required WAM-IPE files.
- `GEOSFPInterpolator`, `NRLMSISEInterpolator`, and `HybridDensityInterpolator`: optional model paths for lower atmosphere, empirical atmosphere, and altitude-aware hybrid use cases.

The first query may download NOAA files into `./cache`, relative to the Julia
working directory. The result is density in kg/m³; use the Quick Start to prepare
the environment before running this example.

## Pages

- [Quick Start](quickstart.md): installation and standalone examples.
- [WFS Workflows](wfs-workflows.md): independent `WFS` tools that require a separate installation.
- [How It Works](how-it-works.md): cache, file selection, interpolation, and trajectory flow.
- [SpaceAGORA Status](spaceagora.md): standalone queries alongside a simulation.
- [Backends](backends.md): model selection, altitude limits and data requirements.
- [Testing](testing.md): strict local checks and optional live-data campaigns.
- [Contributing](contributing.md): development workflow and documentation build.
- [API Reference](api.md): generated reference for public functions and types.
