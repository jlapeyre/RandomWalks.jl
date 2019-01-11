# # Ordinary random walk

# Here is the prototypical application. We repeatedly perform an ordinary random walk with a fixed
# number of steps on $\mathbb{Z}$, collecting statistics on the final position.
# We call each walk, or trajectory, a *sample*. An ensemble of samples is a *trial*.

# We begin by loading packages that we will use.

using RandomWalks
using EmpiricalCDFs: EmpiricalCDF, get_data
using Statistics

# First, we show an uncommented version of the code that specifies and runs the experiment.
# Note that it is very compact!

trial_loop = SampleLoopActor(10^6, ECDFActor(get_x, EmpiricalCDF()));
trial!(WalkPlan(WalkF(), StepLimitActor(10^3)), trial_loop);

# In the following we go through the same code step-by-step.

# ### Generating the samples and the trial

# A sample is a single trajectory, or walk. We will take `nsamples` samples.
nsamples = 10^6;

# Choose the number of steps per walk.
nsteps = 10^3;

# Create an emtpy empirical cumulative distribution function for floating point data.
ecdf = EmpiricalCDF()

# A trial is a collection of samples (walks) from which we collect statistics.
# The following instance of a `SampleLoopActor` specifies that we collect `nsamples` samples and that we
# build an empirical CDF of the final position (on the x-axis) of the walker after each walk. Below, we will
# use a one-dimensional walk, so `get_x` returns the position.
trial_loop = SampleLoopActor(nsamples, ECDFActor(get_x, ecdf));

# We used two `AbstractActors` above. `Actors` are treated (for the most part)
# in a uniform way within a sample, and in (a different)
# uniform way within a trial. This gives flexibility in designing experiments.

# We create a `WalkPlan` and run a trial of `nsamples` samples.
# The `WalkPlan` consists of  two parts;
# The first, a walk specification `WalkF()`, which is the default one-dimension walk on the integers.
# The second an action `StepLimitActor(nsteps)` to take after each step.
# `StepLimitActor(nsteps)` stops the walk if the number of steps exceeds `nsteps`.
# The `WalkPlan` specifies the sample and how it is collected.

# The `Actor` `trial_loop` was described above. It describes how to take several samples and actions to take
# afer each sample.
# In this case, which statistics to collect.
# So, the following line builds an ECDF of the final position of a one-dimensional walk after `nsteps` steps.
@time trial!(WalkPlan(WalkF(), StepLimitActor(nsteps)), trial_loop);

# We rescale the data so that the expected standard deviation is equal to `1`.
x = get_data(ecdf);
x ./= sqrt(nsteps);

# Test that the standard deviation and mean are as expected

## The mean should be near 0 and the standard deviation near 1
@show mean(ecdf), std(ecdf);

# We test the above results with a generous tolerance.
tolerance = 1e-3;

isapprox(std(ecdf), 1; atol = tolerance)
#-
isapprox(mean(ecdf), 0; atol = tolerance)

# We approximate the probability density function with a normalized `Histogram`
# and see that it looks reasonable.
using StatsBase: Histogram, fit, normalize
h = normalize(fit(Histogram, get_data(ecdf), -5.5:1.0:5.5));

println(h.weights);


