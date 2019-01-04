module LatticeWalks

import ..LatticeVars.init!
using ..Lattices
using ..Walks
import ..Walks: get_position, get_time, get_nsteps, step!
using ..Actors

export AbstractLatticeWalk, LatticeWalk, LatticeWalkPlan, walk!, trial!

abstract type AbstractLatticeWalk end

function init!(lattice_walk::AbstractLatticeWalk)
    init!(lattice_walk.lattice)
    Walks.init!(lattice_walk.walk)
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
    Walks.init!(lattice_walk.walk)
    unset_decayed(lattice_walk.walk)
    return nothing
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

struct LatticeWalkPlan{T, V}
    lattice_walk::T
    actor::V
end

function Base.show(io::IO, lp::LatticeWalkPlan)
    println(io, "LatticeWalkPlan")
    show(io, lp.lattice_walk)
    show(io, lp.actor)
end

walk!(lwp::LatticeWalkPlan) = walk!(lwp.lattice_walk, lwp.actor)

for f in (:get_position, :get_time, :get_nsteps)
    @eval ($f)(lw::LatticeWalk) = ($f)(lw.walk)
    @eval ($f)(lwp::LatticeWalkPlan) = ($f)(lwp.lattice_walk)
end

function walk!(lattice_walk::AbstractLatticeWalk, actor)
    init!(lattice_walk)
    Actors.init!(actor)
    while step!(lattice_walk) && Actors.act!(actor, lattice_walk)
    end
    return lattice_walk
end

function trial!(lattice_walk_plan::LatticeWalkPlan, sample_loop::SampleLoop)
    return trial!(lattice_walk_plan, sample_loop.iter, sample_loop.actor)
end

function trial!(lattice_walk_plan::LatticeWalkPlan, iter::AbstractUnitRange, actor)
    for i in iter
        walk!(lattice_walk_plan)
        Actors.act!(actor, lattice_walk_plan.lattice_walk)
    end
    return nothing
end

end  # module LatticeWalks
