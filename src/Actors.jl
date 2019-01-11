module Actors

using ..WalksBase: get_nsteps, get_time, get_position
using ..Points: get_x
using ..LatticeVars: get_num_sites_visited
import ..LatticeVars: init!
using EmpiricalCDFs
import EmpiricalCDFs: get_data
import Statistics
export AbstractActor, act!, ActorSet, NullActor, StepLimitActor, ErrorOnExitActor, FirstReturnActor,
    get_actor_value
export ActorExitException

export StoringActor, init!, storing_position_actor,
    storing_num_sites_visited_actor, get_times, get_ecdf_times, get_values,
    get_stored_values, storing_nsteps_actor, storing_nsteps_position_actor,
    storing_nsteps_num_sites_visited_actor

export CountActor, get_count
export ECDFsActor, get_cdfs, ECDFActor, ECDFValueActor, get_cdf, unpack, prune
export SampleLoopActor, get_actor, ProgressIter

###
### AbstractActor
###

abstract type AbstractActor end

init!(_::AbstractActor) = nothing
finalize!(_::AbstractActor) = nothing
condition_satisfied(_::AbstractActor) = true
# Following makes detecting bugs harder. Leave here to avoid temptation.
# act!(_::AbstractActor, args...) = true

###
### NullActor
###

struct NullActor <: AbstractActor
end
act!(_::NullActor, args...) = true

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

init!(actor::StepLimitActor) = (actor.hit_max_step_limit = false; nothing)
condition_satisfied(actor::StepLimitActor) = actor.hit_max_step_limit

function Base.show(io::IO, actor::StepLimitActor)
    print(io, "StepLimitActor(n=", actor.max_step_limit,
          ", hit=", actor.hit_max_step_limit, ")")
end

###
### ErrorOnExitActor
###

struct ActorExitException{T} <: Exception
    actor::T
    msg::String
end

ActorExitException(actor::T) where {T} = ActorExitException(actor, "actor of type $T exited")
Base.showerror(io::IO, e::ActorExitException) = print(io, e.msg)

struct ErrorOnExitActor{T <: AbstractActor} <: AbstractActor
    child_actor::T
end

for f  in (:init!, :condition_satisfied)
    @eval ($f)(actor::ErrorOnExitActor, args...) = ($f)(actor.child_actor, args...)
end

function act!(actor::ErrorOnExitActor, arg)
    if ! act!(actor.child_actor, arg)
        throw(ActorExitException(actor.child_actor))
    end
    return true
end

###
### CountActor
###

mutable struct Counter
    c::Int
end
Counter() = Counter(0)
init!(counter::Counter) = counter.c = 0
increment(counter::Counter) = counter.c += 1
get_count(counter::Counter) = counter.c

struct CountActor{F} <: AbstractActor
    counter::Counter
    counting_func::F
end

function CountActor(child_actor::AbstractActor)
    CountActor(Counter(), () -> condition_satisfied(child_actor))
end

for f in (:increment, :get_count, :init!)
    @eval ($f)(actor::CountActor, args...) = ($f)(actor.counter, args...)
end
get_actor_value(actor::CountActor) = get_count(actor.counter)

function act!(actor::CountActor, _system)
    if actor.counting_func()
        increment(actor.counter)
    end
    return true
end

###
### FirstReturnActor
###

"""
    FirstReturnActor <: AbstractActor

Records and returns `true`, and the step number if the position is the origin.
"""
mutable struct FirstReturnActor <: AbstractActor
    return_step_num::Int
    has_walker_returned::Bool
end

FirstReturnActor() = FirstReturnActor(0, false)

init!(actor::FirstReturnActor) = (actor.has_walker_returned = false; actor.return_step_num = 0; nothing)

function act!(actor::FirstReturnActor, system)
    iszero(get_position(system)) || return true
    actor.has_walker_returned = true
    actor.return_step_num = get_nsteps(system)
    return false
end

condition_satisfied(actor::FirstReturnActor) = actor.has_walker_returned
get_actor_value(actor::FirstReturnActor) = actor.return_step_num

###
### ActorSet
###

"""
    struct ActorSet

A set of several `Actors` to be applied sequentially.
If one of the set returns `false`, then `ActorSet` immediately returns false.
"""
struct ActorSet{T <: Tuple} <: AbstractActor
    actors::T
