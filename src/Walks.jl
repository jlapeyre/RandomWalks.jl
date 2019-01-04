module Walks
using ..Points

using Printf: @sprintf

export AbstractWalk, Walk, MortalWalk, MortalWalkStatus,
    step!, get_position, set_position!, addto_time!, get_nsteps, incr_nsteps!, set_time!, get_time

export set_decayed, unset_decayed

"""
    abstract type AbstractWalk{N, Time, P}

`N`: the dimension of the walk.
`T`: The type of the time.
`P`: the type representing the point.
"""
abstract type AbstractWalk{N, Time, P} end

function Base.show(io::IO, w::AbstractWalk)
    print(io, "Walk(time=", @sprintf("%e", get_time(w)), ", position= ",
          get_position(w), ", nsteps=", get_nsteps(w), ")")
end

function init!(walk::AbstractWalk{<:Any, T, P}) where {T, P}
    set_time!(walk, zero(T))
    set_position!(walk, zero(P))
    set_nsteps!(walk, 0)
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

###
### Walk
###

"""
    struct Walk

Represents the state of the walk
"""
mutable struct Walk{N, Time, P} <: AbstractWalk{N, Time, P}
    time::Time
    position::P
    nsteps::Int
end

function Walk(p=Point(zero(Float64)))
    T = Float64
    z = zero(T)
    nsteps = 0
    return Walk{length(p), T, typeof(p)}(z, p, nsteps)
end

Walk{N, T}() where {N, T} = Walk(zero(Point{N, T}))
Walk{N}() where {N} = Walk(zero(Point{N, Float64}))

"""
    struct MortalWalk

Represents the state of a mortal walk, i.e. a waker that "dies".
"""
mutable struct MortalWalk{N, Time, P, Status} <: AbstractWalk{N, Time, P}
    time::Time
    position::P
    nsteps::Int
    status::Status
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

end # module Walks
