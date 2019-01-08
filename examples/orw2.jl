using RandomWalks
using BenchmarkTools
using EmpiricalCDFs
using MaximumLikelihoodPower

nsamples = 10^4
first_return_actor = FirstReturnActor()
ecdf_actor = ECDFValueActor(first_return_actor)
@time trial!(WalkPlan(WalkB(), ActorSet(StepLimitActor(10^10), first_return_actor)), SampleLoopActor(nsamples, ecdf_actor))
@show mle(ecdf_actor[end-200:end])
