# AdaptiveFilters

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://baggepinnen.github.io/AdaptiveFilters.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://baggepinnen.github.io/AdaptiveFilters.jl/dev)
[![Build Status](https://travis-ci.org/baggepinnen/AdaptiveFilters.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/AdaptiveFilters.jl)
[![Coverage](https://codecov.io/gh/baggepinnen/AdaptiveFilters.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/AdaptiveFilters.jl)


Simple adaptive AR filters. We export a single function:

```julia
yo,yh = adaptive_filter(y, alg=OMAP; order=6, lr=0.25)
```
This filters `y` with an adaptive AR (only poles) filter with specified order and returns `yo` which is a shortened version of `y` and `yh` which is the predicted output from an adaptive line enhancer (ALE). If your noise is wideband and signal narrowband, `yh` is your desired filtered signal. If the noise is narrowband and the signal is wideband, then `yo-yh` is your desired filtered signal.

Arguments:
- `alg`: Stochastic approximation algorithm or weight function. Examples: `OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight`
- `y`: Input signal
- `order`: Filter order
- `lr`: Learning rate or weight depending on `alg`



## Demo app
```julia
using AdaptiveFilters, WAV, Plots, Interact
inspectdr() # Preferred plotting backend for waveforms

data = [sin.(1:100) .+ 0.1.*randn(100);
         sin.(0.2 .*(1:100)) .+ 0.1.*randn(100)]

function app(req=nothing)
    @manipulate for order = 2:2:10,
                    lr = LinRange(0.1, 0.9, 40),
                    alg = [ExponentialWeight, MSPI, OMAP, OMAS, ADAM]
        y,yh = adaptive_filter(data, alg, order=order, lr=lr)
        e = y.-yh
        plot([y yh], lab=["Signal" "Prediction"], layout=(2,1), show=false, sp=1)
        plot!(e, lab="Filtered signal", sp=2, title="RMS: $(√mean(abs2, e))")
    end
end

app()

# Save filtered sound to disk
y,yh = adaptive_filter(data, 4, 0.25, OMAP)
filtered_signal = y.-yh
wavwrite(filtered_signal, "filtered.wav"), Fs=fs)
```
![window](figs/demo.svg)

In the demo above, the narrowband signal is considered noise and the wideband Gaussian noise is considered signal.

## Internals
This is a lightweight wrapper around functionality in [OnlineStats.jl](https://github.com/joshday/OnlineStats.jl) which does all the heavy lifting.
