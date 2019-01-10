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
#using DataFrames

ntrials = 10^6
nsteps = 10^5
lambda = 1e5

lattice_rates = LatticeVar(Exponential(lambda))
waiting_times = LatticeVarParam(Pareto(0.5))
quenched_lattice = Lattice(waiting_times, lattice_rates)

walk = MortalWalk()
lattice_walk = LatticeWalk(quenched_lattice, walk)

store_range = 1:.3:8.5
storing_actor = storing_nsteps_num_sites_visited_actor(logrange(store_range))
step_limit_actor = StepLimitActor(nsteps)
theactors = ActorSet(step_limit_actor, storing_actor)
walk_plan = WalkPlan(lattice_walk, theactors)
ea = ECDFsActor(storing_actor);

@time trial!(walk_plan, SampleLoopActor(ntrials, ea));

tcdfs = get_ecdf_times(ea);
ptcdfs = prune(tcdfs)
cdfs = get_cdfs(ptcdfs)

nothing
