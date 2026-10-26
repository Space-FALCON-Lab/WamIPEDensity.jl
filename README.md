# WamIPEDensity.jl

WamIPEDensity.jl provides Julia access to NOAA WAM-IPE neutral-density data,
including point, batch and trajectory queries. It also exposes GEOS-FP, MSIS and
hybrid model interfaces.

**`develop` is the maintained branch of the [Space Falcon Lab repository](https://github.com/Space-FALCON-Lab/WamIPEDensity.jl).**
The default `main` branch preserves historical 0.9.5 source on a separate
history and does not contain the October 2026 fixes. Base new work on `develop`.

Use the [Quick Start](docs/src/quickstart.md) for standalone queries. The
[SpaceAGORA status page](docs/src/spaceagora.md) explains how to use these queries
alongside a simulation; a built-in SpaceAGORA adapter is not currently available.

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

## Choose a workflow

- [Quick Start](docs/src/quickstart.md): install the package and query density.
- [Backends](docs/src/backends.md): choose a model and check its altitude limits, data requirements and routing.
- [How It Works](docs/src/how-it-works.md): understand file selection, interpolation and caching.
- [Testing](docs/src/testing.md): run the strict local checks or an optional live-data campaign.
- [Contributing](docs/src/contributing.md): prepare a focused change.
- [Changelog](CHANGELOG.md): retained implementation and release history.

WAM-IPE and GEOS-FP queries download data when it is missing from the local cache.
MSIS may need space-weather indices. A successful software test is not a validation
of a forecast or of a model for a particular mission.

## Build the documentation

The documentation sources live in `docs/`. From the repository root, build them
with Julia 1.12, matching the checked-in documentation manifest:

```julia
using Pkg
Pkg.activate("docs")
Pkg.develop(path=".")
Pkg.instantiate()
include("docs/make.jl")
```

After building, open `docs/build/index.html`. Local and CI builds do not publish
the site. The lab Pages destination and canonical URL still need to be selected
before a separate publication change; this repository does not redirect the
previous personal site.
