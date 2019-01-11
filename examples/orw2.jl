# # Distribution of first return times for the one-dimensional random walk

# Here we verify that the tail of the distribution of the time of first return to the origin
# decays like $n^{-3/2}$

# First, we load packages that we will use
using RandomWalks, EmpiricalCDFs

# Set the number of samples (trajectories) to collect.
nsamples = 10^4;

# The following `AbstractActor` stops the walk on the first return, recording the number of steps taken.
first_return_actor = FirstReturnActor();

# `ECDFValueActor` builds an `EmpiricalCDF` from another (child) actor.
# In this case, we want to build an `EmpiricalCDF` of the first return time.
# If the child actor satisfies a simple interface, and `FirstReturnActor` does,
# then the entire specification of the action is simply
ecdf_actor = ECDFValueActor(first_return_actor);

# The probability that the walker returns to the origin is $1$, but the mean return time is infinite.
# Fluctuations are large and some walkers make a large number of steps before returning.
# So, we want to specify two criteria for terminating a walk: the first return and a limit on the number of steps.
# We put these `Actors` (and any others we may want) in an `ActorSet`.
plan_actor_set = ActorSet(StepLimitActor(10^9), first_return_actor);

# Now we run the trial, using a basic one-dimensional random walker `WalkB()`.

@time trial!(WalkPlan(WalkB(), plan_actor_set), SampleLoopActor(nsamples, ecdf_actor))

# Note that we have used `first_return_actor` in two places.
# First in the generation of the sample, and again in collecting data after each sample.

# Now let's assume (correctly) the tail of the first-return distribution follows a power law
# and verify that the exponent is close to $-3/2$.
using MaximumLikelihoodPower
mle(ecdf_actor[end-200:end]) # mle returns the estimate and error estimate

# ### Ensuring accurate statistics

# There is a potential problem with the example above.
# `StepLimitActor` breaks the sample loop silently, as it should.
# In the case at hand, with only `10^4` samples, the chance of one walker making $10^{9}$ steps before
# returning is very small. (How small ?)
# However, if we want to be sure that none of the walks were cut short,
# We can replace `StepLimitActor(10^9)` above by `ErrorOnExitActor(StepLimitActor(10^9)`.
# This replaces the silent exit with a fatal error.

# Another option is to use `CountActor` to count the number of times the step limit was reached.

step_limit_actor = StepLimitActor(10^6)
plan_actor_set = ActorSet(step_limit_actor, first_return_actor);
count_actor = CountActor(step_limit_actor)
trial_actor = SampleLoopActor(nsamples, ActorSet(ecdf_actor, count_actor))
@time trial!(WalkPlan(WalkB(), plan_actor_set), trial_actor)

get_actor_value(count_actor)

# Note that in the last example, we bound `step_limit_actor` to the instance of `StepLimitActor`
# because we need to refer to it in two places.
