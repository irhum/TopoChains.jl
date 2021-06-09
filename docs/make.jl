using Documenter, Stacks

makedocs(sitename="Stacks.jl",
         pages = Any[
           "Home" => "stacks.md",
         ],
         )

deploydocs(
    repo = "github.com/irhum/Stacks.jl.git",
)
