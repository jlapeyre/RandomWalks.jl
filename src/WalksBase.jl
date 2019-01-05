module WalksBase
using ..Points

import ..LatticeVars.init!
using Printf: @sprintf

export AbstractWalkGeneral, AbstractWalk, Walk, MortalWalk, MortalWalkStatus,
    step!, get_position, set_position!, addto_time!, get_nsteps, incr_nsteps!, set_time!, get_time

export set_decayed, unset_decayed

abstract type AbstractWalkGeneral end

# FIXME: rationalize AbstractWalk / Walk methods
"""
    abstract type AbstractWalk{N, Time, P}

`N`: the dimension of the walk.
`T`: The type of the time.
`P`: the type representing the point.
"""
abstract type AbstractWalk{N, TimeT, NStepsT, PosT} <: AbstractWalkGeneral
end

function Base.show(io::IO, w::AbstractWalk)
    print(io, "Walk(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ")")
end

function init!(walk::AbstractWalk{<:Any, TimeT, NStepsT, PosT}) where {TimeT, NStepsT, PosT}
    set_time!(walk, zero(TimeT))
    set_position!(walk, zero(PosT))
    set_nsteps!(walk, zero(NStepsT))
    return nothing
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

###
### Walk
###

"""
    struct Walk

Represents the state of the walk
"""
mutable struct Walk{N, TimeT, NStepsT, PosT} <: AbstractWalk{N, TimeT, NStepsT, PosT}
    time::TimeT
    position::PosT
    nsteps::NStepsT
end

const _default_walk_time_type = Float64
const _default_walk_nsteps_type = Int
const _default_walk_coord_type = Int

function Walk(p=Point(zero(_default_walk_coord_type)); time = zero(_default_walk_time_type), nsteps = zero(_default_walk_nsteps_type))
    return Walk{length(p), typeof(time), typeof(nsteps), typeof(p)}(time, p, nsteps)
end

function Walk{N, PosElT, TimeT, NStepsT}() where {N, PosElT, TimeT, NStepsT}
    Walk(zero(Point{N, PosElT}); time = zero(TimeT), nsteps = zero(NStepsT))
end

Walk{N, PosElT, TimeT}() where {N, PosElT, TimeT} = Walk{N, PosElT, TimeT, _default_walk_nsteps_type}()
Walk{N, PosElT}() where {N, PosElT} = Walk{N, PosElT, _default_walk_time_type}()
Walk{N}() where {N} = Walk{N, _default_walk_coord_type}()

"""
    struct MortalWalk

Represents the state of a mortal walk, i.e. a waker that "dies".
"""
mutable struct MortalWalk{N, TimeT, NStepsT, PosT, StatusT} <: AbstractWalk{N, TimeT, NStepsT, PosT}
    time::TimeT
    position::PosT
    nsteps::NStepsT
    status::StatusT
end

mutable struct MortalWalkStatus
    decayed::Bool
end

Base.show(io::IO, status::MortalWalkStatus) = print(io, "decayed = ", status.decayed)
MortalWalkStatus() = MortalWalkStatus(false)
set_decayed(mw::MortalWalk) = mw.status.decayed = true
unset_decayed(mw::MortalWalk) = mw.status.decayed = false

function MortalWalk(p=Point(zero(Float64)))
    T = Float64
    z = zero(T)
    nsteps = 0
    status = MortalWalkStatus()
    return MortalWalk{length(p), T, typeof(p), typeof(status)}(z, p, nsteps, status)
end

MortalWalk{N, T}() where {N, T} = MortalWalk(zero(Point{N, T}))
MortalWalk{N}() where {N} = MortalWalk(zero(Point{N, Float64}))

get_position(w::AbstractWalk) = w.position
set_position!(w::AbstractWalk, val) = w.position = val
addto_position!(w::AbstractWalk, val) = w.position += val
get_time(w::AbstractWalk) = w.time
set_time!(w::AbstractWalk, val) = w.time = val
get_nsteps(w::AbstractWalk) = w.nsteps
set_nsteps!(w::AbstractWalk, val) = w.nsteps = val
incr_nsteps!(w::AbstractWalk) = w.nsteps += 1
addto_time!(w::AbstractWalk, incr) = w.time = w.time + incr

end # module WalksBase
