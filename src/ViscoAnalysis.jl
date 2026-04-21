"""
    ViscoAnalysis

Julia package for analysing complex-modulus (viscoelastic) data from
dynamic mechanical experiments on bituminous materials.

## Workflow

```
Excel file  →  load_data  →  DataSeries
                                  ↓
                        build_shift_factors!   (WLF)
                                  ↓
                        build_master_curve     (master curve)
                                  ↓
                          fit2S2P1D            (model identification)
                                  ↓
                         plot_model_fit        (output figures)
```

## Quick start

```julia
using ViscoAnalysis

# Load data (all sheets)
series = load_data("EBR_T0_T10.xlsx"; MPa=true)

# Diagnostic plots (isothermal, isochrone, Cole-Cole, Black, KK, WLF)
plot_all(series, "results/")

# Fit the 2S2P1D model on the master curve at Tref = 10 °C
result = fit2S2P1D(series[1], 10.0)
println(result)

# Plot experimental data + model overlay
plot_model_fit(series, [result], "results/"; Tref=10.0)
```

## Public API

### Data I/O
- [`load_data`](@ref)

### Models
- [`Mod2S2P1D`](@ref)
- [`ModGM`](@ref)
- [`wlf_scalar`](@ref)
- [`T_TEV`](@ref)
- [`change_Tref_WLF`](@ref)

### Analysis
- [`build_shift_factors!`](@ref)
- [`build_master_curve`](@ref)
- [`build_Kramers_Kronig!`](@ref)
- [`fit2S2P1D`](@ref)
- [`eval_model`](@ref)
- [`eval_array`](@ref)

### Plotting
- [`plot_all`](@ref)
- [`plot_isothermes`](@ref)
- [`plot_isochrones`](@ref)
- [`plot_cole_cole`](@ref)
- [`plot_black`](@ref)
- [`plot_kramers_kronig`](@ref)
- [`plot_wlf`](@ref)
- [`plot_wlf_stability`](@ref)
- [`plot_model_fit`](@ref)
"""
module ViscoAnalysis

using Printf
using XLSX
using DataFrames
using Plots
using LaTeXStrings
using NLopt
using LsqFit
using LinearAlgebra
using Logging

gr()  # GR backend — required for LaTeXStrings support

include("types.jl")
include("models.jl")
include("io.jl")
include("fitting.jl")
include("plotting.jl")

# ── Public exports ────────────────────────────────────────────────────────────

# Types
export AbstractFitResult,
       DataSeries,
       FitResult2S2P1D, FitResult1S2P1D, FitResultHS,
       model_name

# I/O
export load_data, save_fitting_results

# Models
export Mod2S2P1D, Mod1S2P1D, ModHS,
       ModGM, wlf_scalar, T_TEV, change_Tref_WLF

# Analysis
export build_shift_factors!, build_master_curve,
       build_Kramers_Kronig!,
       fit2S2P1D, fit1S2P1D, fitHS,
       eval_model, eval_array

# Plotting
export plot_all, plot_isothermes, plot_isochrones,
       plot_cole_cole, plot_black, plot_kramers_kronig,
       plot_wlf, plot_wlf_stability, plot_model_fit

end # module ViscoAnalysis
