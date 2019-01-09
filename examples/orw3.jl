using RandomWalks
using BenchmarkTools
using EmpiricalCDFs: EmpiricalCDF, get_data
using Statistics

nsamples = 10^4
nsteps = 10^3
tolerance = 1e-2

ecdf = EmpiricalCDF()
trial_loop = SampleLoopActor(nsamples, ECDFActor(get_x, ecdf))
@time trial!(WalkPlan(ContinuousWalk(WalkB(Point(0.0))), StepLimitActor(nsteps)), trial_loop)

x = get_data(ecdf)
x ./= sqrt(nsteps)

@info "Test standard deviation and mean of an ordinary RW"
@show isapprox(std(ecdf), 1; atol = tolerance)
@show isapprox(mean(ecdf), 0; atol = tolerance)
