module LatticeWalks

import ..LatticeVars.init!, ..LatticeVars.get_num_sites_visited
using ..Lattices
using ..WalksBase
import ..WalksBase: get_position, get_time, get_nsteps, step!
using ..Actors

export AbstractLatticeWalk, LatticeWalk, get_num_sites_visited

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

for f in (:get_position, :get_time, :get_nsteps)
    @eval ($f)(lw::LatticeWalk) = ($f)(lw.walk)
end

for f in (:get_num_sites_visited,)
    @eval ($f)(lw::LatticeWalk) = ($f)(lw.lattice)
end

Base.getindex(lattice_walk::LatticeWalk, inds...) = getindex(lattice_walk.lattice, inds...)

LatticeWalk(lat, walk) = LatticeWalk{typeof(lat), typeof(walk)}(lat, walk)

function Base.show(io::IO, lw::LatticeWalk)
    println(io, "LatticeWalk")
    show(io, lw.lattice)
    println(io)
    show(io, lw.walk)
    println(io)
end

function step!(lattice_walk::LatticeWalk{<:Any, <:Any})
    result = step!(lattice_walk.walk, lattice_walk.lattice)
    result && return result
    return result
end

function step!(walk::WalkB, lattice::TrapsLattice)
    pos = get_position(walk)
    jump_time = lattice[1, pos]
    addto_time!(walk, jump_time)
    step!(walk)
    return true
end

function step!(lattice_walk::LatticeWalk{<:Any, <:MortalWalk})
    result = step!(lattice_walk.walk, lattice_walk.lattice)
    result && return result
    set_status!(lattice_walk.walk, false)
    return result
end

function step!(walk::MortalWalk, lattice::TrapsLattice)
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

#function step!(walk::WalkF{X,Y,Z}, lattice::SitePercolationLattice) where {X,Y,Z}
function step!(walk::WalkB, lattice::SitePercolationLattice)
    disp = try_step_increment(walk)
    @show disp
    newpos = get_position(walk) + disp
    @show newpos
    site_state = lattice[1, newpos]
    @show site_state
    if site_state
        set_position!(walk, newpos)
    end
    return true
end

end  # module LatticeWalks
