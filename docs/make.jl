using Documenter
using TopoChains

makedocs(
    sitename = "TopoChains",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [TopoChains]
)

deploydocs(
    repo = "https://github.com/irhum/topochains.jl"
)
