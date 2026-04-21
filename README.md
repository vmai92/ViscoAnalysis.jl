# ViscoAnalysis.jl

[![Build Status](https://github.com/vmai92/ViscoAnalysis.jl/actions/workflows/docs.yml/badge.svg?branch=main)](https://github.com/vmai92/ViscoAnalysis.jl/actions/workflows/docs.yml?query=branch%3Amain)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://vmai92.github.io/ViscoAnalysis.jl/dev/)

Julia package for analysing complex-modulus (viscoelastic) data from dynamic
mechanical experiments on bituminous materials.

## Features

- Reads multi-sheet Excel workbooks (one test condition per sheet)
- Builds master curves based on Booij & Thoone and the William–Landel–Ferry (WLF) equation
- Fits the **2S2P1D** or **1S2P1D** or **Huet-Sayegh** rheological model 
- Produces publication-quality figures: isotherms, isochrones, Cole-Cole, Black,
  Kramers-Kronig, WLF shift factors, and model overlay

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

## Excel file format

Each sheet must contain data in exactly four columns, with a header row:

| Column | Content              | Unit         |
|--------|----------------------|--------------|
| 1      | Temperature T        | °C           |
| 2      | Frequency f          | Hz           |
| 3      | Complex modulus norm | Pa or MPa    |
| 4      | Phase angle φ        | degrees (°)  |

Rows are grouped by temperature — all frequencies for one temperature appear
consecutively before the next temperature block.  Multiple sheets in the same
workbook are each loaded as an independent `DataSeries`.

---

## Quick start

```julia
using ViscoAnalysis

# 1. Load all sheets from an Excel file
#    MPa=true  → modulus column is already in MPa (no conversion)
#    MPa=false → modulus column is in Pa, converted to MPa automatically
series = load_data("EBR_T0_T10.xlsx"; MPa=true)

# 2. Generate all diagnostic plots into a directory
plot_all(series, "results/"; Tref=10.0)

# 3. Fit the 2S2P1D model on the master curve at Tref = 10 °C
result = fit2S2P1D(series[1], 10.0)
println(result)

# 4. Plot experimental data + fitted model overlay
plot_model_fit(series, [result], "results/"; Tref=10.0)
```

See [`examples/quickstart.jl`](examples/quickstart.jl) for a complete
runnable script.

---

## Output file structure

After running the quickstart example, the output directory contains:

```
results/
├── Isothermes.pdf / .png
├── Isochrones.pdf / .png
├── Cole-Cole diagram.pdf / .png
├── Black diagram.pdf / .png
├── Kramers-Kronig verification.pdf / .png
├── Shift factors calculation.pdf / .png
├── WLF multiple Trefs.pdf / .png
├── Results_Tref10.pdf / .png
└── parametres_fitting.xlsx          ← model parameters (E∞, E₀, δ, τ, k, h, β) + residual
```

---
