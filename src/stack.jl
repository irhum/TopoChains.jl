using MacroTools: @forward, postwalk

"""
    Stack(topo::NNTopo, layers...)

Similar to a Flux.Chain, with the addition of the use of an NNTopo to define the order/structure of the functions called.

# Example
```jldoctest
julia> topo = @nntopo (x1, x2):x1 => a:x2 => b:(a, b) => c => o

julia> model = Stack(topo,
                Dense(32, 64),
                Dense(32, 64),
                (x, y) -> x .* y, 
                Dropout(0.1))

Stack(Dense(32, 64), Dense(32, 64), #19, Dropout(0.1)) representing the following function composition: 
function(x1, x2)
    a = Dense(32, 64)(x1)
    b = Dense(32, 64)(x2)
    c = #19(a, b)
    o = Dropout(0.1)(c)
    o
end
```
"""
struct Stack{T<:Tuple, FS}
    models::T
    topo::NNTopo{FS}
    Stack(topo::NNTopo{FS}, xs...) where FS = new{typeof(xs), FS}(xs, topo)
end

@generated function (s::Stack{TP, FS})(xs...) where {TP, FS}
    _code = nntopo_impl(FS)
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

@forward Stack.models Base.getindex, Base.length

function Base.show(io::IO, s::Stack)
    print(io, "Stack(")
    join(io, s.models, ", ")
    print(io, ") representing the following function composition: \n")
    print_topo(io, s.topo; models=s.models)
end

"show the structure of the Stack function"
show_stackfunc(s::Stack) = print_topo(s.topo; models=s.models)
