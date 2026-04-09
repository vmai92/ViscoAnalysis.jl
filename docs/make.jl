using Documenter
using ViscoAnalysis

makedocs(
    sitename = "ViscoAnalysis.jl",
    authors  = "Van Than MAI",
    modules  = [ViscoAnalysis],
    pages = [
        "Home"            => "index.md",
        "Getting Started" => "getting_started.md",
        "Theory"          => "theory.md",
        "API Reference"   => [
            "Data I/O"  => "api/io.md",
            "Models"    => "api/models.md",
            "Fitting"   => "api/fitting.md",
            "Plotting"  => "api/plotting.md",
        ],
    ],
    warnonly = true,
)

deploydocs(
    repo      = "github.com/vmai92/ViscoAnalysis.jl.git",
    devbranch = "main",
)
