module LatticeWalks

import ..LatticeVars.init!
using ..Lattices
using ..WalksBase
import ..WalksBase: get_position, get_time, get_nsteps, step!
using ..Actors

import ..Walks: walk!

export AbstractLatticeWalk, LatticeWalk

abstract type AbstractLatticeWalk <: AbstractWalkGeneral
end

function init!(lattice_walk::AbstractLatticeWalk)
    init!(lattice_walk.lattice)
    WalksBase.init!(lattice_walk.walk)
    return nothing
end

###
### LatticeWalk
###

"""
    struct LatticeWalk

Represents a walk on a lattice.
"""
struct LatticeWalk{L <: AbstractLattice, W <: AbstractWalk} <: AbstractLatticeWalk
    lattice::L
    walk::W
end

function init!(lattice_walk::LatticeWalk{<:Any, <:MortalWalk})
    init!(lattice_walk.lattice)
    WalksBase.init!(lattice_walk.walk)
    unset_decayed(lattice_walk.walk)
    return nothing
end

for f in (:get_position, :get_time, :get_nsteps)
    @eval ($f)(lw::LatticeWalk) = ($f)(lw.walk)
end

# mutable struct LatticeWalkStatus
#     decayed::Bool
# end

#Base.show(io::IO, status::LatticeWalkStatus) = print(io, "decayed = ", status.decayed)
#LatticeWalkStatus() = LatticeWalkStatus(false)
#set_decayed(lw::LatticeWalk) = lw.status.decayed = true
#unset_decayed(lw::LatticeWalk) = lw.status.decayed = false

LatticeWalk(lat, walk) = LatticeWalk{typeof(lat), typeof(walk)}(lat, walk)

Base.getindex(lattice_walk::LatticeWalk, inds...) = getindex(lattice_walk.lattice, inds...)

function Base.show(io::IO, lw::LatticeWalk)
    println(io, "LatticeWalk")
    show(io, lw.lattice)
    println(io)
    show(io, lw.walk)
    println(io)
#    println(io, lw.walk.status) # FIXME. show status elsewhere
end

function step!(lattice_walk::LatticeWalk{<:Any, <:Any})
    result = step!(lattice_walk.walk, lattice_walk.lattice)
    result && return result
    return result
end

function step!(lattice_walk::LatticeWalk{<:Any, <:MortalWalk})
    result = step!(lattice_walk.walk, lattice_walk.lattice)
    result && return result
    set_decayed(lattice_walk.walk)
    return result
end

function step!(walk::MortalWalk, lattice::AbstractLattice)
    pos = get_position(walk)
    jump_time = lattice[1, pos]
    decay_time = lattice[2, pos]
    if decay_time < jump_time
        addto_time!(walk, decay_time)
        return false
    else
        addto_time!(walk, jump_time)
        step!(walk)
        return true
    end
end

function step!(walk::Walk, lattice::AbstractLattice)
    pos = get_position(walk)
    jump_time = lattice[1, pos]
    addto_time!(walk, jump_time)
    step!(walk)
    return true
end


end  # module LatticeWalks
