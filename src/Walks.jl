module Walks

import ..LatticeVars.init!
using ..WalksBase
using ..Actors

export walk!, WalkPlan, trial!

function walk!(walk::AbstractWalkGeneral, actor::AbstractActor)
    init!(walk)
    Actors.init!(actor)
    while step!(walk) && Actors.act!(actor, walk)
    end
    return walk
end

# FIXME
# Everything below is more general than lattice + walk
# This should be WalkPlan, or something
struct WalkPlan{T, V}
    walk::T
    actor::V
end

function Base.show(io::IO, lp::WalkPlan)
    println(io, "WalkPlan")
    show(io, lp.walk)
    show(io, lp.actor)
end

walk!(lwp::WalkPlan) = walk!(lwp.walk, lwp.actor)

for f in (:get_position, :get_time, :get_nsteps)
    @eval ($f)(lwp::WalkPlan) = ($f)(lwp.walk)
end

function trial!(walk_plan::WalkPlan, sample_loop::SampleLoop)
    return trial!(walk_plan, sample_loop.iter, sample_loop.actor)
end

function trial!(walk_plan::WalkPlan, iter::AbstractUnitRange, actor)
    for i in iter
        walk!(walk_plan)
        Actors.act!(actor, walk_plan.walk)
    end
    return nothing
end

end
