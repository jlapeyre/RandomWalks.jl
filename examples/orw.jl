using RandomWalks, Distributions, BenchmarkTools
using RandomWalks.LatticeVars
using RandomWalks.Lattices
using RandomWalks.Walks
using RandomWalks.Actors
using EmpiricalCDFs
using JDistributions: Delta

function orw()
    d = 2
    nsteps = 10^7
    ntrials = 10^1
    lattice = Lattice{d}(Delta(1))
    walk = Walk{d,Int}()
    lattice_walk = LatticeWalk(lattice, walk)
    step_limit_actor = StepLimitActor(nsteps)
    lattice_walk_plan = LatticeWalkPlan(lattice_walk, step_limit_actor)
    @time trial!(lattice_walk_plan, 1:ntrials, NullActor())
    return lattice_walk_plan
end

# d = 2
# nsteps = 10^7
# ntrials = 10^1

# lattice = Lattice{2}(Delta(1))
# walk = Walk{d,Int}()
# lattice_walk = LatticeWalk(lattice, walk)
# step_limit_actor = StepLimitActor(nsteps)
# lattice_walk_plan = LatticeWalkPlan(lattice_walk, step_limit_actor)

# trial!(lattice_walk_plan, 1:ntrials, NullActor())

nothing
