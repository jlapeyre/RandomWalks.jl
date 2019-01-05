using RandomWalks
using BenchmarkTools
using RandomWalks.WalksBase
using RandomWalks.Walks
using RandomWalks.Actors
using EmpiricalCDFs
using MaximumLikelihoodPower

nsamples = 10^4
first_return_actor = FirstReturnActor()
ecdf_actor = ECDFValueActor(first_return_actor)
@time trial!(WalkPlan(Walk(), ActorSet(StepLimitActor(10^10), first_return_actor)), SampleLoopActor(nsamples, ecdf_actor))
@show mle(ecdf_actor[end-200:end])
