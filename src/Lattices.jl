module Lattices

using ..LatticeVars
import ..LatticeVars.init!, ..LatticeVars.get_num_sites_visited
using ..Points
using Distributions
using JDistributions: BernoulliBool

export AbstractLattice, Lattice, AbstractLatticeTypes, Traps, TrapsLattice
export SitePercolationLattice, SitePercolation

abstract type AbstractLattice end

abstract type AbstractLatticeTypes end
struct Traps <: AbstractLatticeTypes
end

"""
    Lattice{N, T} <: AbstractLattice

Type representing variables on the sites of an `N`-dimensional lattice.
`T` is a `Tuple` type of variables. These variables are meant to be a mixture of
types `Distribution` (annealed variables) and `LatticeVars` (quenched variables).
"""
struct Lattice{N, T, Opts} <: AbstractLattice
    vars::T
    Lattice{N}(vars::Tuple; lattice_type = Traps) where N = new{N, typeof(vars), lattice_type}(vars)
    function Lattice{N}(vars...; lattice_type = Traps) where N
        vartup = (vars...,)
        return new{N, typeof(vartup), lattice_type}(vartup)
    end
end

Lattice(args...; kwargs...) = Lattice{1}(args...; kwargs...)

const TrapsLattice = Lattice{N, T, Traps} where {N, T}

struct SitePercolation <: AbstractLatticeTypes
end

const SitePercolationLattice = Lattice{N, T, SitePercolation} where {N, T}

function SitePercolationLattice{N}(p) where {N}
    return Lattice{N}(LatticeVar{N}(BernoulliBool(p)); lattice_type = SitePercolation)
end

SitePercolationLattice(p) = SitePercolationLattice{1}(p)

_getindex(dist::Distribution, inds...) = rand(dist)
_getindex(lattice_var::AbstractLatticeVar, inds...) = lattice_var[inds...]
Base.getindex(lattice::Lattice, i::Integer) = lattice.vars[i]
Base.getindex(lattice::Lattice, i::Integer, inds::Integer...) = _getindex(lattice[i], inds)
Base.getindex(lattice::Lattice, i::Integer, p::Point) = _getindex(lattice[i], get_coords(p))
init!(lattice::Lattice) = foreach(x -> init!(x), lattice.vars)
get_vars(lattice::Lattice) = lattice.vars
get_num_sites_visited(lattice::Lattice) = get_num_sites_visited(get_vars(lattice)[1])

function Base.show(io::IO, lattice::Lattice{N}) where N
    println(io, N, "-dimensional Lattice")
    for v in get_vars(lattice)
        println(io, v)
    end
end

end
