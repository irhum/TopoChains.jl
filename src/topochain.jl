using MacroTools: @forward, postwalk

"""
    TopoChain(topo::FuncTopo, layers...)

Similar to a Flux.Chain, with the addition of the use of an FuncTopo to define the order/structure of the functions called.

# Example
```jldoctest
julia> topo = @functopo x:x => a:x => b:(a, b) => c => o

julia> model = TopoChain(topo,
                Dense(32, 64),
                Dense(32, 64),
                (x, y) -> x .* y, 
                Dropout(0.1))

TopoChain(Dense(32, 64), Dense(32, 64), #5, Dropout(0.1)) representing the following function composition: 
function(x)
    a = Dense(32, 64)(x)
    b = Dense(32, 64)(x)
    c = #5(a, b)
    o = Dropout(0.1)(c)
    o
end
```
"""
struct TopoChain{T<:Tuple, FS}
    models::T
    topo::FuncTopo{FS}
    TopoChain(topo::FuncTopo{FS}, xs...) where FS = new{typeof(xs), FS}(xs, topo)
end

@generated function (s::TopoChain{TP, FS})(xs...) where {TP, FS}
    _code = functopo_impl(FS)
    n = fieldcount(TP)
    ms = [Symbol(:__model, i, :__) for i = 1:n]
    head = Expr(:(=), Expr(:tuple, ms...), :(s.models))
    pushfirst!(_code.args, head)
    code = postwalk(_code) do x
        if x isa Expr && x.head === :ref && x.args[1] === :model
            i = x.args[2]
            y = :($(ms[i]))
            return y
        else
            x
        end
    end
    return code
end

@forward TopoChain.models Base.getindex, Base.length

function Base.show(io::IO, s::TopoChain)
    print(io, "TopoChain(")
    join(io, s.models, ", ")
    print(io, ") representing the following function composition: \n")
    print_topo(io, s.topo; models=s.models)
end

"show the structure of the TopoChain function"
show_topochainfunc(s::TopoChain) = print_topo(s.topo; models=s.models)
