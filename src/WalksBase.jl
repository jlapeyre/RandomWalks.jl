module WalksBase
using ..Points
import ..Points: get_x, Biased, Unbiased

import ..LatticeVars.init!
using Printf: @sprintf
import Distributions

export AbstractWalkGeneral, AbstractWalk, WalkB, WalkF, WalkOpts, Mortal, MortalOpts,
    MortalWalk, MortalWalkStatus,
    step!, step_increment!, get_position, get_x, get_y, get_z, set_position!, addto_time!, get_nsteps,
    incr_nsteps!, set_time!, get_time, set_status!, try_step_increment

export walk_opts, Continuous, ContinuousOpts, ContinuousWalk

export set_decayed, unset_decayed

abstract type AbstractWalkGeneral end

# FIXME: rationalize AbstractWalk / WalkB methods
"""
    abstract type AbstractWalk{N, Time, P}

`N`: the dimension of the walk.
`T`: The type of the time.
`P`: the type representing the point.
"""
abstract type AbstractWalk{N} <: AbstractWalkGeneral
end

get_position(w::AbstractWalk) = w.position
get_x(w::AbstractWalk) = get_x(w.position)
set_position!(w::AbstractWalk, val) = w.position = val
addto_position!(w::AbstractWalk, val) = w.position += val
get_time(w::AbstractWalk) = w.time
set_time!(w::AbstractWalk, val) = w.time = val
get_nsteps(w::AbstractWalk) = w.nsteps
set_nsteps!(w::AbstractWalk, val) = w.nsteps = val
incr_nsteps!(w::AbstractWalk) = w.nsteps += 1
addto_time!(w::AbstractWalk, incr) = w.time = w.time + incr

function step!(walk::AbstractWalk)
    step_increment!(walk)
    incr_nsteps!(walk)
    return true
end

###
### WalkB
###

"""
    mutable struct WalkB{N, TimeT, PosT} <: AbstractWalk{N}
        time::TimeT
        position::PosT
        nsteps::Int
    end

Represents the "basic" state of the walk.
`time` is the current physical time.
`position` is the current position.
`nsteps` is the current number of steps taken.

Often, the "physical time" is the same as the number of steps.
In this case, the algorithms typically do not update `time`.
"""
mutable struct WalkB{N, TimeT, PosT} <: AbstractWalk{N}
    time::TimeT
    position::PosT
    nsteps::Int
end

function step_increment!(walk::WalkB{<:Any, <:Any, PosT}) where {PosT}
    return addto_position!(walk, rand(UnitVector{PosT}))
end

function init!(walk::WalkB{<:Any, TimeT, PosT}) where {TimeT, PosT}
    set_time!(walk, zero(TimeT))
    set_position!(walk, zero(PosT))
    set_nsteps!(walk, zero(Int))
    return nothing
end

const _default_walk_time_type = Float64
const _default_walk_coord_type = Int

function WalkB(p=Point(zero(_default_walk_coord_type)); time = zero(_default_walk_time_type), nsteps = zero(Int))
    return WalkB{length(p), typeof(time), typeof(p)}(time, p, nsteps)
end

WalkB{N, PosElT, TimeT}() where {N, PosElT, TimeT} = WalkB(zero(Point{N, PosElT}); time = zero(TimeT), nsteps = zero(Int))
WalkB{N, PosElT}() where {N, PosElT} = WalkB{N, PosElT, _default_walk_time_type}()
WalkB{N}() where {N} = WalkB{N, _default_walk_coord_type}()

function Base.show(io::IO, w::WalkB)
    print(io, "WalkB(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ")")
end

###
### WalkOpts
###

struct WalkOpts{StatusT, StepSampleT, StepDispT}
    status_type::StatusT
    stepsample::StepSampleT
    stepdisplacement::StepDispT
end

function WalkOpts(; status_type = Nothing(), stepsample = Unbiased(), stepdisplacement = NearestNeighbor())
    return WalkOpts(status_type, stepsample, stepdisplacement)
end

# StepDispT
struct NearestNeighbor
end

# StepDispT
struct Continuous{DistT}
    dist::DistT
end
Continuous() = Continuous(Distributions.Normal())

function walk_opts(walk::AbstractWalk = WalkB();
                   status_type = Nothing(), stepsample = Unbiased(), stepdisplacement = NearestNeighbor())
    return WalkOpts(status_type, stepsample, stepdisplacement)
end

"""
    struct WalkF{N, WT, OptT} <: AbstractWalk{N}
        walk::WT
        opts::OptT
    end

Represents the "Full" specification and state of the walk,
via the "basic" walk state `walk`, and the options `opts`.
"""
struct WalkF{N, WT, OptT} <: AbstractWalk{N}
    walk::WT
    opts::OptT
end

function WalkF(w::AbstractWalk{N} = WalkB{1}(); kwargs...) where {N}
    wo = walk_opts(w; kwargs...)
    return WalkF{N, typeof(w), typeof(wo)}(w, wo)
end

mutable struct Mortal
    alive::Bool
end

Mortal() = Mortal(true)
get_status(s::Mortal) = w.alive
set_status!(s::Mortal, state) = s.alive = state
const MortalOpts = WalkOpts{<:Mortal, <:Any, <:Any}
const MortalWalk = WalkF{<:Any, <:Any, <:MortalOpts}
MortalOpts(opts::WalkOpts) = WalkOpts(Mortal(), opts.stepsample, opts.stepdisplacement)
MortalWalk(w = WalkB()) = WalkF(w, status_type = Mortal())

function MortalWalk(wf::WalkF{N}) where {N}
    opts = MortalOpts(wf.opts)
    return WalkF{N, typeof(wf.walk), typeof(opts)}(wf.walk, opts)
end

init!(wf::WalkF) = init!(wf.walk)

for f in (:get_status, :set_status!)
    @eval ($f)(w::WalkOpts, args...) = ($f)(w.status_type, args...)
    @eval ($f)(w::WalkF, args...) = ($f)(w.opts, args...)
end

# TODO: try removing extra params
function try_step_increment(walkf::WalkF{N, WalkB{N, V1, PosT}, <:Any}) where {N, PosT, V1}
    return rand(walkf.opts.stepsample, UnitVector{PosT})
end

try_step_increment(walk::WalkB{N, V1, PosT}) where {N, PosT, V1} = rand(UnitVector{PosT})

# FIXME: Why does this fail with  V1 --> <:Any
function step_increment!(walkf::WalkF{N, WalkB{N, V1, PosT}, <:Any}) where {N, PosT, V1}
     return addto_position!(walkf.walk, rand(walkf.opts.stepsample, UnitVector{PosT}))
end

const ContinuousOpts = WalkOpts{<: Any, <: Any, <: Continuous}
const ContinuousWalk = WalkF{<:Any, <:Any, <:ContinuousOpts}
ContinuousWalk(w = WalkB(), dist=Distributions.Normal()) = WalkF(w, stepdisplacement = Continuous(dist))

function step_increment!(walkf::WalkF{N, WalkB{N, V1, V2}, <:ContinuousOpts}) where {N, V1, V2}
      return addto_position!(walkf.walk, rand(walkf.opts.stepdisplacement.dist))
end

for f in (:get_position, :set_position!, :addto_position!, :get_time, :set_time!, :get_nsteps,
          :set_nsteps!, :incr_nsteps!, :addto_time!, :get_x)
    @eval ($f)(wf::WalkF, args...) = ($f)(wf.walk, args...)
end

end # module WalksBase
