# AdaptiveFilters

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

## Installation
```
using Pkg; Pkg.add(PackageSpec(url="https://github.com/baggepinnen/AdaptiveFilters.jl"))
```



## Demo app
```julia
using AdaptiveFilters, Plots, Interact
inspectdr() # Preferred plotting backend for waveforms

data = [sin.(1:100) .+ 0.1.*randn(100);
         sin.(0.2 .*(1:100)) .+ 0.1.*randn(100)]

function app(req=nothing)
    @manipulate for order = 2:2:10,
                    lr = LinRange(0.1, 0.9, 40),
                    alg = [ExponentialWeight, MSPI, OMAP, OMAS, ADAM]
        y,yh = adaptive_filter(data, alg, order=order, lr=lr)
        e = y.-yh
        plot([y yh], lab=["Measured signal" "Prediction"], layout=(2,1), show=false, sp=1)
        plot!(e, lab="Error", sp=2, title="RMS: $(√mean(abs2, e))")
    end
end

app()

# Save filtered sound to disk
using WAV
y,yh = adaptive_filter(data, 4, 0.25, OMAP)
e = y.-yh
wavwrite(e, "filtered.wav"), Fs=fs)
```
![window](figs/demo.svg)



## Internals
This is a lightweight wrapper around functionality in [OnlineStats.jl](https://github.com/joshday/OnlineStats.jl) which does all the heavy lifting.

## Usage from python
1. First install Julia and install this package in Julia.
2. Install [pyjulia](https://github.com/JuliaPy/pyjulia) using their instructions.
3. Now the following should work

```python
$ python3
>>> import julia
>>> from julia import AdaptiveFilters as af
>>> (yo,yh) = af.adaptive_filter(y)
```
if that fails, try replacing the first line with
```python
>>> from julia.api import Julia
>>> jl = Julia(compiled_modules=False)
```

Keyword args etc. work as normal
```python
af.adaptive_filter(y, af.ADAM, order=2)
```
