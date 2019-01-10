using RandomWalks

# using all of the following just so Revise knows about them
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

function getcdfs(; dimension = 2, ntrials = 10^3, nsteps = 10^3, lambda = 1e2)

    lattice_rates = LatticeVar{dimension}(Exponential(lambda))
    waiting_times = LatticeVarParam{2}(Pareto(0.5))
    quenched_lattice = Lattice(waiting_times, lattice_rates)

    walk = MortalWalk(WalkB{dimension}())
    lattice_walk = LatticeWalk(quenched_lattice, walk)

    log_store_range = 1:.3:8.5
    storing_actor = storing_nsteps_num_sites_visited_actor(logrange(log_store_range))
    step_limit_actor = StepLimitActor(nsteps)
    theactors = ActorSet(step_limit_actor, storing_actor)
    walk_plan = WalkPlan(lattice_walk, theactors)
    ecdfs_actor = ECDFsActor(storing_actor);
    max_step_counter = CountActor(step_limit_actor)
    trial_actors = ActorSet(max_step_counter, ecdfs_actor)
    @time trial!(walk_plan, SampleLoopActor(ProgressIter(ntrials), trial_actors));
    if get_count(max_step_counter) > 0
        @error("Hit step limit " * string(get_count(max_step_counter)) * " times.")
    end
    tcdfs = get_ecdf_times(ecdfs_actor);
    ptcdfs = prune(tcdfs)
    return (ptcdfs, ntrials, trial_actors)
end

function cdfrep(ptcdfs, ntrials)
    cdfs = get_cdfs(ptcdfs)
    times = get_times(ptcdfs)
    DataFrame([times, length.(cdfs[:,1]), length.(cdfs[:,1]) ./ ntrials,  maximum.(cdfs[:,1]), extrema.(cdfs[:,2]),
               median.(cdfs[:,2]), mean.(cdfs[:,2])],
              [:time, :ncounts, :survp, :max_steps, :minmax_sites, :median_nsites, :mean_nsites])
end

function vstrials(; lambda = 1e2, dimension = 2)
    for nexp in 1:7
        for fac in (1, 3, 6)
            (tcdfs, ntrials, trial_actors) = getcdfs(;ntrials = fac * 10^nexp, nsteps=10^6, lambda=lambda, dimension = dimension)
            df = cdfrep(tcdfs, ntrials)
            @info "ntrials = $ntrials"
            println(df)
            println()
        end
    end
end

nothing
