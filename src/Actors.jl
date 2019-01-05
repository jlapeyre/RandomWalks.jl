module Actors

using ..WalksBase: get_nsteps, get_time, get_position
using ..Points: get_x
using EmpiricalCDFs

export AbstractActor, AbstractSampleActor, act!, ActorSet, NullActor, StepLimitActor
export StoringActor, storing_position_actor, storing_num_sites_visited_actor,
    storing_nsteps_actor, storing_nsteps_position_actor
export ECDFActor, ECDFAction, get_cdfs
export SampleLoop

abstract type AbstractActor end

init!(_::AbstractActor) = nothing

abstract type AbstractSampleActor <: AbstractActor
end

###
### ActorSet
###

"""
    struct ActorSet

blah
"""
struct ActorSet{T <: Tuple} <: AbstractActor
    actors::T
end

ActorSet(actors::AbstractActor...) = ActorSet((actors...,))
ActorSet(actor::AbstractActor) = ActorSet((actor,))

init!(actor_set::ActorSet) = foreach(actor -> init!(actor), actor_set.actors)

function act!(actor_set::ActorSet, args...)
    for actor in actor_set.actors
        act!(actor, args...)::Bool || return false
    end
    return true
end

###
### NullActor
###

struct NullActor <: AbstractActor
end
act!(_::NullActor, args...) = true
#init!(_::NullActor) = nothing

###
### StepLimitActor
###

mutable struct StepLimitActor <: AbstractActor
    max_step_limit::Int
    hit_max_step_limit::Bool
    StepLimitActor(n=10) = new(n, false)
end

function act!(actor::StepLimitActor, latwalk)
    nsteps = get_nsteps(latwalk)
    if nsteps >= actor.max_step_limit
        actor.hit_max_step_limit = true
        return false
    end
    return true
end

function init!(actor::StepLimitActor)
    actor.hit_max_step_limit = false
    return nothing
end

function Base.show(io::IO, actor::StepLimitActor)
    print(io, "StepLimitActor(n=", actor.max_step_limit,
          ", hit=", actor.hit_max_step_limit, ")")
end

###
### StoredValues
###

mutable struct StoredValues{T, X}
    times::T
    values::X
    current_index::Int
end

Base.show(io::IO, sv::StoredValues) = Base.show(io, MIME("text/plain"), sv)

function Base.show(io::IO, m::typeof(MIME("text/plain")), sv::StoredValues{T}) where T
                   println(io, "StoredValues{times_type=$T}(current_index=", sv.current_index, ")")
                   maxind = length(sv.values[1])
    show(io, m, [sv.times[1:maxind] (x[1:maxind] for x in sv.values)... ])
end

get_target_time(sv::StoredValues) = sv.times[sv.current_index]
increment_current_index(sv::StoredValues) = sv.current_index += 1
Base.lastindex(sv::StoredValues) = lastindex(sv.times)
get_current_index(sv::StoredValues) = sv.current_index
reset_current_index!(sv::StoredValues) = sv.current_index = 1
get_values(sv::StoredValues) = sv.values
get_times(sv::StoredValues) = sv.times

Base.empty!(sv::StoredValues) = empty!(sv.values)
function Base.empty!(sv::StoredValues{<:Any, <:Tuple})
    for v in sv.values
        empty!(v)
    end
end

StoredValues(times; value_types = Float64) = _StoredValues(times, value_types)

function _StoredValues(times::T, value_types) where T
    initial_index = 1
    return StoredValues{T, Vector{value_types}}(times, zeros(value_types,0), initial_index)
end

function _StoredValues(times::T, value_types::Tuple) where T
    initial_index = 1
    tup = ((zeros(t,0) for t in value_types)...,)
    return StoredValues{T, typeof(tup)}(times, tup, initial_index)
end

###
### StoringActor
###

struct StoringActor{T, X, F} <: AbstractActor
    stored_values::StoredValues{T, X}
    storing_func::F
end

function StoringActor(times, storing_func, value_types)
    return StoringActor(StoredValues(times; value_types=value_types), storing_func)
end

function StoringActor(times, storing_func::Tuple, value_types::Tuple)
    return StoringActor(StoredValues(times; value_types=value_types), storing_func)
end

