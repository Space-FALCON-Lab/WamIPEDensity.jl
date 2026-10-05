# Synthetic constant space weather for deterministic wrapper tests, not a
# scientific validation dataset. Initialise through SpaceIndices' file API.
import SpaceIndices

function load_offline_indices!()
    mktempdir() do dir
        path = joinpath(dir, "space-weather.csv")
        open(path, "w") do io
            println(io, join(("column_$i" for i in 1:31), ","))
            for date in Date(2024, 1, 1):Day(1):Date(2024, 8, 31)
                row = Any[string(date), 1, 1, fill(10, 8)..., 80,
                          fill(4, 8)..., 4, 0.0, 0, 0, 150.0, 150.0,
                          "OBS", 150.0, 150.0, 150.0, 150.0]
                println(io, join(row, ","))
            end
        end
        SpaceIndices.init(SpaceIndices.Celestrak; filepaths=[path])
    end
    # The index download boundary is deliberately bypassed after loading
    # the local fixture. The atmospheric model itself is not mocked.
    WamIPEDensity._MSIS_INITIALIZED[] = true
end
