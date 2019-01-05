using RandomWalks
using BenchmarkTools

using RandomWalks.WalksBase: Walk, get_x
using RandomWalks.Walks: WalkPlan, trial!
using RandomWalks.Actors: StepLimitActor, ECDFActor, SampleLoopActor
using EmpiricalCDFs: EmpiricalCDF
using Statistics

nsamples = 10^5
nsteps = 10^4
tolerance = 1e-2

ecdf = EmpiricalCDF{Int}()
cdf_actor = ECDFActor(get_x, ecdf)
trial_loop = SampleLoopActor(nsamples, cdf_actor)
@time trial!(WalkPlan(Walk(), StepLimitActor(nsteps)), trial_loop)

ecdf =  ecdf ./ sqrt(nsteps)

@info "Test standard deviation and mean of an ordinary RW"
@show isapprox(std(ecdf), 1; atol = tolerance)
@show isapprox(mean(ecdf), 0; atol = tolerance)
