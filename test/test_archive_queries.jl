# Deterministic archive regressions. Load WamIPEDensity before including this file.
# Fixtures are tiny local NetCDF files; no NOAA data or credentials are required.
using Test, Dates, NCDatasets

const WAM_ARCHIVE = WamIPEDensity

function archive_fixture(path; packed=false, permuted=false, fourdim=false,
                         fill_only=false, height_units="km", density_factor=1.0)
    NCDataset(path, "c") do ds
        for name in ("lon", "lat", "height")
            defDim(ds, name, 2)
        end
        lon = defVar(ds, "lon", Float64, ("lon",); attrib=Dict("units" => "degrees_east"))
        lat = defVar(ds, "lat", Float64, ("lat",); attrib=Dict("units" => "degrees_north"))
        height = defVar(ds, "height", Float64, ("height",); attrib=Dict("units" => height_units))
        lon[:] = [0.0, 360.0]
        lat[:] = [-10.0, 10.0]
        height[:] = height_units == "m" ? [400000.0, 500000.0] : [400.0, 500.0]
        dims = permuted ? ("height", "lon", "lat") : ("lon", "lat", "height")
        raw = [10i + 20j + 40k for i in 1:2, j in 1:2, k in 1:2]
        permuted && (raw = permutedims(raw, (3, 1, 2)))
        if fourdim
            defDim(ds, "time", 1)
            time = defVar(ds, "time", Float64, ("time",))
            time[:] = [0.0]
            dims = (dims..., "time")
            raw = reshape(raw, (size(raw)..., 1))
        end
        if packed
            v = defVar(ds, "den", Int16, dims; attrib=Dict(
                "scale_factor" => density_factor * 1e-14, "add_offset" => density_factor * 1e-12,
                "_FillValue" => Int16(-32768), "missing_value" => Int16(-32767)))
            v.var[:] = fill_only ? fill(Int16(-32768), size(raw)) : Int16.(raw)
        else
            v = defVar(ds, "den", Float64, dims)
            v[:] = density_factor .* (1e-12 .+ raw .* 1e-14)
        end
    end
    return path
end

