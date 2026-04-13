# ViscoAnalysis.jl

**ViscoAnalysis.jl** is a Julia package for analysing complex-modulus (viscoelastic) data
from dynamic mechanical analysis (DMA) experiments on bituminous materials (asphalt, etc.).

It provides a complete, self-contained workflow from raw Excel data to publication-quality
figures and rheological model parameters.

---

## Features

| Feature | Description |
|---------|-------------|
| **Data import** | Read multi-sheet Excel workbooks; one sheet = one test condition |
| **Time-temperature superposition** | Automatic WLF shift-factor computation and master-curve construction |
| **Model identification** | Global optimisation for 2S2P1D, 1S2P1D, and Huet-Sayegh models |
| **Diagnostic plots** | Isotherm, isochrone, Cole-Cole, Black, Kramers-Kronig, WLF |
| **Model overlay plots** | Experimental master curve vs fitted model |

---

## Installation

From the Julia REPL, activate the package environment and instantiate dependencies:

```julia
] activate path/to/ViscoAnalysis
] instantiate
```

Or add it as a development dependency from another project:

```julia
] dev path/to/ViscoAnalysis
```

---

## Quick start

```julia
using ViscoAnalysis

# 1. Load all sheets from an Excel workbook
#    MPa=true  → modulus column is already in MPa
#    MPa=false → modulus column is in Pa, converted to MPa automatically
series = load_data("data.xlsx"; MPa=true)

# 2. Generate all diagnostic plots
plot_all(series, "results/"; Tref=10.0)

# 3. Fit the 2S2P1D model on the master curve at Tref = 10 °C
result = fit2S2P1D(series[1], 10.0)
println(result)

# 4. Overlay the fitted model on the master curve
plot_model_fit(series, [result], "results/"; Tref=10.0)

# 5. Evaluate the model at a specific frequency
ω = 2π * 10.0          # 10 Hz → rad/s
E_star = result(ω)
@show abs(E_star)              # |E*| [MPa]
@show angle(E_star) * 180/π   # φ   [°]
```

See [Getting Started](@ref) for a full walkthrough, or jump to the [API Reference](@ref load_data).

---

## Workflow overview

```
Excel file (.xlsx)
        │
        ▼
   load_data()           → Vector{DataSeries}    (one per sheet)
        │
        ▼
build_shift_factors!()   → WLF coefficients C1, C2  stored in DataSeries
        │
        ▼
build_master_curve()     → reduced-frequency master curve at Tref
        │
        ▼
fit2S2P1D / fit1S2P1D    → FitResult  (model parameters + residual)
 / fitHS
        │
   ┌────┴─────┐
   ▼          ▼
plot_all()  plot_model_fit()   → PDF + PNG figures
```

---

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [XLSX.jl](https://github.com/felipenoris/XLSX.jl) | Read Excel workbooks |
| [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) | Tabular data |
| [Plots.jl](https://github.com/JuliaPlots/Plots.jl) (GR backend) | Figures |
| [LaTeXStrings.jl](https://github.com/JuliaStrings/LaTeXStrings.jl) | LaTeX axis labels |
| [LsqFit.jl](https://github.com/JuliaNLSolvers/LsqFit.jl) | WLF nonlinear least-squares |
| [NLopt.jl](https://github.com/JuliaOpt/NLopt.jl) | Global model optimisation |