end

ActorSet(child_actors::AbstractActor...) = ActorSet((child_actors...,))
ActorSet(child_actor::AbstractActor) = ActorSet((child_actor,))
init!(actor_set::ActorSet) = foreach(actor -> init!(actor), actor_set.actors)

function act!(actor_set::ActorSet, args...)
    for actor in actor_set.actors
        act!(actor, args...)::Bool || return false
    end
    return true
end

###
### StoredValues
###

mutable struct StoredValues{T, X}
    times::T
    values::X
    current_index::Int
end

function Base.getindex(sv::StoredValues, ind1, ind2)
    return sv.values[ind2][ind1]
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

StoringActor(times, storing_func; value_types=Float64) = StoringActor(times, storing_func, value_types)
StoringActor(times, storing_func, value_types) = StoringActor(StoredValues(times; value_types=value_types), storing_func)
StoringActor(times, storing_func::Tuple, value_types::Tuple) = StoringActor(StoredValues(times; value_types=value_types), storing_func)

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
get_stored_values(sa::StoringActor) = sa.stored_values

Base.getindex(sa::StoringActor, ind1::Integer, inds...) = _getindex(sa, Val(ind1), inds...)
Base.getindex(sa::StoringActor, ind1::Integer) = _getindex(sa, Val(ind1))
_getindex(sa::StoringActor, ::Val{1}, inds...) = get_times(sa)[inds...]
_getindex(sa::StoringActor, ::Val{n}, inds...) where {n} = get_values(sa)[n-1][inds...]
_getindex(sa::StoringActor, ::Val{1}) = get_times(sa)
_getindex(sa::StoringActor, ::Val{n}) where {n} = get_values(sa)[n-1]
Base.length(sa::StoringActor) = length(get_values(sa)) + 1
Base.size(sa::StoringActor) = (length(sa), ((length(sa[i]) for i in 1:length(sa))...,))
Base.show(io::IO, actor::StoringActor) = print(io, "StoringActor(", actor.stored_values, ")")

###
### Some instances of StoringActor
###

# FIXME: allowing single arrays rather than tuple of arrays (possibly of length 1) increases complexity
# and amount of code that must be maintained: Must support only tuples.
# hmmm. maybe convert single array and single type to tuples upon construction
storing_position_actor(times) = StoringActor(times, (system) -> get_x(get_position(system)))

function storing_num_sites_visited_actor(times)
    funcs = ((system) -> get_num_sites_visited(system),)
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

function storing_nsteps_num_sites_visited_actor(times)
    funcs = ((system) -> get_nsteps(system), (system) -> get_num_sites_visited(system))
    value_types = (Int, Int)
    return StoringActor(times, funcs; value_types=value_types)
end

###
### ECDFActor
###

struct ECDFActor{T <: AbstractEmpiricalCDF, F, FC} <: AbstractActor
    action_func::F
    ecdf::T
    condition_func::FC
end

ECDFActor(action_func, ecdf = EmpiricalCDF()) = ECDFActor(action_func, ecdf, _ -> true)
init!(actor::ECDFActor) = (empty!(actor.ecdf); nothing)
finalize!(actor::ECDFActor) = (sort!(actor.ecdf); nothing)

function act!(actor::ECDFActor, system)
    if actor.condition_func(system)
        push!(actor.ecdf, actor.action_func(system))
    end
    return true
end

get_cdf(ea::ECDFActor) = ea.ecdf

"""
    ECDFValueActor(child_actor::AbstractActor)

Builds a CDF for any `child_actor` that implements `condition_satisfied` and `get_actor_value`.
"""
function ECDFValueActor(child_actor::AbstractActor)
    ecdf = EmpiricalCDF{typeof(get_actor_value(child_actor))}()
    condition_func = _ -> condition_satisfied(child_actor)
    action_func = _ -> get_actor_value(child_actor)
    return ECDFActor(action_func, ecdf, condition_func)
end

###
### ECDFsActor
###

# In some cases, we may not need, or even have, a child_actor
struct ECDFsActor{CDFT, F} <: AbstractActor
    ecdfs_times::CDFT
    storing_func::F
end

get_ecdf_times(ea::ECDFsActor) = ea.ecdfs_times

