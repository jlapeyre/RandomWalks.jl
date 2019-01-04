module RandomWalks
using Distributions: Distribution, Exponential, Pareto
using EmpiricalCDFs

export AbstractLatticeWalk, LatticeWalk
export init!
export LatticeWalkPlan, trial!
export AbstractTrialCallback

export get_position, get_waiting_time, get_decay_rate, get_time, get_nsteps, step!,
    addto_time!, addto!

include("utils.jl")

include("Points.jl")
using .Points

include("LatticeVars.jl")
using .LatticeVars

include("Lattices.jl")
using .Lattices

include("Walks.jl")
using .Walks

include("Actors.jl")
using .Actors

include("LatticeWalks.jl")
using .LatticeWalks

end # module
