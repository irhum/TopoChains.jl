# Stacks.jl

<p align="center">
<img width="400px" src="https://raw.githubusercontent.com/irhum/Stacks.jl/master/docs/src/assets/logo.png"/>
</p>

[![][docs-dev-img]][docs-dev-url]

Stacks.jl provides a new data structure, a Stack, which picks up where Flux.jl's Chain left off. Unlike a Chain, which is designed for a sequential single-input single-output use case, a Stack can handle multi-input multi-output compositions of layers and functions. We achieve this by seperating the *structure* of a model from the actual *layers* of a model. Check the [docs][docs-dev-url] for more!

The Stack was originally designed as part of [Transformers.jl](https://github.com/chengchingwen/Transformers.jl) by Peter Cheng, and is repackaged here into a standalone package for general purpose use.

### Installation

For the time being, the package can be installed with 
```
] add https://github.com/irhum/Stacks.jl
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://irhum.github.io/Stacks.jl/dev/
