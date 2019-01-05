using RandomWalks, Distributions, BenchmarkTools
using RandomWalks.Points
using RandomWalks.LatticeVars
using RandomWalks.Lattices
using RandomWalks.WalksBase
using RandomWalks.Walks
using RandomWalks.Actors
using EmpiricalCDFs
using JDistributions: Delta

function orw()
    d = 2
    nsteps = 10^3
    ntrials = 10^1
    lattice = Lattice{d}(Delta(1))
    walk = Walk{d,Int}()
    lattice_walk = LatticeWalk(lattice, walk)
    step_limit_actor = StepLimitActor(nsteps)
    walk_plan = WalkPlan(lattice_walk, step_limit_actor)
    @time trial!(walk_plan, SampleLoopActor(ntrials))
    return walk_plan
end

# d = 2
# nsteps = 10^7
# ntrials = 10^1

# lattice = Lattice{2}(Delta(1))
# walk = Walk{d,Int}()
# lattice_walk = LatticeWalk(lattice, walk)
# step_limit_actor = StepLimitActor(nsteps)
# walk_plan = LatticeWalkPlan(lattice_walk, step_limit_actor)

# trial!(walk_plan, 1:ntrials, NullActor())

nothing
