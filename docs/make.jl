using Documenter
using Stacks

makedocs(
    sitename = "Stacks",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [Stacks]
)

deploydocs(
    repo = "https://github.com/irhum/Stacks.jl"
)