struct ECDFsTimes{TimeT, CDFT}
    times::TimeT
    ecdfs::CDFT
end
get_times(et::ECDFsTimes) = et.times
get_cdfs(et::ECDFsTimes) = et.ecdfs
unpack(et::ECDFsTimes) = [get_times(et) get_cdfs(et)]

function prune(et::ECDFsTimes; f = x -> !isempty(x))
    good_inds = unique(getindex.(findall(f, et.ecdfs),1))
    new_times = et.times[good_inds]
    new_ecdfs = et.ecdfs[good_inds,:]
    return ECDFsTimes(new_times, new_ecdfs)
end

function Base.show(io::IO, actor::ECDFsActor)
    print(io, "ECDFsActor{", typeof(get_ecdf_times(actor)), ", Func, ")
    print(io, "}")
end

act!(actor::ECDFsActor, system) = (actor.storing_func(system); true)
get_cdfs(ea::ECDFsActor) = get_cdfs(get_ecdf_times(ea))

function init!(actor::ECDFsActor)
    empty!(actor)
    nothing
end

finalize!(actor::ECDFsActor) = (sort!(actor); nothing)

# TODO: Fix indexing. Time should not be in index value 1
function ECDFsActor(storing_actor::StoringActor)
    times = get_times(storing_actor)
    ecdfs = [EmpiricalCDF{eltype(storing_actor[j])}() for i in 1:length(times), j in 2:length(storing_actor)]
    ecdfs_times = ECDFsTimes(times, ecdfs)
    storing_func = function(_...)
        for j in 2:length(storing_actor)
            for i in 1:length(storing_actor[j])
                push!(ecdfs[i, j-1], storing_actor[j][i])
            end
        end
        return true
    end
    return ECDFsActor(ecdfs_times, storing_func)
end


get_times(a::ECDFsActor) = get_times(get_ecdf_times(a))
unpack(a::ECDFsActor) = unpack(get_ecdf_times(a))

for f in (:sort!, :empty!)
    @eval function Base.$(f)(actor::ECDFsActor)
        ecdfs = get_cdfs(get_ecdf_times(actor))
        for cdf in ecdfs
           ($f)(cdf)
        end
        return actor
    end
end

get_data(cdf::ECDFActor) = get_data(cdf.ecdf)

for f in (:length, :size, :minimum, :maximum, :extrema, :issorted, :iterate, :getindex,
          :lastindex, :firstindex, :eltype, :view)
    @eval begin
        Base.$(f)(cdf::ECDFActor, args...) = $(f)(cdf.ecdf, args...)
#        Base.$(f)(cdf::ECDFsActor, ind, args...) = $(f)(cdf.ecdfs[ind], args...)
    end
end

for f in (:mean, :median, :middle, :std, :stdm, :var, :varm, :quantile)
    @eval begin
        Statistics.$(f)(cdf::ECDFActor, args...; kws...) = Statistics.$(f)(cdf.ecdf, args...; kws...)
        Statistics.$(f)(cdf::ECDFsActor, ind, args...; kws...) = Statistics.$(f)(cdf.ecdfs[ind], args...; kws...)
    end
end

for f in (:sort!, :empty!)
    @eval begin
        Base.$(f)(cdf::ECDFActor, args...) = ($(f)(cdf.ecdf,args...); cdf)
    end
end

###
### SampleLoopActor
###

# abstract type AbstractSampleLoopActor <: AbstractActor
# end

struct ProgressIter{IterT}
    iter::IterT
end
ProgressIter(n::Integer) = ProgressIter(1:n)

struct SampleLoopActor{Iter, ActorT} <: AbstractActor
    iter::Iter
    actor::ActorT
end

"""
    SampleLoopActor(iter, actor::AbstractActor = NullActor())

Actor for use in `trial!`. The sample iterator is `iter`.
"""
SampleLoopActor(iter) = SampleLoopActor(iter, NullActor())

"""
    SampleLoopActor(n::Integer,  actor = NullActor())

Actor for use in `trial!` that performs `n` samples.
"""
SampleLoopActor(n::Integer, actor = NullActor()) = SampleLoopActor(1:n, actor)

get_actor(s::SampleLoopActor) = s.actor

end # module Actors
