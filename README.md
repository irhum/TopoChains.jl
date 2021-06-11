# TopoChains.jl

<p align="center">
<img width="300px" src="/docs/src/assets/logo.png"/>
</p>

[![][docs-dev-img]][docs-dev-url]

TopoChains.jl provides a new data structure, a `TopoChain`, which picks up where Flux.jl's `Chain` left off. Unlike a `Chain`, which is designed for a sequential single-input single-output use case, a `TopoChain` can handle multi-input multi-output compositions of layers and functions. We achieve this by seperately specifying the *topology* (that is, the structure) of a model from the actual *layers* of a model. Check the [docs][docs-dev-url] for more!

The `TopoChain` was originally designed as the `Stack`, as part of [Transformers.jl](https://github.com/chengchingwen/Transformers.jl) by Peter Cheng, and is repackaged here into a standalone package for general purpose use.


### Usage
Suppose you want to define the following model:

<p align="center">
<img width="275px" src="/docs/src/assets/example2.png"/>
</p>

First, we define the structure of the model:
```julia
topo = @functopo x:x => a:x => b:(a, b) => c => o
```

Then we define the model itself:
```julia
model = TopoChain(topo,
            Dense(32, 64),
            Dense(32, 64),
            (x, y) -> x .* y, 
            Dropout(0.1))
```

And that's it, you're done! You can see that the model both contains your layers, as well as information on how to run the layers:

```julia
model
# TopoChain(Dense(32, 64), Dense(32, 64), #7, Dropout(0.1)) representing the following function composition: 
# function(x)
#     a = Dense(32, 64)(x)
#     b = Dense(32, 64)(x)
#     c = #7(a, b)
#     o = Dropout(0.1)(c)
#     o
# end
```

`TopoChain` is a drop-in replacement for a `Chain`, which means all the features of `Chain`, such as parameter collection, indexing, layer slicing, etc. will work as intended.

### Installation

For the time being, the package can be installed with 
```
] add https://github.com/irhum/TopoChains.jl
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://irhum.github.io/TopoChains.jl/dev/
