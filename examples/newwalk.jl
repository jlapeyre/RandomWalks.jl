using RandomWalks
# using all of these just so Revise knows about them
using RandomWalks.Actors
using RandomWalks.Lattices
using RandomWalks.LatticeVars
using RandomWalks.LatticeWalks
using RandomWalks.Points
using RandomWalks.WalksBase
using RandomWalks.Walks

using Distributions, BenchmarkTools
using EmpiricalCDFs
using DataFrames

function getcdfs(; ntrials = 10^3, nsteps = 10^3, lambda = 1e2)

#    ntrials = 10^3; nsteps = 10^3; lambda = 1e2

    lattice_rates = LatticeVar{2}(Exponential(lambda))
    waiting_times = LatticeVarParam{2}(Pareto(0.5))
    quenched_lattice = Lattice(waiting_times, lattice_rates)

    walk = MortalWalk(WalkB{2}())
    lattice_walk = LatticeWalk(quenched_lattice, walk)

    store_range = 1:.3:8.5
    storing_actor = storing_nsteps_num_sites_visited_actor(logrange(store_range))
    step_limit_actor = StepLimitActor(nsteps)
    theactors = ActorSet(step_limit_actor, storing_actor)
    walk_plan = WalkPlan(lattice_walk, theactors)
    ecdfs_actor = ECDFsActor(storing_actor);
    max_step_counter = CountActor(step_limit_actor)
    trial_actors = ActorSet(max_step_counter, ecdfs_actor)
    @time trial!(walk_plan, SampleLoopActor(ntrials, trial_actors));
    if get_count(max_step_counter) > 0
        @warn("Hit step limit " * string(get_count(max_step_counter)) * " times.")
    end
    tcdfs = get_ecdf_times(ecdfs_actor);
    ptcdfs = prune(tcdfs)
    cdfs = get_cdfs(ptcdfs)
    return (cdfs, trial_actors, ptcdfs)
end

function cdfrep(ptcdfs)
    cdfs = get_cdfs(ptcdfs)
    times = get_times(ptcdfs)
#    DataFrame([extrema.(cdfs) median.(cdfs) length.(cdfs[:,1])], [:ext_nsteps, :ext_nsites, :med_nsteps, :med_nsites, :ncounts])
    DataFrame([times length.(cdfs[:,1])  maximum.(cdfs[:,1]) extrema.(cdfs[:,2]) median.(cdfs[:,2]) ],
              [:time, :ncounts, :max_steps, :minmax_nsites, :med_nsites])
end

nothing
