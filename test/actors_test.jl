using RandomWalks.Actors: init!, act!

@testset "NullActor" begin
    a = RandomWalks.Actors.NullActor()
    @test act!(a, nothing)
    @test init!(a) == nothing
end

@testset "StepLimitActor" begin
    n = 10
    a = RandomWalks.Actors.StepLimitActor(n)
    @test a.max_step_limit == n
    @test ! a.hit_max_step_limit
    a.hit_max_step_limit = true
    @test init!(a) == nothing
    @test ! a.hit_max_step_limit
end

