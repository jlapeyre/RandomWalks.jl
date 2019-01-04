module Points

export Point, get_x, get_y, get_z, get_coords, unit_vectors2, define_Point

###
### Point
###

struct Point{N, T, C <: Tuple}
    coords::C
end

get_coords(p::Point) = p.coords

# FIXME: is this useful ?
# """
#     define_Point(dim::Integer)

# Define alias `Pointdimd = Point{dim,T,C} where C where T`.
# """
# function define_Point(d::Integer)
#     type_name = Symbol("Point", d, "d")
#     args = ((Symbol("x", i) for i in 1:d)...,)
#     @eval ($type_name){T, C} = Point{$d, T, C}
#     @eval ($type_name)($(args...)) = Point($(args...))
# end

# for d in 1:3
#     define_Point(d)
# end

Point(coords::T...) where T = Point{length(coords), T, typeof(coords)}(coords)
Point(coords::Tuple) = Point(coords...)

@generated function Point{N, T}() where {N, T}
    return Point((zero(T) for i in 1:N)...,)
end

@generated function Point{N}() where {N}
    return Point((zero(Float64) for i in 1:N)...,)
end

Point() = Point{1}()

Base.getindex(p::Point, inds...) = getindex(get_coords(p), inds...)
Base.length(p::Point) = length(get_coords(p))
Base.eltype(p::Point) = eltype(get_coords(p))

get_x(p::Point) = p[1]
get_y(p::Point) = p[2]
get_z(p::Point) = p[3]

import Base: +, -
+(p::Point{1, <:Any, <:Any}, x::Number) = Point(x + get_x(p))
+(p1::Point{N}, p2::Point{N}) where N = Point((get_coords(p1) .+ get_coords(p2))...)
-(p::Point) = Point(broadcast(-, get_coords(p))...)
-(p1::Point{N}, p2::Point{N}) where N = p1 + (-p2)

Base.zero(p::Point) = Base.zero(typeof(p))
# Replacing V with <:Any does not work. Method not found
Base.zero(::Type{Point{N, T, V}}) where {N, T, V} = Point{N, T}()
Base.zero(::Type{Point{N, T}}) where {T, N} = Point{N, T}()

Base.show(io::IO, p::Point{N, T}) where {T, N}  = print(io, "Point{$N, $T}", get_coords(p))
Base.show(io::IO, p::Point{1, T}) where {T}  = print(io, "Point{1, $T}(", get_coords(p)[1], ")")

const unit_vectors2 = (Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0))

end # module Point
