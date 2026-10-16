# SpaceAGORA Status

WamIPEDensity supports standalone density queries that can be used alongside a
SpaceAGORA simulation. The [SpaceAGORA source checked on 2026-10-16](https://github.com/Space-FALCON-Lab/SpaceAGORA.jl/tree/1204744fd292a0e4634cca1aa2a7bab5b27fff51)
does not provide `SpaceAGORA.WAMIPEDensityAtmosphereModel`. Installing this
package does not register an atmosphere adapter with SpaceAGORA.

Use the [Quick Start](quickstart.md) to install the maintained `develop` branch
and query the package directly. A future adapter requires a separate
implementation and validation against SpaceAGORA's atmosphere interface.

## Query data alongside a simulation

The public WamIPEDensity methods expose the following units:

| Method | Time | Latitude and longitude | Altitude |
| --- | --- | --- | --- |
| `get_density` | UTC `DateTime` | degrees | kilometres |
| `get_density_batch` | UTC `DateTime` values | degrees | kilometres |
| `get_density_trajectory_optimised` | UTC `DateTime` values | radians by default; degrees with `angles_in_deg=true` | metres |

Convert a simulation's elapsed seconds to physical UTC times using its mission
epoch, and convert positions to the units required by the selected query method.
The package does not perform those conversions on behalf of a SpaceAGORA run.
See the [API Reference](api.md) for the method signatures.

WAM-IPE density queries return neutral mass density in kg/m³. They do not supply
a complete atmosphere state for a force model: temperature, wind and any other
required quantities need an explicit model choice in a future integration.

For separate WFS ionosphere-variable queries, see [WFS Workflows](wfs-workflows.md).
Those programs are independent of a SpaceAGORA atmosphere adapter.
