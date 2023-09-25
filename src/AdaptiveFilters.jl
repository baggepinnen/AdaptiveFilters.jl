module AdaptiveFilters
using OnlineStats, DSP
using OnlineStats: l2regloss

export adaptive_filter, focused_adaptive_filter, OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight, NLMS


"""
    yh = adaptive_filter(y, alg=MSPI; order=4, lr=0.1)

Filters `y` with an adaptive AR (only poles) filter with specified order.
Returns `yh` which is the predicted output from an adaptive line enhancer (ALE). If your noise is wideband and signal narrowband, `yh` is your desired filtered signal. If the noise is narrowband and the signal is wideband, then `y-yh` is your desired filtered signal.

The first `order` samples of `yh` will be copies of `y`. The signals will thus have the same length.

#Arguments:
- `alg`: Stochastic approximation algorithm or weight function. Examples: `OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight`
- `y`: Input signal
- `order`: Filter order
- `lr`: Learning rate or weight depending on `alg`
"""
function adaptive_filter(y, alg::Type{<:OnlineStats.Algorithm}=MSPI, loss::Function=l2regloss; order=4, lr=0.1, kwargs...)
    T = length(y)
    model = StatLearn(loss, order, alg(); rate=LearningRate(lr), kwargs...)
    yh = similar(y)
    yh[1:order] = y[1:order]
    for t in 1:T-order
        x = @view(y[t:t+order-1])
        o  = fit!(model, (x, y[t+order]))
        yh[t+order] = OnlineStats.predict(o, x)
    end
    yh
end

function adaptive_filter(y, alg::Type{<:OnlineStats.Weight}; order=6, lr=0.2)
    T = length(y)
    model = LinReg(weight=alg(lr))
    yh = similar(y)
    yh[1:order] = y[1:order]
    for t in 1:T-order
        x = @view(y[t:t+order-1])
        o  = fit!(model, (x, y[t+order]))
        if t > order
            value(model)
            yh[t+order] = OnlineStats.predict(model, x)
        else
            yh[t+order] = y[t]
        end
    end
    yh
end

"""
    focused_adaptive_filter(y, band, fs, args...; kwargs...)

An adaptive filter that focuses its attention to a specific frequency range.

#Arguments:
- `y`: Input signal
- `band`: Frequency band typle
- `fs`: Sample rate, e.g., 44100
- `args`: Passed through to `adaptive_filter`
- `kwargs`: Passed through to `adaptive_filter`
"""
function focused_adaptive_filter(y,band,fs,args...; kwargs...)
    dm = Butterworth(3)
    rt = Bandpass(band...,fs=fs)
    f = digitalfilter(rt, dm)
    yh = filt(f, reverse(y))
    yh = filt(f, reverse(yh))
    yh = adaptive_filter(yh, args...; kwargs...)
    yh
end


struct NLMS{T}
    x::Vector{T}
    w::Vector{T}
    μ::T
    last::Base.RefValue{Int}
end

"""
    NLMS(n::Int, μ::T)

Create an `NLMS` FIR-filter with `n` coefficients (filter taps) and learning rate `0 < μ ≤ 1`.
The type of `μ` determines the numeric type used by the filter.

Call the filter object like a function `ŷ, e = f(x, d)` where `x` is the input and `d` is the desired output.
To create an adaptive line enhancer (ALE), set ``d[k] = x[k-Δ]`` where ``Δ`` is a positive integer delay, like 1.
"""
function NLMS(n::Int, μ::T) where T
    NLMS(zeros(T, n), zeros(T, n), μ, Base.RefValue(0))
end

@inbounds function (f::NLMS{T})(x, d; a=1e-6) where T
    i = f.last[] + 1
    if i > length(f.x)
        i = 1
    end
    f.last[] = i
    f.x[i] = x

    wi = 1
    wTx = zero(T)
    x² = zero(T)
    for xi = i:length(f.x)
        fxi = f.x[xi]
        wTx += fxi*conj(f.w[wi])
        x² += abs2(fxi)
        wi += 1
    end
    for xi = 1:i-1
        fxi = f.x[xi]
        wTx += fxi*conj(f.w[wi])
        x² += abs2(fxi)
        wi += 1
    end

    yh = wTx
    e = d - yh
    μe = f.μ * e / (x² + a)
    wi = 1
    for xi = i:length(f.x)
        f.w[wi] += μe * f.x[xi]
        wi += 1
    end
    for xi = 1:i-1
        f.w[wi] += μe * f.x[xi]
        wi += 1
    end
    yh, e
end



end
