using AdaptiveFilters
using Documenter

makedocs(;
    modules=[AdaptiveFilters],
    authors="Fredrik Bagge Carlson",
    repo="https://github.com/baggepinnen/AdaptiveFilters.jl/blob/{commit}{path}#L{line}",
    sitename="AdaptiveFilters.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://baggepinnen.github.io/AdaptiveFilters.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/baggepinnen/AdaptiveFilters.jl",
)
