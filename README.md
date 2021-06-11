# TopoChains.jl

<p align="center">
<img width="400px" src="https://raw.githubusercontent.com/irhum/TopoChains.jl/master/docs/src/assets/logo.png"/>
</p>

[![][docs-dev-img]][docs-dev-url]

TopoChains.jl provides a new data structure, a `TopoChain`, which picks up where Flux.jl's `Chain` left off. Unlike a `Chain`, which is designed for a sequential single-input single-output use case, a `TopoChain` can handle multi-input multi-output compositions of layers and functions. We achieve this by seperately specifying the *topology* (that is, the structure) of a model from the actual *layers* of a model. Check the [docs][docs-dev-url] for more!

The `TopoChain` was originally designed as the `Stack`, as part of [Transformers.jl](https://github.com/chengchingwen/Transformers.jl) by Peter Cheng, and is repackaged here into a standalone package for general purpose use.

### Installation

For the time being, the package can be installed with 
```
] add https://github.com/irhum/TopoChains.jl
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://irhum.github.io/TopoChains.jl/dev/
