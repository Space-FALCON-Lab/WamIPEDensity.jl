using Test, Dates

@testset "Connected backend interfaces" begin
    dt = DateTime(2024, 5, 15, 12)
    lat, lon = 45.0, -75.0
    @testset "MSIS-only public API" begin
        model = NRLMSISEOnlyInterpolator(latitude=lat, longitude=lon, date=dt,
                                         solar_flux=150.0, geomag_index=4.0)
        expected = WamIPEDensity.SatelliteToolboxAtmosphericModels.AtmosphericModels.nrlmsise00(
            dt, 400000.0, deg2rad(lat), deg2rad(lon), 150.0, 150.0, 4.0).total_density
        @test expected > 0
        @test nrlmsise00(400, lat, lon, dt, 150, 4) ≈ expected rtol=1e-12
        @test get_density(model, 400000, lat, lon, dt) ≈ expected rtol=1e-12
        @test get_density(model, -6000, lat, lon, dt) == 0.0
        @test get_density(model, 1100000, lat, lon, dt) ≈ nrlmsise00(1000, lat, lon, dt, 150, 4) rtol=1e-12
        @test get_density(model, -1000, lat, lon, dt) ≈ nrlmsise00(-1, lat, lon, dt, 150, 4) rtol=1e-12
        @test_throws ArgumentError get_density(model, NaN, lat, lon, dt)
        @test_throws ArgumentError nrlmsise00(400, 91, lon, dt, 150, 4)
    end
    @testset "GEOS trajectory entry point" begin
        itp = GEOSFPInterpolator()
        @test isempty(get_density_trajectory(itp, DateTime[], Float64[], Float64[], Float64[]))
    end
    @testset "Trajectory units and aliases" begin
        msis = NRLMSISEInterpolator(max_alt_km=500)
        hybrid = HybridDensityInterpolator(msis=msis, msis_max_alt_km=500)
        hybrid.geos_bounds_cache[WamIPEDensity._datetime_floor_3hr(dt)] = (0.0, 70.0)
        for itp in (msis, hybrid)
            expected = get_density(itp, dt, lat, lon, 400.0)
            for query in (get_density_trajectory, get_density_trajectory_optimised,
                          get_density_trajectory_optimized)
                @test only(query(itp, [dt], [deg2rad(lat)], [deg2rad(lon)], [400000.0])) ≈ expected rtol=1e-12
                @test only(query(itp, [dt], [lat], [lon], [400000.0]; angles_in_deg=true)) ≈ expected rtol=1e-12
            end
            @test only(get_density_batch_optimized(itp, [dt], [lat], [lon], [400.0])) ≈ expected rtol=1e-12
            @test only(get_density_batch_parallel(itp, [dt], [lat], [lon], [400.0])) ≈ expected rtol=1e-12
        end
    end
end
