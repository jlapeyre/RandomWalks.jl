using RandomWalks
using Distributions, BenchmarkTools
using RandomWalks.LatticeVars
using RandomWalks.Lattices
using RandomWalks.Walks: Walk, MortalWalk
using RandomWalks.Actors
using EmpiricalCDFs

ntrials = 10^2
nsteps = 10^5
lambda = 1e6

lattice_rates = LatticeVar(Exponential(lambda))
waiting_times = LatticeVarParam(Pareto(0.5))
quenched_lattice = Lattice(waiting_times, lattice_rates)

walk = MortalWalk()
latwalk = LatticeWalk(quenched_lattice, walk)

#storing_actor = storing_nsteps_actor(logrange(1:.3:7.5));
storing_actor = storing_nsteps_actor(logrange(1:.3:5.5));
step_limit_actor = StepLimitActor(nsteps)
theactors = (step_limit_actor, storing_actor)
thecallbacks = callbacks(theactors...)
lattice_walk_plan = LatticeWalkPlan(latwalk, theactors)
ea = ECDFActor(storing_actor);

@time trial!(lattice_walk_plan, 1:ntrials, callbacks(ea));

sort!(ea);
cdfs = get_cdfs(ea);

nothing
