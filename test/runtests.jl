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

    y = sin.(0:0.1:100)
    yh = focused_adaptive_filter(y, (0.01,2), (2pi)/0.1, lr=0.01, order=4)
    @test mean(abs2, y-yh) < 1e-2

    ## NLMS
    y = sin.(0:0.1:320)
    yn = y + 0.1*randn(length(y))
    N = 2*29
    T = length(y)
    
    f = AdaptiveFilters.NLMS(N, 0.01)
    
    YH = zeros(T)
    E = zeros(T)
    
    Δ = 1
    
    for i = eachindex(y)
        YH[i], E[i] = f(yn[max(i-Δ, 1)], yn[i])
    end
    
    # using Plots
    # plot([y yn YH E y-YH], lab=["y" "yn" "yh" "e" "y-yh"])
    
    @test mean(abs2, y[end-100:end] - YH[end-100:end]) < 1e-2
end
