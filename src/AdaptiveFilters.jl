module AdaptiveFilters
using OnlineStats

export adaptive_filter, OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight


"""
    yo,yh = adaptive_filter(y, alg=OMAP; order=6, lr=0.25)

Filters `y` with an adaptive AR (only poles) filter with specified order.
Returns `yo` which is a shorter version of `y` and `yh` which is the predicted output from an adaptive line enhancer (ALE). If your noise is wideband and signal narrowband, `yh` is your desired filtered signal. If the noise is narrowband and the signal is wideband, then `yo-yh` is your desired filtered signal.

#Arguments:
- `alg`: Stochastic approximation algorithm or weight function. Examples: `OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight`
- `y`: Input signal
- `order`: Filter order
- `lr`: Learning rate or weight depending on `alg`
"""
function adaptive_filter(y, alg::Type{<:OnlineStats.Algorithm}=OMAP; order=6, lr=0.25)
    T = length(y)
    model = StatLearn(order, alg(), rate=LearningRate(lr))
    yh = map(1:T-order) do t
        x = @view(y[t:t+order-1])
        o  = fit!(model, (x, y[t+order]))
        yh = OnlineStats.predict(o, x)
    end
    y[order+1:end],yh
end

function adaptive_filter(y, alg::Type{<:OnlineStats.Weight}; order=6, lr=0.2)
    T = length(y)
    model = LinReg(weight=alg(lr))
    yh = map(1:T-order) do t
        x = @view(y[t:t+order-1])
        o  = fit!(model, (x, y[t+order]))
        if t > order
            value(model)
            OnlineStats.predict(model, x)
        else
            y[t]
        end
    end
    y[order+1:end],yh
end

end
