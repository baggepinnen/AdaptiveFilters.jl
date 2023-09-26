# AdaptiveFilters

[![CI](https://github.com/baggepinnen/AdaptiveFilters.jl/workflows/CI/badge.svg)](https://github.com/baggepinnen/AdaptiveFilters.jl/actions)
[![Coverage](https://codecov.io/gh/baggepinnen/AdaptiveFilters.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/AdaptiveFilters.jl)


Simple adaptive AR filters. We export two functions:

```julia
yh = adaptive_filter(y, alg=MSPI; order=4, lr=0.1)
```
This filters `y` with an adaptive AR (only poles) filter with specified order and returns `yh` which is the predicted output from an adaptive line enhancer (ALE). If your noise is wideband and signal narrowband, `yh` is your desired filtered signal. If the noise is narrowband and the signal is wideband, then `y-yh` is your desired filtered signal.

Arguments:
- `alg`: Stochastic approximation algorithm or weight function. Examples: `OMAP, MSPI, OMAS, ADAM, ExponentialWeight, EqualWeight`. `ExponentialWeight` corresponds to the recursive least-squares algorithm (RLS). `ADAM` corresponds *roughly* to the normalized least-mean squares (NLMS) algorithm. More options exist if OnlineStats is loaded.
- `y`: Input signal
- `order`: Filter order
- `lr`: Learning rate or weight depending on `alg`

The function
```julia
focused_adaptive_filter(y, band, fs, args...; kwargs...)
```
allows you to specify a frequency band (tuple) in which to focus the attention of the adaptive filter. `fs` here denotes the sample rate, e.g., 44100Hz.

## Installation
```julia
using Pkg; Pkg.add("AdaptiveFilters")
```



## Demo app
```julia
using AdaptiveFilters, Plots, Interact
inspectdr() # Preferred plotting backend for waveforms

y = [sin.(1:100); sin.(0.2 .*(1:100))] # A sinusoid with changing frequency
yn = y .+ 0.1*randn(length(y)) # A sinusoid with noise


function app(req=nothing)
    @manipulate for order = 2:2:10,
                    lr = LinRange(0.01, 0.99, 100),
                    alg = [ExponentialWeight, MSPI, OMAP, OMAS, ADAM]
        yh = adaptive_filter(yn, alg, order=order, lr=lr)
        e = yn.-yh
        plot([yn yh], lab=["Measured signal" "Prediction"], layout=(2,1), show=false, sp=1)
        plot!(e, lab="Error", sp=2, title="RMS: $(√mean(abs2, e))")
    end
end

app()

# Save filtered sound to disk
using WAV
yh = adaptive_filter(yn, OMAP, order=4, lr=0.25)
e = yn.-yh
wavwrite(e, "filtered.wav", Fs=fs)
```
![window](figs/demo.svg)

## NLMS
A normalized least-mean squares (NLMS) filter can be created like
```julia
using AdaptiveFilters, Random
N = 60   # Number of filter taps 
μ = 0.01 # Learning rate
f = NLMS(N, μ)
```

This filter can then be called like
```
ŷ, e = f(x, d)
```
where `x` is the input signal, `d` is the desired signal and `ŷ` is the filtered signal. The error `e` is also returned. This call modifies the internal state of `f`.

## Adaptive line enhancer
The NLMS filter can be used to build an adaptive line enhancer (ALE) by letting the input signal be the desired signal delayed by a number of samples ``Δ``:

```julia
using Random
Random.seed!(0)
y = sin.(0:0.1:100)
yn = y + 0.1*randn(length(y)) # A sinusoid with noise


T = length(y)
YH = zeros(T)
E = zeros(T)

Δ = 1 # Delay in samples

for i = eachindex(y)
    YH[i], E[i] = f(yn[max(i-Δ, 1)], yn[i])
end

using Plots, Test
@test mean(abs2, y[end-100:end] - YH[end-100:end]) < 1e-3
plot([y yn YH E y-YH], lab=["y" "yn" "yh" "e" "y-yh"])
```




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
>>> yh = af.adaptive_filter(y)
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

## Example: Adaptive cicada filtering
The following function does a reasonable job at filtering out the sound of cicadas from an audio recording
```julia
cicada_filter(y,fs,args...; kwargs...) = y-focused_adaptive_filter(data,(4200,11000),fs,args...; kwargs...)
```
