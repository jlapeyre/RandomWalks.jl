@testset "Mortal walks" begin
    walk = WalkF(status_type = Mortal())

    lattice_rates = LatticeVar{1}(Exponential(1e6))
    waiting_times = LatticeVar{1}(Pareto(0.5))

    ql = Lattice(waiting_times, lattice_rates)

    latwalk = LatticeWalk(ql, walk)

    times = logrange(1:.3:6)
    step_limit_actor = StepLimitActor(10^4)
    storing_actor = storing_nsteps_position_actor(times)

    actors = ActorSet(step_limit_actor, storing_actor)
    walk!(latwalk, actors)
    @test  typeof(Actors.get_values(storing_actor)) == Tuple{Vector{Int64}, Vector{Float64}}

    storing_actor = storing_nsteps_actor(times)
    actors = ActorSet(step_limit_actor, storing_actor)
    walk!(latwalk, actors)
    @test  typeof(Actors.get_values(storing_actor)) == Tuple{Vector{Int64}}

    storing_actor = storing_position_actor(times)
    actors = ActorSet(step_limit_actor, storing_actor)
    walk!(latwalk, actors)
    @test  typeof(Actors.get_values(storing_actor)) == Vector{Float64}

    lwp = WalkPlan(latwalk, ActorSet(step_limit_actor, storing_actor, NullActor()))
    walk!(lwp)
    @test  typeof(Actors.get_values(storing_actor)) == Vector{Float64}
end
