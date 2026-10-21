# Contributing

Start from the maintained `develop` branch. Keep each change focused, explain the
problem it fixes, and update the relevant examples or API documentation with it.
For a change to the public API, dependency set or cache/concurrency design, open
an issue and agree on the approach with a maintainer before implementing it.

## Prepare a checkout

Use Julia 1.11 or 1.12. From a directory where you keep source checkouts:

```sh
git clone --branch develop https://github.com/Space-FALCON-Lab/WamIPEDensity.jl.git
cd WamIPEDensity.jl
```

Use your fork's URL if you intend to submit a pull request. Run the commands below
from this repository root; the test and documentation environments are separate.

## Run the strict local checks

```sh
julia --project=test -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=test test/ci.jl
```

Dependency setup may access package servers. The second command strictly
precompiles the package and runs the local interface, generated archive and
offline checks. Any compilation error or failed assertion must be addressed.
See [Testing](testing.md) for the files and limits of these fixtures.

The live-data campaign is optional and can download substantial NOAA/NASA data:

```sh
julia --project=test test/runtests.jl
```

Record skipped cases separately from successful checks. A passing run with
unavailable-data skips does not demonstrate archive access or scientific validity.
Use the separate test environment rather than substituting the root environment.

## Build the documentation

Use Julia 1.12 for the checked-in documentation manifest, from the repository root:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Open `docs/build/index.html` and check the changed page and its links. Local and CI
builds do not publish the site. Markdown lives in `docs/src`; the API reference
renders docstrings from the implementation.

## Project layout

```
src/
  WamIPEDensity.jl          # Main module. Includes implementation files and exports the API.
  types.jl                  # Struct definitions: WAMInterpolator, GEOSFPInterpolator,
                            # NRLMSISEInterpolator, HybridDensityInterpolator,
                            # GridMetadata, _FileCache, and all global constants.
  time_utils.jl             # DateTime helpers, version mapping, S3 key construction.
  io.jl                     # NetCDF helpers, CF decode, per-thread dataset pool,
                            # grid metadata loader.
  cache.jl                  # On-disc LRU file cache with serialised metadata,
                            # time-bucket pair cache, clean_cache!, print_cache_stats.
  interpolation.jl          # 3-D / 4-D separable interpolation (linear,
                            # log-z, SciML quadratic) and WAM-IPE core evaluator.
  downloads.jl              # AWS configuration, bounded-concurrency downloader.
  backends/
    wam.jl                  # WAM-IPE backend: file resolution, density, batch, trajectory.
    geos.jl                 # GEOS-FP backend: density reconstruction via
                            # hydrostatic integration, altitude bounds cache.
    msis.jl                 # NRLMSISE-00 backend via SatelliteToolbox.
    hybrid.jl               # Altitude-routing hybrid: GEOS -> MSIS -> WAM.
  api.jl                    # Public top-level API: density(), leo_config(),
                            # lower_atmo_config(), batch wrappers.
  profile.jl                # Global-mean density profile and Plots.jl helpers.
  diagnostics.jl            # GEOS-FP file inspection helpers.
test/
  runtests.jl                # Full test suite (some testsets need S3 access)
  ci.jl                      # Strict precompile plus three local test files
  test_offline.jl            # Constructors, validation, routing and helpers
  Project.toml               # Test-only deps
docs/
  make.jl                    # Documenter build script; publication is not configured
  src/*.md                    # Markdown source for the docs site
.github/workflows/
  docs.yml                    # Builds docs without publishing
  test.yml                    # Strict local tests; optional manual live campaign
  TagBot.yml                  # Julia registry tag automation
```

## Preserve the interface and data conventions

- Keep existing exported names available through a documented deprecation when
  renaming or removing them. Prefer optional keywords to new required arguments.
- Preserve units and coordinate conventions. In particular, point/batch queries
  use kilometres and degrees, while trajectory helpers accept metres and an
  explicit radians/degrees choice.
- Preserve identifier spelling: `get_density_trajectory_optimised` and
  `get_density_batch_optimized` are existing public names.
- Keep interpolation warnings visible unless a reviewed change alters their
  meaning. Do not use log-level changes to hide a failing query.
- Underscore-prefixed implementation helpers are not a stable downstream API.
  Files included by the main module share its namespace; they do not need exports
  merely to call one another.

## Changes requiring design review

Cache and NetCDF concurrency changes need explicit ownership and lifetime checks.
The current implementation already uses per-thread dataset handles; that alone
is not a general guarantee about the underlying C libraries. Review handle use,
locking and cleanup together, and exercise concurrent access before making a
thread-safety claim.

The `get_density_batch_optimized` and `get_density_batch_parallel` entry points
currently delegate to `get_density_batch`. Preserve their call signatures when
changing the shared implementation. Review trajectory grouping separately rather
than assuming that every entry point has a distinct algorithm.

A lighter GEOS altitude-bounds lookup must retain the existing missing-height and
hydrostatic-fill behaviour. Propose its validation before replacing the current
full-field loading path.

## Submit the change

Describe the failure or user need, the resulting behaviour, and the exact checks
run. Include the Julia version and identify any live-data skips. Keep unrelated
cleanup in separate pull requests. Contributions use the repository's MIT license.
