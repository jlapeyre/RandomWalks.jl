module Walks

import ..WalksBase: get_position, get_x, get_y, get_z, get_time, get_nsteps, step!
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

struct WalkPlan{T, V}
    walk::T
    actor::V
end

for f in (:get_position, :get_x, :get_y, :get_z, :get_time, :get_nsteps)
    @eval ($f)(lwp::WalkPlan) = ($f)(lwp.walk)
end

function Base.show(io::IO, lp::WalkPlan)
    println(io, "WalkPlan")
    show(io, lp.walk)
    show(io, lp.actor)
end

walk!(lwp::WalkPlan) = walk!(lwp.walk, lwp.actor)

function sample!(walk_plan::WalkPlan, trial_actor)
    walk!(walk_plan)
    Actors.act!(trial_actor, walk_plan.walk)
    return nothing
end

function trial_body!(walk_plan::WalkPlan, sample_loop::SampleLoopActor, iter)
    for i in iter
        sample!(walk_plan, sample_loop.actor)
    end
    return nothing
end

function trial!(walk_plan::WalkPlan, sample_loop::SampleLoopActor)
    trial_actor = sample_loop.actor
    Actors.init!(trial_actor)
    trial_body!(walk_plan, sample_loop, sample_loop.iter)
    Actors.finalize!(trial_actor)
    return nothing
end

end # module Walks
