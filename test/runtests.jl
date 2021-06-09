using Stacks

const tests = [
    "nntopo",
]

Random.seed!(0)

@testset "Stacks" begin
  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end
end
