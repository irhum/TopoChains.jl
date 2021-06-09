# Stacks.jl

Stacks.jl provides a new data structure, a Stack, which picks up where Flux.jl's Chain left off. Unlike a Chain, which is designed for a sequential single-input single-output use case, a Stack can handle multi-input multi-output compositions of functions, layers and models.

The Stack was originally designed as part of [Transformers.jl](https://github.com/chengchingwen/Transformers.jl) by Peter Cheng, and is repackaged here into a standalone package for general-purpose use.