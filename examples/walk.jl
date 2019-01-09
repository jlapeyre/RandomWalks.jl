using RandomWalks
using RandomWalks.LatticeWalks
using Distributions, BenchmarkTools
using EmpiricalCDFs

ntrials = 10^4
nsteps = 10^4
lambda = 1e3

lattice_rates = LatticeVar(Exponential(lambda))
waiting_times = LatticeVarParam(Pareto(0.5))
quenched_lattice = Lattice(waiting_times, lattice_rates)

walk = MortalWalk()
lattice_walk = LatticeWalk(quenched_lattice, walk)

store_range = 1:.3:7.5
storing_actor = storing_nsteps_num_sites_visited_actor(logrange(store_range))
step_limit_actor = StepLimitActor(nsteps)
theactors = ActorSet(step_limit_actor, storing_actor)
walk_plan = WalkPlan(lattice_walk, theactors)
ea = ECDFsActor(storing_actor);

@time trial!(walk_plan, SampleLoopActor(ntrials, ea));

cdfs = get_cdfs(ea);

nothing
