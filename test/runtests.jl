using TopoChains

using Test 

const tests = [
    "functopo", "topochain",
]

@testset "TopoChains" begin
  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end
end
