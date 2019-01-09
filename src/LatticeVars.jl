module LatticeVars

using ..Points
import Distributions
using Distributions: Distribution

export LatticeVal, AbstractLatticeVar, LatticeVar, LatticeVarParam, init!,
    get_num_sites_visited

###
### LatticeVal
###

"""
    LatticeVal{N, T, D}

A container for values of type `T` attached to sites
on an `N`-dimensional hyper-cubic lattice.
Values are stored in `dict::D`, typically a `Dict`.
"""
struct LatticeVal{N, T, D}
    dict::D
end

"""
    LatticeVal{N=1, T=Float64}()

Construct a `LatticeVal` object. `dict` is
of type `Dict{Tuple(Int, Int, ...), T}`.
"""
function LatticeVal{N, T}() where {N, T}
    dict = Dict{Tuple{(Int for i in 1:N)...}, T}()
    return LatticeVal{N, T, typeof(dict)}(dict)
end

LatticeVal{N}() where N = LatticeVal{N, Float64}()
LatticeVal() = LatticeVal{1}()
Base.eltype(v::LatticeVal{<:Any, T}) where T = T

"""
    init!(vals::LatticeVal)

Remove all values stored in `vals`.
"""
init!(vals::LatticeVal) = empty!(vals)

import Base: empty!, length

for f in (:empty!, :length)
    @eval Base.$(f)(vals::LatticeVal) = ($f)(vals.dict)
end

get_num_sites_visited(vals::LatticeVal) = length(vals)

Base.setindex!(vals::LatticeVal, val, inds::Int...) = vals.dict[inds] = val
Base.getindex(vals::LatticeVal, inds::Int...) = vals.dict[inds]
Base.setindex!(vals::LatticeVal, val, p::Point) = setindex!(vals, val, get_coords(p))
Base.getindex(vals::LatticeVal, p::Point) = getindex(vals, get_coords(p))
Base.get!(vals::LatticeVal, k, v) = get!(vals.dict, k, v)

function Base.show(io::IO, v::LatticeVal{N, T}) where {N, T}
    print(io, length(v), "-element LatticeVal{$N, $T}")
end

abstract type AbstractLatticeVar end

get_num_sites_visited(v::AbstractLatticeVar) = get_num_sites_visited(get_vals(v))

for f in (:length, :eltype)
    @eval Base.$(f)(v::AbstractLatticeVar) = ($f)(get_vals(v))
end

init!(v::AbstractLatticeVar) = (init!(get_vals(v)); nothing)
# This should not be exported to avoid method squatting
init!(d::Distribution) = nothing

###
### LatticeVar
###

"""
    LatticeVar{N, Dist, Vals}

Type representing a quenched random variable on an `N`-dimensional lattice.
Field `dist::Dist` is typically a `Distribution`.

Field `vals::Vals` is typically storage for samples indexed by lattice site,
with `Vals <: LatticeVal`.
"""
struct LatticeVar{N, Dist, Vals} <: AbstractLatticeVar
    vals::Vals
    dist::Dist
end

get_vals(lv::LatticeVar) = lv.vals
get_dist(lv::LatticeVar) = lv.dist

"""
    LatticeVar{N=1}(dist::Distribution)

Construct a sample of a set of i.i.d. random variables with distribution `dist`
indexed by site on an `N`-dimensional hyper-cubic lattice.

### Examples
Exponentially distributed random variables on a square lattice.
The value for a site is generated when it is first accessed.
Subsequent access to the same site return the same value.
```julia-repl
julia> lv =  LatticeVar{2}(Exponential());

julia> lv[0,0]
1.3586837894898518

julia> lv[0,0]
1.3586837894898518

julia> lv[0,1]
0.1412406531803109
```
"""
function LatticeVar{N}(dist::Distribution) where N
    vals = LatticeVal{N}()
    return LatticeVar{N, typeof(dist), typeof(vals)}(vals, dist)
end
LatticeVar(dist::Distribution) = LatticeVar{1}(dist)

Base.getindex(var::LatticeVar, inds::Int...) = get!(var.vals, inds, rand(var.dist))
Base.getindex(var::LatticeVar, inds::Tuple) = get!(var.vals, inds, rand(var.dist))
Base.getindex(var::LatticeVar, k::Point) = getindex(var, get_coords(k))
Base.setindex!(var::LatticeVar, val, inds...) = (var.vals[inds...] = val)

function Base.show(io::IO, v::LatticeVar{N}) where {N}
    print(io, length(v), "-element LatticeVar{$N, ")
    show(io, v.dist)
    print(io, "}")
end

###
### LatticeVarParam
###

"""
    LatticeVarParam{N, ParamVar, SampleDist} <: AbstractLatticeVar

Type representing a random variable  with a quenched random parameter on an `N`-dimensional lattice.
More precisely, a quenched parameter is associated with each lattice site.
The value at that site is sampled each time it is queried from a distribution
depending on the quenched parameter.

By default, the sampling distribution is `Exponential`.
"""
struct LatticeVarParam{N, ParamVar, SampleDist} <: AbstractLatticeVar
    param_var::ParamVar
    sample_dist::SampleDist
end

function LatticeVarParam{N}(param_dist::Distribution, sample_dist = Distributions.Exponential) where N
    param_var = LatticeVar{N}(param_dist)
    return LatticeVarParam{N, typeof(param_var), typeof(sample_dist)}(param_var, sample_dist)
end

LatticeVarParam(param_dist::Distribution, sample_dist = Distributions.Exponential) = LatticeVarParam{1}(param_dist, sample_dist)

get_vals(lvp::LatticeVarParam) = get_vals(lvp.param_var)
get_param(lvp::LatticeVarParam) = lvp.param_var
get_param_dist(lvp::LatticeVarParam) = get_dist(get_param(lvp))
get_sample_dist(lvp::LatticeVarParam) = lvp.sample_dist

function Base.show(io::IO, v::LatticeVarParam{N}) where {N}
    print(io, length(v), "-element LatticeVarParam{$N, ")
    show(io, get_param(v).dist)
    print(io, ", ")
    show(io, v.sample_dist)
    print(io, "}")
end

Base.getindex(var::LatticeVarParam, inds::Int...) = rand(var.sample_dist(get_param(var)[inds...]))
Base.getindex(var::LatticeVarParam, inds::Tuple) = rand(var.sample_dist(get_param(var)[inds]))
Base.getindex(var::LatticeVarParam, k::Point) = rand(var.sample_dist(get_param(var)[k]))

end # module LatticeVars
