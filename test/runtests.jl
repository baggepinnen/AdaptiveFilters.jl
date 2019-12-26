using AdaptiveFilters
using Test, Statistics

@testset "AdaptiveFilters.jl" begin
    y = sin.(0:0.1:100)
    yh = adaptive_filter(y, lr=0.01, order=4)

    @test mean(abs2, y-yh) < 1e-3

    yh = adaptive_filter(y, lr = 0.99, order=4)
    @test 1e-2 < mean(abs2, y-yh) < 1e-1

    yh = adaptive_filter(y, ExponentialWeight, order=2, lr = 0.01)
    @test mean(abs2, y-yh) < 1e-4

    @test length(y) == length(yh)

end
