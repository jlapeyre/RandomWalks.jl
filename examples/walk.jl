using RandomWalks
using Distributions, BenchmarkTools
using RandomWalks.LatticeVars
using RandomWalks.Lattices
using RandomWalks.Walks: Walk, MortalWalk, WalkPlan, trial!
using RandomWalks.Actors
using EmpiricalCDFs

ntrials = 10^3
nsteps = 10^3
lambda = 1e6

lattice_rates = LatticeVar(Exponential(lambda))
waiting_times = LatticeVarParam(Pareto(0.5))
quenched_lattice = Lattice(waiting_times, lattice_rates)

walk = MortalWalk()
latwalk = LatticeWalk(quenched_lattice, walk)

store_range = 1:.3:7.5
storing_actor = storing_nsteps_actor(logrange(store_range))
step_limit_actor = StepLimitActor(nsteps)
theactors = ActorSet(step_limit_actor, storing_actor)
walk_plan = WalkPlan(latwalk, theactors)
ea = ECDFActor(storing_actor);

@time trial!(walk_plan, 1:ntrials, ea);

sort!(ea);
cdfs = get_cdfs(ea);

nothing