StoringActor(times, storing_func; value_types=Float64) = StoringActor(times, storing_func, value_types)

function act!(actor::StoringActor, system)
    get_current_index(actor.stored_values) > lastindex(actor.stored_values) && return false # terminate walk
    while get_time(system) >= get_target_time(actor.stored_values)
        push!(actor.stored_values.values, actor.storing_func(system))
        increment_current_index(actor.stored_values)
        get_current_index(actor.stored_values) > lastindex(actor.stored_values) && return false # terminate walk
    end
    return true
end

function act!(actor::StoringActor{T, <:Tuple, <:Tuple}, system) where T
    get_current_index(actor.stored_values) > lastindex(actor.stored_values) && return false # terminate walk
    while get_time(system) >= get_target_time(actor.stored_values)
        for (array, func) in zip(actor.stored_values.values, actor.storing_func)
            push!(array, func(system))
        end
        increment_current_index(actor.stored_values)
        get_current_index(actor.stored_values) > lastindex(actor.stored_values) && return false # terminate walk
    end
    return true
end

function init!(actor::StoringActor)
    reset_current_index!(actor.stored_values)
    empty!(actor.stored_values)
    return nothing
end

for f in (:get_values, :get_times)
    @eval ($f)(sa::StoringActor) = ($f)(sa.stored_values)
end

Base.getindex(sa::StoringActor, ind1::Integer, inds...) = _getindex(sa, Val(ind1), inds...)
Base.getindex(sa::StoringActor, ind1::Integer) = _getindex(sa, Val(ind1))
_getindex(sa::StoringActor, ::Val{1}, inds...) = get_times(sa)[inds...]
_getindex(sa::StoringActor, ::Val{n}, inds...) where {n} = get_values(sa)[n-1][inds...]
_getindex(sa::StoringActor, ::Val{1}) = get_times(sa)
_getindex(sa::StoringActor, ::Val{n}) where {n} = get_values(sa)[n-1]
Base.length(sa::StoringActor) = length(get_values(sa)) + 1
Base.size(sa::StoringActor) = (length(sa), ((length(sa[i]) for i in 1:length(sa))...,))

function Base.show(io::IO, actor::StoringActor)
    print(io, "StoringActor(", actor.stored_values, ")")
end

###
### basic instances of StoringActor
###

# FIXME: allowing single arrays rather than tuple of arrays (possibly of length 1) increases complexity
# and amount of code that must be maintained: Must support only tuples.
# hmmm. maybe convert single array and single type to tuples upon construction
storing_position_actor(times) = StoringActor(times, (system) -> get_x(get_position(system)))

function storing_num_sites_visited_actor(times)
    funcs = ((system) -> get_nsteps(system),)
    value_types = (Int,)
    return StoringActor(times, funcs; value_types=value_types)
end

function storing_nsteps_actor(times)
    funcs = ((system) -> get_nsteps(system), )
    value_types = (Int, )
    return StoringActor(times, funcs; value_types=value_types)
end

function storing_nsteps_position_actor(times)
    funcs = ((system) -> get_nsteps(system), (system) -> get_x(get_position(system)))
    return StoringActor(times, funcs; value_types=(Int, Float64))
end

###
### ECDFActor
###

struct ECDFActor{T, F} <: AbstractActor
    ecdfs::T
    storing_func::F
end

function act!(actor::ECDFActor, _...)
    actor.storing_func()
    return true
end

#init!(actor::ECDFActor) = true

get_cdfs(ea::ECDFActor) = ea.ecdfs

function ECDFActor(sa::StoringActor)
    storage_array = sa[2] # By default, use the first data array.
    times = get_times(sa)
    ecdfs = [EmpiricalCDF{eltype(storage_array)}() for i in 1:length(times)]
    storing_func = function(_...)
        for i in 1:length(storage_array)
            push!(ecdfs[i], storage_array[i])
        end
        return true
    end
    return ECDFActor(ecdfs, storing_func)
end

function Base.sort!(actor::ECDFActor)
    for cdf in actor.ecdfs
        sort!(cdf)
    end
    return actor
end

###
### SampleLoop
###

struct SampleLoop{Iter, ActorT}
    iter::Iter
    actor::ActorT
end

end # module Actors
