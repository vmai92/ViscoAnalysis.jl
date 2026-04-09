# Getting Started

## Installation

### From a local path (development)

```julia
using Pkg
Pkg.develop(path="/path/to/ViscoAnalysis")
```

### From a Git URL

```julia
using Pkg
Pkg.add(url="https://github.com/Van-Than-MAI/ViscoAnalysis.jl")
```

### Verify the installation

```julia
using ViscoAnalysis
```

---

## Input File Format

`load_data` reads `.xlsx` workbooks. Each sheet must contain **four columns** with no header row (or one header row that is automatically skipped):

| Column | Description | Unit |
|--------|-------------|------|
| 1 | Temperature *T* | °C |
| 2 | Frequency *f* | Hz |
| 3 | Complex-modulus magnitude \|E\*\| | Pa or MPa |
| 4 | Phase angle *φ* | degrees (°) |

Rows must be grouped by temperature (isothermal sweeps). Frequencies within each temperature block may be in any order — they are sorted automatically.

**Multiple materials** can be stored in different sheets of the same workbook; `load_data` returns one [`DataSeries`](@ref) per sheet.

### Example Excel layout

```
T (°C)   f (Hz)   |E*| (MPa)   φ (°)
   0      0.01      2450.2      12.5
   0      0.1       2520.8      13.1
   0      1.0       2601.4      14.3
   0     10.0       2690.0      15.8
  10      0.01      2200.1      15.2
  10      0.1       2285.3      16.0
  ...
```

---

## Step-by-Step Walkthrough

### 1 — Load data

```julia
using ViscoAnalysis

# MPa=true  → modulus column is already in MPa
# MPa=false → modulus column is in Pa (default, divides by 10⁶)
series = load_data("EBR_T0_T10.xlsx"; MPa=true)

# series is a Vector{DataSeries}, one per sheet
d = series[1]
println(d)                  # DataSeries("Sheet1", 6 temps, 9 freqs)
println(d.list_temp)        # [0.0, 10.0, 20.0, 30.0, 40.0, 50.0]
println(d.list_omega)       # angular frequencies [rad/s]
```

Access data at a specific temperature:

```julia
T10 = d[10.0]               # Dict with keys "f", "omega", "|M*|", "delta", "M*", …
T10["|M*|"]                 # modulus magnitudes [MPa]
T10["delta"]                # phase angles [°]
T10["M*"]                   # complex moduli
```

---

### 2 — Diagnostic plots

Generate all standard diagnostic figures in one call:

```julia
plot_all(series, "results/"; Tref=10.0)
```

This saves the following figures to `results/`:

| File | Content |
|------|---------|
| `isothermes_<name>.pdf` | \|E\*\| and φ vs frequency, one curve per temperature |
| `isochrones_<name>.pdf` | \|E\*\| and φ vs temperature, one curve per frequency |
| `Cole-Cole_<name>.pdf` | Loss modulus *E₂* vs storage modulus *E₁* |
| `Black_<name>.pdf` | \|E\*\| vs phase angle φ (Black diagram) |
| `Kramers-Kronig_<name>.pdf` | Causality verification |
| `WLF_<name>.pdf` | Shift factors and fitted WLF curve |

---

### 3 — Build the master curve

```julia
# Compute WLF shift factors and store them in d
log_aT = build_shift_factors!(d, 10.0)   # Tref = 10 °C

println("C₁ = $(d.C1),  C₂ = $(d.C2)")

# Build the master curve for |E*|
omega_r, Estar_r = build_master_curve(d, "M*", 10.0)
```

---

### 4 — Fit a rheological model

```julia
# 2S2P1D — recommended for bituminous materials
result = fit2S2P1D(series[1], 10.0)
println(result)
```

Output:

```
FitResult2S2P1D
  E∞   = 2.8756e+04 MPa
  E₀   = 8.3200e+00 MPa
  δ    = 2.3150
  τ_E  = 1.9400e-02 s
  k    = 0.1850
  h    = 0.6200
  β    = 4.8700e+02
  residual = 3.214500e-04
```

The result object is callable — evaluate the model at any frequency:

```julia
ω = 2π * 10.0              # 10 Hz
E_star  = result(ω)        # ComplexF64 [MPa]
E_norm  = abs(E_star)      # |E*| [MPa]
phi_deg = angle(E_star) * 180/π   # φ [°]
```

Other available models:

```julia
result_1s = fit1S2P1D(series[1], 10.0)   # 1S2P1D (no glassy spring)
result_hs = fitHS(series[1], 10.0)        # Huet-Sayegh (no dashpot)
```

---

### 5 — Plot model fit

```julia
plot_model_fit(series, [result], "results/"; Tref=10.0)
# → saves Results_2S2P1D_Tref10.0.pdf and .png
```

You can overlay multiple models at once:

```julia
plot_model_fit(series, [result, result_hs], "results/"; Tref=10.0)
```

---

### 6 — WLF: change reference temperature

```julia
# Convert WLF from Tref=10 °C to Tref=15 °C
wlf_new, C1_new, C2_new = change_Tref_WLF(d.C1, d.C2, 10.0, 15.0)
log_aT_at_25 = wlf_new(25.0)   # log₁₀(aT) at 25 °C relative to 15 °C
```

---

### 7 — Evaluate a manually constructed model

```julia
# Build the 2S2P1D function directly
model = Mod2S2P1D(28_000.0, 8.0, 2.3, 0.02, 0.19, 0.62, 500.0)

# Evaluate at a range of frequencies
ω_vec = 10 .^ range(-3, 3, length=200) .* 2π
re, im_part, absval, deg = eval_model(model, ω_vec)
```

---

## Complete Example Script

```julia
using ViscoAnalysis

# ── Load ────────────────────────────────────────────────────────────────────
series = load_data("EBR_T0_T10.xlsx"; MPa=true)

# ── Diagnostics ─────────────────────────────────────────────────────────────
mkpath("results")
plot_all(series, "results/"; Tref=10.0)

# ── Model identification ─────────────────────────────────────────────────────
Tref = 10.0
r2s   = fit2S2P1D(series[1], Tref)
r1s   = fit1S2P1D(series[1], Tref)
rhs   = fitHS(series[1], Tref)

println(r2s)
println(r1s)
println(rhs)

# ── Result plot ──────────────────────────────────────────────────────────────
plot_model_fit(series, [r2s, r1s, rhs], "results/"; Tref=Tref)

# ── Spot evaluation ──────────────────────────────────────────────────────────
for f_hz in [0.1, 1.0, 10.0]
    E = r2s(2π * f_hz)
    @printf("f = %5.1f Hz  →  |E*| = %8.1f MPa   φ = %5.2f °\n",
            f_hz, abs(E), angle(E)*180/π)
end
```