@testset "Archive density regressions" begin
    @testset "WFS cycle and calendar boundaries" begin
        for (dt, expected) in [
            (DateTime(2025,6,6,0), DateTime(2025,6,6,0)),
            (DateTime(2025,6,6,3), DateTime(2025,6,6,0)),
            (DateTime(2025,6,6,5,59,59), DateTime(2025,6,6,0)),
            (DateTime(2025,6,6,6), DateTime(2025,6,6,6)),
            (DateTime(2025,6,6,11,59), DateTime(2025,6,6,6)),
            (DateTime(2025,6,6,12), DateTime(2025,6,6,12)),
            (DateTime(2025,6,6,18), DateTime(2025,6,6,18)),
            (DateTime(2025,12,31,23,59), DateTime(2025,12,31,18)),
            (DateTime(2026,1,1), DateTime(2026,1,1)),
        ]
            @test WAM_ARCHIVE._wfs_archive(dt) == expected
        end
        @test WAM_ARCHIVE._construct_s3_key(DateTime(2025,6,6,3), "wfs") ==
            "v1.2/wfs.20250606/00/wam_fixed_height.wfs.t00z.wam10.20250606_030000.nc"
        @test WAM_ARCHIVE._construct_s3_key(DateTime(2025,12,31,23,50), "wfs") ==
            "v1.2/wfs.20251231/18/wam_fixed_height.wfs.t18z.wam10.20251231_235000.nc"
    end

    @testset "Metadata and density decoding" begin
        mktempdir() do dir
            for (name, opts) in [
                ("plain", (;)),
                ("packed", (;packed=true)),
                ("reordered", (;packed=true, permuted=true)),
                ("fourdim", (;packed=true, permuted=true, fourdim=true, height_units="m")),
            ]
                @testset "$name" begin
                    path = archive_fixture(joinpath(dir, name * ".nc"); opts...)
                    NCDataset(path) do ds
                        meta = WAM_ARCHIVE._load_grid_metadata(ds, "den")
                        @test meta.lon_is_360
                        @test meta.z == [400.0, 500.0]
                        @test meta.ndims == (get(opts, :fourdim, false) ? 4 : 3)
                        # The eight raw corners have mean 105: decode once.
                        @test WAM_ARCHIVE._get_density_wam_core(meta, 180.0, 0.0, 450.0) ≈ 2.05e-12 rtol=1e-12
                        @test WAM_ARCHIVE._get_density_wam_core(meta, -180.0, 0.0, 450.0) ≈ 2.05e-12 rtol=1e-12
                        if get(opts, :packed, false)
                            @test WAM_ARCHIVE._decode_value(100.0, meta) ≈ 2e-12 rtol=1e-12
                            @test isnan(WAM_ARCHIVE._decode_value(-32768.0, meta))
                            @test isnan(WAM_ARCHIVE._decode_value(-32767.0, meta))
                            @test isnan(WAM_ARCHIVE._decode_value(NaN, meta))
                        end
                    end
                end
            end
            path = archive_fixture(joinpath(dir, "missing.nc"); packed=true, fill_only=true)
            NCDataset(path) do ds
                meta = WAM_ARCHIVE._load_grid_metadata(ds, "den")
                @test isnan(WAM_ARCHIVE._get_density_wam_core(meta, 180.0, 0.0, 450.0))
            end
        end
    end

    @testset "Public archive APIs with cached local files" begin
        for fourdim in (false, true)
            mktempdir() do dir
                dt = DateTime(2025, 6, 6, 0, 5)
                paths = [joinpath(dir, "wam_fixed_height.wfs.t00z.wam10.20250606_$(stamp).nc")
                         for stamp in ("000000", "001000")]
                for (i, path) in enumerate(paths)
                    archive_fixture(path; packed=true, permuted=true, fourdim=fourdim,
                                    height_units="m", density_factor=Float64(i))
                end
                itp = WAMInterpolator()
                WAM_ARCHIVE._cache_file_pair(itp, dt, (paths[1], paths[2]))
                try
                    expected = 3.075e-12
                    @test get_density(itp, dt, 0.0, 180.0, 450.0) ≈ expected rtol=1e-12
                    @test get_density_at_point(itp, dt, 0.0, pi, 450000.0) ≈ expected rtol=1e-12
                    @test get_density_batch(itp, [dt, dt], [0.0, 0.0], [180.0, -180.0], [450.0, 450.0]) ≈ [expected, expected] rtol=1e-12
                    @test only(get_density_trajectory(itp, [dt], [0.0], [pi], [450000.0])) ≈ expected rtol=1e-12
                    @test only(get_density_trajectory_optimised(itp, [dt], [0.0], [180.0], [450000.0]; angles_in_deg=true)) ≈ expected rtol=1e-12
                    heights, profile = mean_density_profile(itp, dt)
                    @test heights == [400.0, 500.0]
                    @test profile ≈ [2.775e-12, 3.375e-12] rtol=1e-12

                    # The same timestamp can legitimately have different WFS
                    # and WRS files. One product must not reuse the other's pair.
                    wrs_paths = replace.(paths, "wfs" => "wrs")
                    for (i, path) in enumerate(wrs_paths)
                        archive_fixture(path; packed=true, permuted=true, fourdim=fourdim,
                                        height_units="m", density_factor=2.0 * i)
                    end
                    wrs = WAMInterpolator(product="wrs")
                    WAM_ARCHIVE._cache_file_pair(wrs, dt, (wrs_paths[1], wrs_paths[2]))
                    @test get_density(wrs, dt, 0.0, 180.0, 450.0) ≈ 2expected rtol=1e-12
                    @test get_density(itp, dt, 0.0, 180.0, 450.0) ≈ expected rtol=1e-12
                finally
                    WAM_ARCHIVE.clear_nc_pool!()
                    WAM_ARCHIVE.clear_grid_cache!()
                    empty!(WAM_ARCHIVE._TIME_BUCKET_CACHE)
                end
            end
        end
    end

    @testset "Retained log-altitude interpolation" begin
        interp = WAM_ARCHIVE._sciml_quad_logz
        @test isnan(interp([100.0], [NaN], 100.0))
        @test interp([100.0], [2e-12], 500.0) == 2e-12
        @test interp([200.0, 50.0], [4e-12, 1e-12], 100.0) ≈ 2e-12 rtol=1e-12
        @test interp([200.0, 50.0], [4e-12, 1e-12], 25.0) ≈ 1e-12 rtol=1e-12
        @test interp([200.0, 50.0], [4e-12, 1e-12], 400.0) ≈ 4e-12 rtol=1e-12
        @test interp([50.0, 100.0, 200.0], [1e-12, 2e-12, 4e-12], 100.0) ≈ 2e-12 rtol=1e-12
    end
end
