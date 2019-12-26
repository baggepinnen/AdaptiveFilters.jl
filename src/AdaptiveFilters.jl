module AdaptiveFilters
using OnlineStats, DSP

export adaptive_filter, focused_adaptive_filter, OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight


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
function adaptive_filter(y, alg::Type{<:OnlineStats.Algorithm}=MSPI; order=4, lr=0.1)
    T = length(y)
    model = StatLearn(order, alg(), rate=LearningRate(lr))
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
