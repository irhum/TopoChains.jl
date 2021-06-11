#=
examples
x => b => c  ==> b = m[1](x) ; c = m[2](b)
x => 3 ==> x => a => a => a ==> x = m[1](a); a = m[1](a); a = m[1](a)
(x, m) => a => b => c ==> a = m[1](x , m); b = m[2](b); c = m[3](b)
((x, m) => x) => 3 ==> (x = m[1](x, m)); (x = m[2](x, m)); (x = m[3](x, m))
(((x, m) => x:(x, m)) => 3) ==> (x = m[1](x,m)); (x = m[2](x,m)) ;(x = m[3](x,m))
=#

"""
    nntopo"pattern"

the @nntopo string
"""
macro nntopo_str(str)
  :(NNTopo($(esc(str))))
end

"""
    @nntopo structure

Create an `NNTopo` to apply functions according to the given `structure`.

# Example
```jldoctest
julia> @nntopo x:x => h1:x => h2:(h1, h2) => o
NNTopo{"x:x => (h1:x => (h2:(h1, h2) => o))"}
function(model, x)
    h1 = model[1](x)
    h2 = model[2](x)
    o = model[3](h1, h2)
    o
end
```
"""
macro nntopo(expr)
  NNTopo(interpolate(__module__, expr))
end

isinterpolate(x) = false
isinterpolate(ex::Expr) = ex.head == :($)
interpolate(m::Module, x) = x
function interpolate(m::Module, ex::Expr)
  if isinterpolate(ex)
    return @eval(m, $(ex.args[1]))
  else
    for (i, e) ∈ enumerate(ex.args)
      ex.args[i] = interpolate(m, e)
    end
  end
  ex
end

"""
    NNTopo(s)

the type of a sequence of function
"""
struct NNTopo{FS} end

Base.getproperty(nt::NNTopo, s::Symbol) = s == :fs ? Base.getproperty(nt, Val(:fs)) : error("type NNTopo has no field $s")
Base.getproperty(::NNTopo{FS}, ::Val{:fs}) where FS = string(FS)

NNTopo(s::String) = NNTopo(Meta.parse(s))
NNTopo(ex::Expr) = islegal(ex) ?
  NNTopo{Symbol(ex)}() :
  error("topo pattern illegal")

genline(name, arg::Symbol, m, i::Int) = Expr(:(=), name, Expr(:call, :($m[$i]), arg))
genline(name, args::Expr, m, i::Int) = Expr(:(=), name, Expr(:call, :($m[$i]), args.args...))

nntopo_impl(s::Symbol) = nntopo_impl(string(s))
nntopo_impl(sf::String) = nntopo_impl(Meta.parse(sf))
function nntopo_impl(pattern)
  m = :model
  xs = :xs

  collectsyms = Any[]

  code = to_code(pattern)

  if istuple(code.in)
    pref = Expr(:(=), removecollect(code.in), xs)
  else
    pref = Expr(:(=), removecollect(Expr(:tuple, code.in)), xs)
  end

  fbody = Any[:block]
  push!(fbody, pref)
  for (i, l) ∈ enumerate(code.lines)
    (name, args) = l
    if hascollect(args)
      colname = gensym(:%)
      push!(fbody, Expr(:(=), colname, collectcollect(args)))
      push!(collectsyms, colname)
    end

    push!(fbody, genline(removecollect(name), removecollect(args), m, i))

    if hascollect(name)
      colname = gensym(:%)
      push!(fbody, Expr(:(=), colname, collectcollect(name)))
      push!(collectsyms, colname)
    end
  end

  if isempty(collectsyms)
    push!(fbody, removecollect(code.out))
  else
    if hascollect(code.out)
      colname = gensym(:%)
      push!(fbody, Expr(:(=), colname, collectcollect(code.out)))
      push!(collectsyms, colname)
    end

    duplicatedcollect = filter(2:length(fbody)-1) do i
      fbody[i].args[2] == fbody[i+1].args[2]
    end

    erasedidx = map(duplicatedcollect) do i
      findfirst(isequal(fbody[i].args[1]), collectsyms)
    end

    deleteat!(fbody, duplicatedcollect)
    deleteat!(collectsyms, erasedidx)

    push!(fbody, Expr(:tuple,
                      removecollect(code.out),
                      Expr(:tuple, collectsyms...)))
  end

  Expr(fbody...)
end

@generated function (nt::NNTopo{FS})(model, xs...) where {FS}
  return nntopo_impl(FS)
end

function Base.show(io::IO, nt::NNTopo)
  println(io, "NNTopo{\"$(nt.fs)\"}")
  print_topo(io, nt)
  io
end

print_topo(nt::NNTopo; models=nothing) = print_topo(stdout, nt; models=models)

function print_topo(io::IO, nt::NNTopo; models=nothing)
  body = nntopo_impl(Meta.parse(nt.fs)).args
  farg = join(body[1].args[1].args, ", ")
  println(io, models == nothing ? "function(model, $farg)" : "function($farg)")
  i = 1
  sname = Dict{String, String}()
  si = 1
  for l ∈ @view(body[2:end-1])
    name = string(l.args[1])
    if occursin("#", name)
      args = string(l.args[2])
      sname[name] = "%$si"
      println(io, "    $(sname[name]) = $args")
      si+=1
    else
      args = join(l.args[2].args[2:end], ", ")
      model = models === nothing ? "model[$i]" : string(models[i])
      println(io, "    $name = $model($args)")
      i+=1
    end
  end
  out = replace(string(body[end]), r"##%#\d+" => s->sname[s])
  println(io, "    $out")
  println(io, "end")
end

