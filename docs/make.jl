using Documenter
using ViscoAnalysis

makedocs(
    sitename = "ViscoAnalysis.jl",
    authors  = "Van Than MAI",
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical  = "https://Van-Than-MAI.github.io/ViscoAnalysis.jl",
    ),
    modules = [ViscoAnalysis],
    pages = [
        "Home"            => "index.md",
        "Getting Started" => "getting_started.md",
        "Theory"          => "theory.md",
        "API Reference"   => [
            "Data I/O"     => "api/io.md",
            "Models"       => "api/models.md",
            "Fitting"      => "api/fitting.md",
            "Plotting"     => "api/plotting.md",
        ],
    ],
    checkdocs = :exports,
    warnonly  = true,
)

deploydocs(
    repo   = "github.com/Van-Than-MAI/ViscoAnalysis.jl.git",
    branch = "gh-pages",
)
