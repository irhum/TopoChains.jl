module TopoChains

using Requires

export FuncTopo, @functopo_str, @functopo
export TopoChain

include("code.jl")
include("topology.jl")
include("topochain.jl")

function __init__()
    @require Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c" begin
        Flux.functor(s::TopoChain) = s.models, m -> TopoChain(s.topo, m...)
    end
end
end