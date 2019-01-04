module Lattices

using ..LatticeVars
import ..LatticeVars.init!
using ..Points
using Distributions

export AbstractLattice, Lattice

abstract type AbstractLattice end

"""
    Lattice{N, T} <: AbstractLattice

Type representing variables on the sites of an `N`-dimensional lattice.
`T` is a `Tuple` type of variables. These variables are meant to be a mixture of
types `Distribution` (annealed variables) and `LatticeVars` (quenched variables).
"""
struct Lattice{N, T} <: AbstractLattice
    vars::T
    Lattice{N}(vars::Tuple) where N = new{N, typeof(vars)}(vars)
    function Lattice{N}(vars...) where N
        vartup = (vars...,)
        return new{N, typeof(vartup)}(vartup)
    end
end
Lattice(args...) = Lattice{1}(args...)

_getindex(dist::Distribution, inds...) = rand(dist)
_getindex(lattice_var::AbstractLatticeVar, inds...) = lattice_var[inds...]
Base.getindex(lattice::Lattice, i::Integer) = lattice.vars[i]
Base.getindex(lattice::Lattice, i::Integer, inds::Integer...) = _getindex(lattice[i], inds)
Base.getindex(lattice::Lattice, i::Integer, p::Point) = _getindex(lattice[i], get_coords(p))

init!(lattice::Lattice) = foreach(x -> init!(x), lattice.vars)

get_vars(lattice::Lattice) = lattice.vars

function Base.show(io::IO, lattice::Lattice{N}) where N
    println(io, N, "-dimensional Lattice")
    for v in get_vars(lattice)
        println(io, v)
    end
end

# const QuenchedLattice{N, T} where {N, T <: Tuple{<: = Lattice{


end
