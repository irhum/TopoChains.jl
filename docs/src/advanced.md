# Advanced Uses

## Collect Variables

You can collect intermediate variables you are interested in with `'` on that variable. This allows you to define and train a model, and only make changes to its structure (and not the layers of the model itself) if you need access to intermediate outputs for downstream tasks (e.g. style transfer using a pretrained CNN). For example:

```julia
julia> @functopo (x,y) => (a,b,c,d') => (w',r',y) => (m,n)' => z
# FuncTopo{"(x, y) => ((a, b, c, d') => ((w', r', y) => (((m, n))' => z)))"}
# function(model, x, y)
#     (a, b, c, d) = model[1](x, y)
#     %1 = d
#     (w, r, y) = model[2](a, b, c, d)
#     %2 = (w, r)
#     (m, n) = model[3](w, r, y)
#     %3 = (m, n)
#     z = model[4](m, n)
#     (z, (var"%1", var"%2", var"%3"))
# end
```

## Interpolation
TopoChains.jl supports interpolation, so you can use a variable to hold a substructure or the unroll number. 
!!! note
    The interpolation variable should always be at the top level of the module since we can only get that value with `eval`. (To interpolate local variables, use `@functopo_str "topo_pattern"` instead)

```@docs
@functopo_str
```

```julia
N = 3

topo = @functopo (y => (z1, z2) => t) => $N

# alternatively
# topo = @functopo_str "(y => (z1, z2) => t) => $N"

topo
# FuncTopo{"(y => ((z1, z2) => t)) => 3"}
# function(model, y)
#     (z1, z2) = model[1](y)
#     t = model[2](z1, z2)
#     (z1, z2) = model[3](t)
#     t = model[4](z1, z2)
#     (z1, z2) = model[5](t)
#     t = model[6](z1, z2)
#     t
# end
```

