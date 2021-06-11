# Advanced Uses

### Interpolation
We also support interpolation, so you can use a variable to hold a substructure or the unroll number. But **notice** that the interpolation variable should always be at the top level of the module since we can only get that value with `eval`. (To interpolate local variables, use `@nntopo_str "topo_pattern"` instead)

```julia
N = 3
topo = @nntopo((e, m, mask):e → pe:(e, pe) → t → (t:(t, m, mask) → t:(t, m, mask)) → $N:t → c)

# alternatively
# topo = @nntopo_str "(e, m, mask):e → pe:(e, pe) → t → (t:(t, m, mask) → t:(t, m, mask)) → $N:t → c"

print_topo(topo)
# 
# NNTopo{"(e, m, mask):e → (pe:(e, pe) → (t → ((t:(t, m, mask) → t:(t, m, mask)) → (3:t → c))))"}
# topo_func(model, e, m, mask)
#         pe = model[1](e)
#         t = model[2](e, pe)
#         t = model[3](t)
#         t = model[4](t, m, mask)
#         t = model[5](t, m, mask)
#         t = model[6](t, m, mask)
#         c = model[7](t)
#         c
# end
```

### Collect Variables

You can also collect intermediate variables you are interested in with `'` on that variable. This allows you to define and train a model, and only make changes to its structure (and not the layers of the model itself) if you need access to intermediate outputs for downstream tasks. For example:

```julia
julia> @nntopo x => y' => 3 => z
# NNTopo{"x => (y' => (3 => z))"}
# topo_func(model, x)
#         y = model[1](x)
#         %1 = y
#         y = model[2](y)
#         %2 = y
#         y = model[3](y)
#         %3 = y
#         y = model[4](y)
#         %4 = y
#         z = model[5](y)
#         (z, (%1, %2, %3, %4))
# end

julia> @nntopo (x,y) => (a,b,c,d') => (w',r',y) => (m,n)' => z
# NNTopo{"(x, y) => ((a, b, c, d') => ((w', r', y) => (((m, n))' => z)))"}
# topo_func(model, x, y)
#         (a, b, c, d) = model[1](x, y)
#         %1 = d
#         (w, r, y) = model[2](a, b, c, d)
#         %2 = (w, r)
#         (m, n) = model[3](w, r, y)
#         %3 = (m, n)
#         z = model[4](m, n)
#         (z, (%1, %2, %3))
# end
```