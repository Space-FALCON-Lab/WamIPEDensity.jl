module WamIPEDensity

using Dates
using Printf
using Statistics
using AWS
using AWSS3
using NCDatasets
using HTTP
using DataInterpolations
using Serialization
using CommonDataModel
using Plots
import SatelliteToolbox
import SatelliteToolboxAtmosphericModels
using LinearAlgebra
import SpaceIndices

# EXPORTS

export WAMInterpolator, GEOSFPInterpolator, NRLMSISEInterpolator, HybridDensityInterpolator,
       NRLMSISEOnlyInterpolator, nrlmsise00,
       density, leo_config, lower_atmo_config,
       get_density, get_density_batch, get_density_at_point,
       get_density_trajectory, get_density_trajectory_optimised, mean_density_profile,
       plot_global_mean_profile, plot_global_mean_profile_plots,
       prewarm_cache!, set_max_open_datasets!, print_cache_stats, clear_grid_cache!,
       get_density_batch!, get_density_batch_optimized, get_density_batch_parallel,
       get_density_trajectory_optimized, set_download_concurrency!, clear_nc_pool!, clean_cache!,
       inspect_geos_file, inspect_geos_remote_file

# Load each implementation once, in dependency order.
include("types.jl")
include("time_utils.jl")
include("io.jl")
include("cache.jl")
include("interpolation.jl")
include("downloads.jl")
include("backends/wam.jl")
include("backends/geos.jl")
include("backends/msis.jl")
include("backends/hybrid.jl")
include("api.jl")
include("profile.jl")
include("diagnostics.jl")

end # module
