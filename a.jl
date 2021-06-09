using Stacks

using BenchmarkTools

topo = @nntopo ((x₁, y₁):x₁ => x₂:y₁ => y₂:(x₂, y₂) => f) => 8

a = rand(5000)
b = rand(5000)

topo(repeat([x -> x.^2, x -> x.^3, (x, y) -> x .- y], 8), a, b)