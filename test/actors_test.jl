@testset "NullActor" begin
    a = NullActor()
    @test act!(a, nothing)
    @test Actors.init!(a) == nothing
end

@testset "StepLimitActor" begin
    n = 10
    a = StepLimitActor(n)
    @test a.max_step_limit == n
    @test ! a.hit_max_step_limit
    a.hit_max_step_limit = true
    @test Actors.init!(a) == nothing
    @test ! a.hit_max_step_limit
end

