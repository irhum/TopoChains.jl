# Stacks.jl

*Adapted from [Transformers.jl](https://chengchingwen.github.io/Transformers.jl/dev/stacks/)*

Stacks.jl allows you to cleanly build flexible neural networks whose layers can take any number of inputs, and produce any number of outputs. It achieves this by seperating the *layers* themselves from the *structure* of the inputs/outputs the layers take in/produce. To accomplish this, this package provides two core features:
* `@nntopo`: A macro that uses a compact DSL (Domain Specific Language) to store the *structure* of the function composition in an `NNTopo`.
* `Stack`: Similar to a `Flux.Chain`, except it takes in an `NNTopo` as its first argument to determine which inputs to pass into each layer.  

## NNTopo
We store the structure of the model in a `NNTopo`, short for "Neural Network Topology". At its core, it is simply used to define inputs and outputs for each function in a sequence of function calls. Consider it a supercharged version of Julia's piping operator (`|>`). 

`NNTopo`s are usually created by using the `@nntopo` macro, and its syntax is best explained through examples.

### Chaining functions

Suppose you want to chain the functions `g`, `f` and `h` in the following way:

```julia
y = h(f(g(x))) # a chain of function calls
```

You could instead write the following:

```
julia
# or equivalently
a = g(x)
b = f(a)
y = h(b)
```

Or you could take the Stacks.jl approach, which is to seperate the *structure* from the *functions*:
```
julia
topo = @nntopo x => a => b => y # first we define the topology/architecture
y = topo((g, f, h), x) # then call on the given functions
```

First, we create `topo` (which has type `NNTopo`) using `@nntopo`. The inputs to `@nntopo` are parsed in the following way:
* Each variable name (e.g `b`) is a symbol that represents a function input/output. Note that these symbols have no relation with globally defined variables (in the same way that `a` in `f(a) = a^2` has no relation with a previously defined `a` in the Julia session)
* Each `=>` represents a function call, with the left hand side being the input argument and right hand side being the symbol used to represent the output. 

Note that `@nntopo` simply creates the *structure* of the function calls; it does not actually *perform* the function calls until the generated `NNTopo` struct is called with concrete functions (in this case `(g, f, h)`)

### Multiple arguments & skip connections

As we metioned above, the original intention was to handle the case that we multiple inputs and multiple outputs. We can do this with the following syntax: 

```julia
# a complex structure
# x1 to x4 in the given inputs
t = f(x1, x2)
z1, z2 = g(t, x3)
w = h(x4, z1)
y = k(x2, z2, w)

# is equivalent to 
topo = @nntopo (x1, x2, x3, x4):(x1, x2) => t:(t, x3) => (z1, z2):(x4, z1) => w:(x2, z2, w) => y
y = topo((f, g, h, k), x1, x2, x3, x4)

# you can also see the function call order with `print_topo` function
print_topo(topo; models=(f, g, h, k))
# 
# NNTopo{"(x1, x2, x3, x4):(x1, x2) => (t:(t, x3) => ((z1, z2):(x4, z1) => (w:(x2, z2, w) => y)))"}
# topo_func(model, x1, x2, x3, x4)
#         t = f(x1, x2)
#         (z1, z2) = g(t, x3)
#         w = h(x4, z1)
#         y = k(x2, z2, w)
#         y
# end
```

### Seperating inputs and outputs
Notice that we use a `:` to seperate the input/output variable names for each function call. If the `:` is not present, we will by default assume that all output variables are the inputs of the next function call. i.e. `x => (t1, t2) => y` is equivalent to `x => (t1, t2):(t1, t2) => y`. 

We can also return multiple variables, so the complete syntax can be viewed as:
    
        (input arguments):(function1 inputs) => (function1 outputs):(function2 inputs):(function2 outputs) => .... => (function_n outputs):(return variables)

### Loop unrolling

you can also unroll a loop:

```julia
y = g(f(f(f(f(x)))))

# or 
tmp = x
for i = 1:4
  tmp = f(tmp)
end
y = g(tmp)

# is equivalent to 
topo = @nntopo x => 4 => y
y = topo((f,f,f,f, g), x) 
```

### Nested Structure

You can also use the `()` to create a nested structure for the unroll.

```julia
topo = @nntopo x => ((y => z => t) => 3 => w) => 2
print_topo(topo)
# 
# NNTopo{"x => (((y => (z => t)) => (3 => w)) => 2)"}
# topo_func(model, x)
#         y = model[1](x)
#         z = model[2](y)
#         t = model[3](z)
#         z = model[4](t)
#         t = model[5](z)
#         z = model[6](t)
#         t = model[7](z)
#         w = model[8](t)
#         z = model[9](w)
#         t = model[10](z)
#         z = model[11](t)
#         t = model[12](z)
#         z = model[13](y)
#         t = model[14](z)
#         w = model[15](t)
#         w
# end
```

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

## Stack

With the NNTopo DSL, we can use the NNTopo with our Stack type, which is like `Flux.Chain` except that we also need to pass in the `NNTopo` for the architecture. You can check the actual function call with `show_stackfunc`, which integrates `print_topo` with the actual names of the layers in the Stack.

```julia
# An example Decoder (from Attention Is All You Need)

using Transformers

N = 3

Stack(
@nntopo((e, m, mask):e → pe:(e, pe) → t → (t:(t, m, mask) → t:(t, m, mask)) → $N:t → c),
PositionEmbedding(512),
(e, pe) -> e .+ pe,
Dropout(0.1),
[TransformerDecoder(512, 8, 64, 2048) for i = 1:N]...,
Positionwise(Dense(512, length(labels)), logsoftmax)
)

julia> show_stackfunc(s)
# topo_func(model, e, m, mask)
#         pe = PositionEmbedding(512)(e)
#         t = getfield(Main, Symbol("##23#25"))()(e, pe)
#         t = Dropout{Float64}(0.1, true)(t)
#         t = TransformerDecoder(head=8, head_size=64, pwffn_size=2048, size=512, dropout=0.1)(t, m, mask)
#         t = TransformerDecoder(head=8, head_size=64, pwffn_size=2048, size=512, dropout=0.1)(t, m, mask)
#         t = TransformerDecoder(head=8, head_size=64, pwffn_size=2048, size=512, dropout=0.1)(t, m, mask)
#         c = Positionwise{Tuple{Dense{typeof(identity),TrackedArray{…,Array{Float32,2}},TrackedArray{…,Array{Float32,1}}},typeof(logsoftmax)}}((Dense(512, 12), NNlib.logsoftmax))(t)
#         c
# end
```


