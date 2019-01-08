module WalksBase
using ..Points
import ..Points: get_x, Biased, Unbiased

import ..LatticeVars.init!
using Printf: @sprintf
import Distributions

export AbstractWalkGeneral, AbstractWalk, WalkB, WalkF, WalkOpts, Mortal, MortalOpts,
    AMortalWalk, MortalWalk, MortalWalkStatus,
    step!, step_increment!, get_position, get_x, get_y, get_z, set_position!, addto_time!, get_nsteps,
    incr_nsteps!, set_time!, get_time, set_status!

export walk_opts

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
    struct WalkB

Represents the state of the walk
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
const _default_walk_nsteps_type = Int
const _default_walk_coord_type = Int

function WalkB(p=Point(zero(_default_walk_coord_type)); time = zero(_default_walk_time_type), nsteps = zero(_default_walk_nsteps_type))
    return WalkB{length(p), typeof(time), typeof(p)}(time, p, nsteps)
end

function WalkB{N, PosElT, TimeT}() where {N, PosElT, TimeT}
    return WalkB(zero(Point{N, PosElT}); time = zero(TimeT), nsteps = zero(Int))
end

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
    status::StatusT
    stepsample::StepSampleT
    stepdisplacement::StepDispT
end

function WalkOpts(; status = None(), stepsample = Unbiased(), stepdisplacement = NearestNeighbor())
    return WalkOpts(status, stepsample, stepdisplacement)
end

# StatusT
struct None
end

# StatusT
mutable struct Mortal
    alive::Bool
end
Mortal() = Mortal(true)
get_status(s::Mortal) = w.alive
set_status!(s::Mortal, state) = s.alive = state


# StepDispT
struct NearestNeighbor
end

# StepDispT
struct Continuous{DistT}
    dist::DistT
end
Continuous() = Continuous(Distributions.Normal())

const MortalOpts = WalkOpts{<:Mortal, <:Any, <:Any}

function walk_opts(walk::AbstractWalk = WalkB(); status = None(), stepsample = Unbiased(), stepdisplacement = NearestNeighbor())
    return WalkOpts(status, stepsample, stepdisplacement)
end

struct WalkF{N, WT, OptT} <: AbstractWalk{N}
    walk::WT
    opts::OptT
end

const AMortalWalk = WalkF{<:Any, <:Any, <:MortalOpts}

function WalkF(w::AbstractWalk{N} = WalkB{1}(); kwargs...) where {N}
    wo = walk_opts(w; kwargs...)
    return WalkF{N, typeof(w), typeof(wo)}(w, wo)
end

init!(wf::WalkF) = init!(wf.walk)

for f in (:get_status, :set_status!)
    @eval ($f)(w::WalkOpts, args...) = ($f)(w.status, args...)
    @eval ($f)(w::WalkF, args...) = ($f)(w.opts, args...)
end

# TODO: Why to I need V1, V2, V3, rather than <:Any, .... ?
function step_increment!(walkf::WalkF{N, WalkB{N, V1, PosT}, WalkOpts{V2, StepSampleT, V3}}) where {N, PosT, StepSampleT, V1, V2, V3}
     return addto_position!(walkf.walk, rand(walkf.opts.stepsample, UnitVector{PosT}))
end

for f in (:get_position, :set_position!, :addto_position!, :get_time, :set_time!, :get_nsteps,
          :set_nsteps!, :incr_nsteps!, :addto_time!, :get_x)
    @eval ($f)(wf::WalkF, args...) = ($f)(wf.walk, args...)
end

###
### MortalWalk
###

"""
    struct MortalWalk

Represents the state of a mortal walk, i.e. a waker that "dies".
"""
mutable struct MortalWalk{N, WalkT, StatusT} <: AbstractWalk{N}
    walk::WalkT
    status::StatusT
end

get_status(w::MortalWalk) = w.status
set_status!(w::MortalWalk, state) = w.status = state

MortalWalk(walk::AbstractWalk{N}, status) where {N} = MortalWalk{N, typeof(walk), typeof(status)}(walk, status)
MortalWalk(walk::AbstractWalk{N} = WalkB()) where {N} = MortalWalk(walk, true)

for f in (:get_position, :set_position!, :addto_position!, :get_time, :set_time!, :get_nsteps,
          :set_nsteps!, :incr_nsteps!, :addto_time!, :step!)
    @eval ($f)(w::MortalWalk, args...) = ($f)(w.walk, args...)
end

function Base.show(io::IO, w::MortalWalk)
    print(io, "MortalWalk(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ", status=", get_status(w), ")")
end

function init!(w::MortalWalk)
    init!(w.walk)
    w.status = false
    return nothing
end

end # module WalksBase
