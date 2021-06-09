using Stacks

using Test 

const tests = [
    "nntopo",
]

@testset "Stacks" begin
  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end
end
