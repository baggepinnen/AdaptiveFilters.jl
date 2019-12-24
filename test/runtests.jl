using AdaptiveFilters
using Test, Statistics

@testset "AdaptiveFilters.jl" begin
    y = sin.(0:0.1:100)
    yh = adaptive_filter(y)

    @test mean(abs2, y-yh) < 1e-4

    yh = adaptive_filter(y, lr = 0.99)
    @test 1e-3 < mean(abs2, y-yh) < 1e-2

    yh = adaptive_filter(y, lr = 0.01)
    @test mean(abs2, y-yh) < 1e-7

    yh = adaptive_filter(y, ExponentialWeight, order=2, lr = 0.01)
    @test mean(abs2, y-yh) < 1e-4

    @test length(y) == length(yh)

end
