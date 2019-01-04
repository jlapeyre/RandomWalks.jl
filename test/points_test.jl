@testset "Points" begin
    @test Point() == Point{1}()
    @test Point() == Point{1, Float64}()
    @test Point() == Point(0.0)
    @test Point{2}() == Point(0.0, 0.0)
    @test Point{2, Int}() == Point(0, 0)
    @test Point(1, 2) == Point((1, 2))

    p = Point(1.0)
    @test zero(p) == Point(0.0)
    @test get_coords(p) == (1.0,)
    @test typeof(Point(1)) == Point{1, Int64, Tuple{Int64}}
    p = Point(2.0, 3.0)
    @test p[1] == 2.0
    @test p[2] == 3.0
end
