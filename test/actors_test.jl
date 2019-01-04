using RandomWalks.Actors: init!

@testset "NullActor" begin
    a = RandomWalks.Actors.NullActor()
    @test fieldnames(NullActor) == (:callback, )
    @test isa(callbacks(a), SampleCallback)
    cb = callbacks(a)
    @test cb.action!(nothing)
    @test cb(nothing) == cb.action!(nothing)
    @test cb.init!() == nothing
    @test init!(cb) == cb.init!()
end

@testset "StepLimitActor" begin
    n = 10
    a = RandomWalks.Actors.StepLimitActor(n)
    cb = callbacks(a)
    @test cb.action!.max_step_limit == n
    @test ! cb.action!.hit_max_step_limit
    cb.action!.hit_max_step_limit = true
    init!(cb)
    @test ! cb.action!.hit_max_step_limit
end

