# ViscoAnalysis.jl

**ViscoAnalysis.jl** is a Julia package for analysing **complex-modulus (viscoelastic) data** from dynamic mechanical experiments on bituminous materials (asphalt mixes).

It provides a complete analysis workflow — from reading Excel measurement files to identifying rheological model parameters — together with publication-quality diagnostic figures.

---

## Features

- **Data loading** from `.xlsx` files (isothermal sweeps or isochrone layouts)
- **Time-Temperature Superposition (TTS)** via the WLF equation — master curve construction
- **Kramers–Kronig verification** — causality check on experimental data
- **Rheological model fitting**:
  - 2S2P1D (2 Springs, 2 Parabolic elements, 1 Dashpot) — 7 parameters
  - 1S2P1D (no glassy spring) — 6 parameters
  - Huet-Sayegh (no dashpot) — 6 parameters
  - Generalised Maxwell — arbitrary number of elements
- **Diagnostic plots**: isotherms, isochronals, Cole-Cole, Black diagram, WLF, model fit overlay

---

## Installation

ViscoAnalysis.jl is a local package. To add it from its folder:

```julia
using Pkg
Pkg.develop(path="path/to/ViscoAnalysis")
```

Or, once registered on a registry:

```julia
using Pkg
Pkg.add("ViscoAnalysis")
```

---

## Quick Example

```julia
using ViscoAnalysis

# 1. Load data (modulus in MPa)
series = load_data("my_data.xlsx"; MPa=true)

# 2. All diagnostic plots → results/ folder
plot_all(series, "results/")

# 3. Fit the 2S2P1D model at Tref = 10 °C
result = fit2S2P1D(series[1], 10.0)
println(result)

# 4. Overlay model on experimental data
plot_model_fit(series, [result], "results/"; Tref=10.0)

# 5. Evaluate the model at 10 Hz
ω = 2π * 10.0
E_star  = result(ω)           # complex modulus [MPa]
E_norm  = abs(E_star)         # |E*| [MPa]
phi_deg = angle(E_star)*180/π # phase angle φ [°]
```

---

## Analysis Workflow

```
Excel file (.xlsx)
      │
      ▼
  load_data()              → Vector{DataSeries}
      │
      ▼
  build_shift_factors!()   → WLF coefficients (C₁, C₂)
      │
      ▼
  build_master_curve()     → reduced-frequency master curve
      │
      ▼
  fit2S2P1D() / fitHS()    → FitResult (callable model)
      │
      ▼
  plot_model_fit()         → PDF + PNG figures
```

---

## Package Information

| | |
|---|---|
| **Version** | 0.1.0 |
| **Author** | Van Than MAI |
| **Julia** | ≥ 1.9 |
| **License** | MIT |
| **Source** | [GitHub](https://github.com/Van-Than-MAI/ViscoAnalysis.jl) |

---

## Contents

```@contents
Pages = ["getting_started.md", "theory.md",
         "api/io.md", "api/models.md", "api/fitting.md", "api/plotting.md"]
Depth = 2
```
