using EmpiricalCDFs: EmpiricalCDF
using MaximumLikelihoodPower: mle

@testset "ordinary RW, first return" begin
    nsamples = 10^4
    cutoff = 200
    first_return_actor = FirstReturnActor()
    ecdf_actor = ECDFValueActor(first_return_actor)
    for w in (WalkB(), WalkF())
        @time trial!(WalkPlan(w, ActorSet(StepLimitActor(10^10), first_return_actor)), SampleLoopActor(nsamples, ecdf_actor))
        alpha, err = mle(ecdf_actor[end - cutoff:end])
        @test isapprox(alpha, 3/2, atol=0.2)
    end
end

@testset "ordinary RW, mean std" begin
    nsteps = 10^4
    ntrials = 10^5
    w = WalkB()
    wp = WalkPlan(w, StepLimitActor(nsteps))
    ecdf = EmpiricalCDF{Int}()
    cdf_actor = ECDFActor(get_x, ecdf)
    trial_loop = SampleLoopActor(ntrials, cdf_actor)
    @time trial!(wp, trial_loop)
    ecdf =  ecdf ./ sqrt(nsteps)
    tol = 1e-2
    @test isapprox(std(ecdf), 1; atol=tol)
    @test isapprox(mean(ecdf), 0; atol=tol)
end
