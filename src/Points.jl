module Points

export Point, get_x, get_y, get_z, get_coords, unit_vectors2, unit_vectors3

###
### Point
###

struct Point{N, T, C <: NTuple{N, T}}
    coords::C
end

get_coords(p::Point) = p.coords
Point(coords::T...) where T = Point{length(coords), T, typeof(coords)}(coords)
Point(coords::Tuple) = Point(coords...)

@generated function Point{N, T}() where {N, T}
    isa(N, Integer) || throw(TypeError(:Point, "", Integer, typeof(N)))
    N > 0 || throw(DomainError(N, "N must be a positive Integer"))
    return Point((zero(T) for i in 1:N)...,)
end

Point{N}() where {N} = Point{N, Float64}()
Point() = Point{1}()

Base.getindex(p::Point, inds...) = getindex(get_coords(p), inds...)
Base.length(p::Point) = length(get_coords(p))
Base.eltype(p::Point) = eltype(get_coords(p))

get_x(p::Point) = p[1]
get_y(p::Point) = p[2]
get_z(p::Point) = p[3]

import Base: +, -, *
+(p::Point{1, <:Any, <:Any}, x::Number) = Point(x + get_x(p))
+(p1::Point{N}, p2::Point{N}) where N = Point((get_coords(p1) .+ get_coords(p2))...)
*(p1::Point, n::Number) = Point((get_coords(p1) .* n))
*(n::Number, p::Point) = p * n
-(p::Point) = Point(broadcast(-, get_coords(p))...)
-(p1::Point{N}, p2::Point{N}) where N = p1 + (-p2)

Base.zero(p::Point) = Base.zero(typeof(p))
# Replacing V with <:Any does not work. Method not found
Base.zero(::Type{Point{N, T, V}}) where {N, T, V} = Point{N, T}()
Base.zero(::Type{Point{N, T}}) where {T, N} = Point{N, T}()

Base.show(io::IO, p::Point{N, T}) where {T, N}  = print(io, "Point{$N, $T}", get_coords(p))
Base.show(io::IO, p::Point{1, T}) where {T}  = print(io, "Point{1, $T}(", get_coords(p)[1], ")")

const unit_vectors2 = (Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0))

const unit_vectors3 = (Point(0, 0, 1), Point(0, 1, 0), Point(1, 0, 0),
                       Point(0, 0, -1), Point(0, -1, 0), Point(-1, 0, 0))

end # module Point
