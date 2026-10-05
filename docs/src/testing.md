# Testing

## Strict local checks

CI uses a separate test environment and runs on Julia 1.11 and 1.12.
From the repository root:

```bash
julia --project=test -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=test test/ci.jl
```

The first command installs dependencies and may access package servers. The
second strictly precompiles the package and runs deterministic tests with
local inputs. A compilation error or failed assertion fails the job. The
tracked root Manifest is not used to resolve the separate test environment.

| File | Coverage |
|---|---|
| `test/test_offline.jl` | Public exports, constructors, argument validation, cache helpers, cycle routing, MSIS and hybrid wrappers. |
| `test/test_archive_queries.jl` | Tiny generated NetCDF files: packed values, fill values, dimension permutations, metre/kilometre coordinates, temporal interpolation, public single/batch/trajectory queries, and mean density profiles. |
| `test/test_loading_interfaces.jl` | MSIS-only density interface, trajectory angle conversion, and preserved API aliases. |

`test/offline_indices.jl` generates synthetic constant space-weather rows and
loads them through the SpaceIndices file API. It then marks the test process
as initialised so the wrappers do not fetch indices. The atmospheric model
itself is not mocked. The hybrid tests seed known GEOS altitude bounds to
avoid downloading a GEOS file solely to choose the MSIS backend. These
fixtures test code behaviour and units; they do not validate real space
weather, GEOS fields, forecast accuracy, or an atmospheric campaign.

The archive tests seed the file-pair cache with small local NetCDF fixtures.
They do not download NOAA files. Known numerical expectations verify that CF
scale and offset are applied once and that filled cells remain missing.
Temporary files and open dataset handles are cleaned up after the tests.

## Optional live-data campaign

The existing `test/runtests.jl` campaign and root `test_smoke.jl` remain
available. They need live space-weather and/or NOAA/NASA services, and the
full campaign includes multi-day trajectories and benchmarks:

```bash
julia --project=test test/runtests.jl
```

Some campaign testsets catch unavailable downloads and report a skip.
Those skips are not evidence of successful archive retrieval or scientific
validation. Record the actual files, dates, source revision, skipped cases,
and environment when using campaign output as validation evidence.

## GitHub Actions

The `Tests` workflow runs the strict local suite for pull requests and pushes
to `main` or `develop`, with separate Julia 1.11 and 1.12 jobs. Both jobs must
pass for this repair to be considered CI-verified.

The full live-data campaign is a separate manual workflow option,
`run_network_tests`, disabled by default. Selecting it runs the existing
campaign without `continue-on-error`; inspect any self-reported skips as
well as the job result. This avoids making routine pull-request checks
launch large archive downloads or numerical campaigns.
