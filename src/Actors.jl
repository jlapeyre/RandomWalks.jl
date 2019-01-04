module Actors

using ..Walks: get_nsteps, get_time, get_position
using ..Points: get_x
using EmpiricalCDFs

export NullActor
export SampleLoop
export StoredValues
export AbstractSampleCallback, SampleCallback
export ECDFActor, ECDFAction, get_cdfs
export CallbackSet
export callbacks, get_action
export storing_position_actor
export storing_nsteps_actor
export storing_nsteps_position_actor
export logrange
export get_times
export StepLimitActor
export DefaultSampleActor
export get_values
export StoringAction
export StoringActor

abstract type AbstractSampleCallback end

###
### SampleCallback
###

"""
    struct SampleCallback

Callback for a "sample", i.e. a single walk. All callbacks for a single walk are instances
of this type.

`action!` stores data and functions implementing the callback.

`init!` is called with no arguments at the beginning of the walk.

An instance `cb::SampleCallback` is callable and is called on the
`system::AbstractLatticeWalk` after each step.
"""
struct SampleCallback{F2, F3} <: AbstractSampleCallback
    action!::F2
    init!::F3
end

init!(cb::SampleCallback) = cb.init!()
(cb::SampleCallback)(args...) = cb.action!(args...)

###
### CallbackSet
###

"""
    struct SampleCallback

Callback for a "sample", i.e. a single walk. All callbacks for a single walk are instances
of this type.

`action!` stores data and functions implementing the callback.

`init!` is called with no arguments at the beginning of the walk.
"""
struct CallbackSet{T <: Tuple} <: AbstractSampleCallback
    callbacks::T
end

CallbackSet(cbs::SampleCallback...) = CallbackSet((cbs...,))

init!(callbacks::CallbackSet) = foreach(cb -> cb.init!(), callbacks.callbacks)

function (cbs::CallbackSet)(args...)
    for cb in cbs.callbacks
        cb(args...)::Bool || return false
    end
    return true
end

###
### AbstractSampleActor
###

abstract type AbstractSampleActor end

macro actor(name)
    quote
        struct ($name){T <: AbstractSampleCallback} <: AbstractSampleActor
            callback::T
        end
    end
end

callbacks(actor::AbstractSampleActor) = actor.callback
get_action(actor::AbstractSampleActor) = callbacks(actor).action!

# FIXME: semantics of callbacks methods are very different
function callbacks(actor::AbstractSampleActor, actors::AbstractSampleActor...)
    return CallbackSet(callbacks(actor), callbacks.(actors)...)
end

###
### NullActor
###

struct NullAction end
(action!::NullAction)(_) = true
@actor NullActor
NullActor(_ = nothing)  = NullActor(SampleCallback(NullAction(), () -> nothing))

###
### StepLimitActor
###

mutable struct StepLimitAction
    max_step_limit::Int
    hit_max_step_limit::Bool
    StepLimitAction(n=10) = new(n, false)
end

function (action!::StepLimitAction)(latwalk)
    nsteps = get_nsteps(latwalk)
    if nsteps >= action!.max_step_limit
        action!.hit_max_step_limit = true
        return false
    end
    return true
end

@actor StepLimitActor

# We used a closure for init!. Is this the best way ?
function StepLimitActor(n = 100)
    action! = StepLimitAction(n)
    init! = () -> action!.hit_max_step_limit = false
    return StepLimitActor(SampleCallback(action!, init!))
end

function Base.show(io::IO, actor::StepLimitActor)
    print(io, "StepLimitActor(n=", get_action(actor).max_step_limit,
          ", hit=", get_action(actor).hit_max_step_limit, ")")
end

DefaultSampleActor = StepLimitActor

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

struct StoringAction{T, X, F}
    stored_values::StoredValues{T, X}
    storing_func::F
end

function StoringAction(times, storing_func, value_types)
    return StoringAction(StoredValues(times; value_types=value_types), storing_func)
end

function StoringAction(times, storing_func::Tuple, value_types::Tuple)
    return StoringAction(StoredValues(times; value_types=value_types), storing_func)
end

function (action!::StoringAction)(system)
    get_current_index(action!.stored_values) > lastindex(action!.stored_values) && return false # terminate walk
    while get_time(system) >= get_target_time(action!.stored_values)
        push!(action!.stored_values.values, action!.storing_func(system))
        increment_current_index(action!.stored_values)
        get_current_index(action!.stored_values) > lastindex(action!.stored_values) && return false # terminate walk
    end
    return true
end

function (action!::StoringAction{T, <:Tuple, <:Tuple})(system) where T
    get_current_index(action!.stored_values) > lastindex(action!.stored_values) && return false # terminate walk
    while get_time(system) >= get_target_time(action!.stored_values)
        for (array, func) in zip(action!.stored_values.values, action!.storing_func)
            push!(array, func(system))
        end
        increment_current_index(action!.stored_values)
        get_current_index(action!.stored_values) > lastindex(action!.stored_values) && return false # terminate walk
    end
    return true
end

function storing_callback_init!(action!)
    return function ()
        reset_current_index!(action!.stored_values)
        empty!(action!.stored_values)
        return nothing
    end
end

@actor StoringActor

StoringActor(times, storing_func; value_types=Float64) = _StoringActor(times, storing_func, value_types)

function _StoringActor(times, storing_func, value_types)
    action! = StoringAction(times, storing_func, value_types)
    init! = storing_callback_init!(action!)
    return StoringActor(SampleCallback(action!, init!))
end

for f in (:get_values, :get_times)
    @eval ($f)(sa::StoringActor) = ($f)(sa.callback.action!.stored_values)
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
    print(io, "StoringActor(", get_action(actor).stored_values, ")")
end

# FIXME: how about an easy, *performant*, lazy version ?
function logrange(itr)
    return collect(exp10(x) for x in itr)
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

struct SampleLoop{Iter, Actors <: Tuple}
    iter::Iter
    actors::Actors
end

callbacks(s::SampleLoop) = callbacks(s.actors...)

###
### ECDFActor
###

struct ECDFAction{T, F}
    ecdfs::T
    storing_func::F
end

function (action!::ECDFAction)(_...)
    action!.storing_func()
    return true
end

@actor ECDFActor

get_cdfs(ea::ECDFActor) = callbacks(ea).action!.ecdfs

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
    action! = ECDFAction(ecdfs, storing_func)
    init! = () -> true
    return ECDFActor(SampleCallback(action!, init!))
end

function Base.sort!(actor::ECDFActor)
    for cdf in actor.callback.action!.ecdfs
        sort!(cdf)
    end
    return actor
end

end # module Actors
