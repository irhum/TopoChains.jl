module Stacks

using Requires

export NNTopo, @nntopo_str, @nntopo
export Stack, show_stackfunc

include("code.jl")
include("topology.jl")
include("stack.jl")

function __init__()
    @require Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c" begin
        Flux.functor(s::Stack) = s.models, m -> Stack(s.topo, m...)
    end
end
end
