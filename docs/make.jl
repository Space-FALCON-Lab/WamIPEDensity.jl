using Documenter
using WamIPEDensity

DocMeta.setdocmeta!(
    WamIPEDensity,
    :DocTestSetup,
    :(using WamIPEDensity, Dates);
    recursive=true,
)

makedocs(
    sitename="WamIPEDensity.jl",
    modules=[WamIPEDensity],
    repo=Documenter.Remotes.GitHub("Space-FALCON-Lab", "WamIPEDensity.jl"),
    checkdocs=:none,
    format=Documenter.HTML(
        # Set a canonical URL only after the lab Pages destination is selected.
        edit_link="develop",
        assets=["assets/custom.css"],
        prettyurls=get(ENV, "CI", "false") == "true",
    ),
    pages=[
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "WFS Workflows" => "wfs-workflows.md",
        "How It Works" => "how-it-works.md",
        "SpaceAGORA Status" => "spaceagora.md",
        "API Reference" => "api.md",
    ],
)

# Build only. Publishing requires a separate, explicit lab Pages destination.
