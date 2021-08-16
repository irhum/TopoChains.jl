module TopoChains

using Functors

export FuncTopo, @functopo_str, @functopo
export TopoChain

include("code.jl")
include("topology.jl")
include("topochain.jl")

Functors.functor(s::TopoChain) = s.models, m -> TopoChain(s.topo, m...)

end
