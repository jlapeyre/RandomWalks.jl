module WalksBase
using ..Points
import ..Points: get_x

import ..LatticeVars.init!
using Printf: @sprintf

export AbstractWalkGeneral, AbstractWalk, Walk, MortalWalk, MortalWalkStatus,
    step!, get_position, get_x, get_y, get_z, set_position!, addto_time!, get_nsteps, incr_nsteps!, set_time!, get_time, set_status!

export set_decayed, unset_decayed

abstract type AbstractWalkGeneral end

# FIXME: rationalize AbstractWalk / Walk methods
"""
    abstract type AbstractWalk{N, Time, P}

`N`: the dimension of the walk.
`T`: The type of the time.
`P`: the type representing the point.
"""
abstract type AbstractWalk{N} <: AbstractWalkGeneral
end

function step!(walk::AbstractWalk{1})
    incr = rand(Bool) ? +1 : -1
    addto_position!(walk, incr)
    incr_nsteps!(walk)
    return true
end

function step!(walk::AbstractWalk{2})
    incr = unit_vectors2[rand(1:4)]
    addto_position!(walk, incr)
    incr_nsteps!(walk)
    return true
end

function step!(walk::AbstractWalk{3})
    incr = unit_vectors3[rand(1:6)]
    addto_position!(walk, incr)
    incr_nsteps!(walk)
    return true
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

###
### Walk
###

"""
    struct Walk

Represents the state of the walk
"""
mutable struct Walk{N, TimeT, NStepsT, PosT} <: AbstractWalk{N}
    time::TimeT
    position::PosT
    nsteps::NStepsT
end

function init!(walk::Walk{<:Any, TimeT, NStepsT, PosT}) where {TimeT, NStepsT, PosT}
    set_time!(walk, zero(TimeT))
    set_position!(walk, zero(PosT))
    set_nsteps!(walk, zero(NStepsT))
    return nothing
end

const _default_walk_time_type = Float64
const _default_walk_nsteps_type = Int
const _default_walk_coord_type = Int

function Walk(p=Point(zero(_default_walk_coord_type)); time = zero(_default_walk_time_type), nsteps = zero(_default_walk_nsteps_type))
    return Walk{length(p), typeof(time), typeof(nsteps), typeof(p)}(time, p, nsteps)
end

function Walk{N, PosElT, TimeT, NStepsT}() where {N, PosElT, TimeT, NStepsT}
    return Walk(zero(Point{N, PosElT}); time = zero(TimeT), nsteps = zero(NStepsT))
end

Walk{N, PosElT, TimeT}() where {N, PosElT, TimeT} = Walk{N, PosElT, TimeT, _default_walk_nsteps_type}()
Walk{N, PosElT}() where {N, PosElT} = Walk{N, PosElT, _default_walk_time_type}()
Walk{N}() where {N} = Walk{N, _default_walk_coord_type}()

function Base.show(io::IO, w::Walk)
    print(io, "Walk(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ")")
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
MortalWalk(walk::AbstractWalk{N}) where {N} = MortalWalk(walk, true)

for f in (:get_position, :set_position!, :addto_position!, :get_time, :set_time!, :get_nsteps,
          :set_nsteps!, :incr_nsteps!, :addto_time!)
    @eval ($f)(w::MortalWalk, args...) = ($f)(w.walk, args...)
end

function Base.show(io::IO, w::MortalWalk)
    print(io, "MortalWalk(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ", status=", get_status(w), ")")
end

MortalWalk{N, PosElT, TimeT}() where {N, PosElT, TimeT} = MortalWalk(Walk{N, PosElT, TimeT}(), true)
MortalWalk{N, PosElT}() where {N, PosElT} = MortalWalk(Walk{N, PosElT}(), true)
MortalWalk{N}() where {N} = MortalWalk(Walk{N}(), true)
MortalWalk() = MortalWalk(Walk(), true)

function init!(w::MortalWalk)
    init!(w.walk)
    w.status = false
    return nothing
end

end # module WalksBase
