using RandomWalks, Distributions, BenchmarkTools

function test_new()
    walk = Walk()
    lattice_rates = LatticeVar{1}(Exponential(1e6))
    waiting_times = LatticeVar{1}(Pareto(0.5))
    ql = QuenchedDecayLattice(waiting_times, lattice_rates)
    latwalk = LatticeWalk(ql, walk)

    #spc = storing_position_actor(logrange(1:.3:6));
    spc = storing_nsteps_position_actor(logrange(1:.3:6));
    theactors = (StepLimitActor(10^4), spc)
    thecallbacks = callbacks(theactors...)
    walk!(latwalk, thecallbacks)
    lwp = LatticeWalkPlan(latwalk, theactors)
    walk!(lwp)
end


function test_one()
    walk = Walk()
    lattice_rates = LatticeVar{1}(Exponential(1e6))
    waiting_times = LatticeVar{1}(Pareto(0.5))
    ql = QuenchedDecayLattice(waiting_times, lattice_rates)
    latwalk = LatticeWalk(ql, walk)

    #spc = storing_position_actor(logrange(1:.3:6));
    spc = storing_nsteps_position_actor(logrange(1:.3:6));
    theactors = (StepLimitActor(10^4), spc)
    thecallbacks = callbacks(theactors...)
    walk!(latwalk, thecallbacks)
    lwp = LatticeWalkPlan(latwalk, theactors)
    walk!(lwp)
end

function survival_cdf()
    walk = Walk()
    lattice_rates = LatticeVar{1}(Exponential(1e3))
    waiting_times = LatticeVar{1}(Pareto(0.5))
    ql = QuenchedDecayLattice(waiting_times, lattice_rates)
    latwalk = LatticeWalk(ql, walk)
    sample_actors = (StepLimitActor(10^6),)
    lwp = LatticeWalkPlan(latwalk, sample_actors)
    sl = SampleLoop(1:10^2, (NullActor(), ))
    trial!(lwp, sl)
    return lwp
end

nothing
