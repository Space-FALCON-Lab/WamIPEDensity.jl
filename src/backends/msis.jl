# backends/msis.jl - NRLMSISE-00 backend.
# Empirical density model (Naval Research Laboratory Mass Spectrometer
# and Incoherent Scatter Radar Exosphere, 2000 version).

# --------------------------------------------------------------------------
# One-time index initialisation
# --------------------------------------------------------------------------

function _init_msis_indices!(itp::NRLMSISEInterpolator)
    lock(_MSIS_INIT_LOCK) do
        _MSIS_INITIALIZED[] && return nothing
        try
            SpaceIndices.init()
        catch err
            @warn "SpaceIndices.init() failed; NRLMSISE-00 may still work with explicit indices." exception=(err, catch_backtrace())
        end
        _MSIS_INITIALIZED[] = true
        return nothing
    end
end

# --------------------------------------------------------------------------
# Single-point density
# --------------------------------------------------------------------------

"""
    get_density(itp::NRLMSISEInterpolator, dt, lat, lon, alt_km) -> Float64

Return density from the NRLMSISE-00 empirical model. Default window
0-100 km; widen with `NRLMSISEInterpolator(min_alt_km=0.0, max_alt_km=...)`.
Degrees, kilometres. Triggers a one-time space-weather index download
under a module-level lock on first call.
"""
function get_density(itp::NRLMSISEInterpolator, dt::DateTime,
                    latq::Real, lonq::Real, alt_km::Real)
    _validate_query_args_msis(itp, dt, latq, lonq, alt_km)
    _init_msis_indices!(itp)
    out = SatelliteToolboxAtmosphericModels.AtmosphericModels.nrlmsise00(
        dt, alt_km * 1000.0, deg2rad(float(latq)), deg2rad(float(lonq))
    )
    return float(out.total_density)
end

# --------------------------------------------------------------------------
# Batch and trajectory
# --------------------------------------------------------------------------

"""
    get_density_batch(itp::NRLMSISEInterpolator, dts, lats, lons, alts_km)
        -> Vector{Float64}

Vector-form NRLMSISE-00 density query.
"""
function get_density_batch(itp::NRLMSISEInterpolator,
                           dts::AbstractVector{<:DateTime},
                           lats::AbstractVector,
                           lons::AbstractVector,
                           alts_km::AbstractVector)
    n = length(dts)
    @assert length(lats) == n == length(lons) == length(alts_km)
    results = Vector{Float64}(undef, n)
    Threads.@threads for i in 1:n
        results[i] = get_density(itp, dts[i], lats[i], lons[i], alts_km[i])
    end
    return results
end

get_density_trajectory(itp::NRLMSISEInterpolator, dts, lats, lons, alts_m; angles_in_deg=false) =
    get_density_batch(itp, dts,
        (angles_in_deg ? Float64.(lats) : rad2deg.(Float64.(lats))),
        (angles_in_deg ? Float64.(lons) : rad2deg.(Float64.(lons))), Float64.(alts_m) .* 1e-3)

get_density_trajectory_optimised(itp::NRLMSISEInterpolator, dts, lats, lons, alts_m; angles_in_deg=false) =
    get_density_trajectory(itp, dts, lats, lons, alts_m; angles_in_deg=angles_in_deg)

# --------------------------------------------------------------------------
# Point helper
# --------------------------------------------------------------------------

"""
    get_density_at_point(itp::NRLMSISEInterpolator, dt, lat, lon, alt_m;
                         angles_in_deg=false) -> Float64

Single-point NRLMSISE-00 query in orbit-propagator units (metres, radians).
"""
function get_density_at_point(itp::NRLMSISEInterpolator, dt::DateTime,
                             lat::Real, lon::Real, alt_m::Real;
                             angles_in_deg::Bool=false)
    lat_d = angles_in_deg ? float(lat) : rad2deg(float(lat))
    lon_d = angles_in_deg ? float(lon) : rad2deg(float(lon))
    alt_k = float(alt_m) * 1e-3
    return get_density(itp, dt, lat_d, lon_d, alt_k)
end

# --------------------------------------------------------------------------
# Cache prewarm
# --------------------------------------------------------------------------

"""
    prewarm_cache!(itp::NRLMSISEInterpolator, dts) -> Int

NRLMSISE-00 is an empirical model with no on-disc file cache - this method
exists for API completeness and returns `0` unconditionally.
"""
function prewarm_cache!(itp::NRLMSISEInterpolator, dts::AbstractVector{<:DateTime})
    _init_msis_indices!(itp)
    return 0
end

"""
    nrlmsise00(alt_km, lat, lon, time, f107, ap)

Density in kg/m^3 from the installed Julia NRLMSISE-00 model, with altitude
in kilometres and angles in degrees. The supplied solar flux is used for
both daily and mean F10.7. No space-index download is needed.
"""
function nrlmsise00(alt_km::Real, lat::Real, lon::Real, time::DateTime,
                   f107::Real, ap::Real)
    isfinite(alt_km) || throw(ArgumentError("altitude must be finite"))
    isfinite(lat) && -90 <= lat <= 90 || throw(ArgumentError("latitude must be in [-90, 90]"))
    isfinite(lon) || throw(ArgumentError("longitude must be finite"))
    isfinite(f107) && f107 > 0 || throw(ArgumentError("solar flux must be positive and finite"))
    isfinite(ap) && ap >= 0 || throw(ArgumentError("Ap must be nonnegative and finite"))
    out = SatelliteToolboxAtmosphericModels.AtmosphericModels.nrlmsise00(
        time, Float64(alt_km) * 1000, deg2rad(Float64(lat)), deg2rad(Float64(lon)),
        Float64(f107), Float64(f107), Float64(ap))
    return Float64(out.total_density)
end

function get_density(interp::NRLMSISEOnlyInterpolator, altitude_m::Real,
                     lat::Real, lon::Real, time::DateTime)
    alt_km = Float64(altitude_m) / 1000
    isfinite(alt_km) || throw(ArgumentError("altitude must be finite"))
    alt_km < interp.min_alt_km && return 0.0
    # Preserve the existing configured floor and 1000 km ceiling.
    alt_km = clamp(alt_km, interp.min_alt_km, 1000.0)
    return nrlmsise00(alt_km, lat, lon, time, interp.solar_flux, interp.geomag_index)
end
