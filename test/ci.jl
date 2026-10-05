# Loading normally also checks package precompilation (including method overwrites).
using Pkg
Pkg.precompile(["WamIPEDensity"]; strict=true)
using WamIPEDensity
include("test_offline.jl")
include("test_archive_queries.jl")
include("test_loading_interfaces.jl")
