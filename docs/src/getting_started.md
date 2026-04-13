# Getting Started

This page walks you through the complete ViscoAnalysis workflow step by step,
from preparing your Excel data file to saving publication-quality figures and
fitted model parameters.

---

## 1. Prepare your Excel file

Each sheet of the workbook must contain exactly **four columns** with a header row:

| Column | Content | Unit |
|--------|---------|------|
| 1 | Temperature T | °C |
| 2 | Frequency f | Hz |
| 3 | Complex modulus norm \|E\*\| | Pa **or** MPa |
| 4 | Phase angle φ | degrees (°) |

**Row organisation (isotherms mode, default):**  
All frequencies for one temperature appear consecutively, then the next temperature
block begins.

```
T=−10  f₁  |E*|₁  φ₁
T=−10  f₂  |E*|₂  φ₂
  …
T=  0  f₁  |E*|₁  φ₁
T=  0  f₂  |E*|₂  φ₂
  …
```

**Isochrone mode (`Iso=true`):**  
Rows are grouped by frequency instead of temperature.

Multiple sheets in the same workbook are each loaded as an independent
[`DataSeries`](@ref) object.

---

## 2. Load your data

```julia
using ViscoAnalysis

# Modulus in MPa — pass MPa=true so no unit conversion is applied
series = load_data("my_data.xlsx"; MPa=true)

# Modulus in Pa — the package divides by 10⁶ automatically
series = load_data("my_data.xlsx"; MPa=false)
```

Inspect the loaded data:

```julia
d = series[1]           # first sheet
println(d.name)         # sheet name
println(d.list_temp)    # temperatures [°C]
println(d.list_freq)    # frequencies  [Hz]
println(d.list_omega)   # angular freq [rad/s]

# Access one temperature block
entry = d[10.0]         # Dict with measurement at T = 10 °C
entry["|M*|"]           # vector of |E*| values [MPa]
entry["delta"]          # vector of phase angles [°]
entry["M*"]             # vector of complex modulus values
```

---

## 3. Generate all diagnostic plots

```julia
mkpath("results/")
plot_all(series, "results/"; Tref=10.0)
```

This runs seven plots for every `DataSeries` and saves both **PDF** and **PNG** files:

| File | Plot |
|------|------|
| `isothermes_<name>.*` | \|E\*\| and φ vs frequency, one curve per temperature |
| `isochrones_<name>.*` | \|E\*\| and φ vs temperature, one curve per frequency |
| `Cole-Cole_<name>.*` | E₂ (imaginary) vs E₁ (real) |
| `Black_<name>.*` | \|E\*\| vs φ (semi-log) |
| `Kramers-Kronig_<name>.*` | Kramers-Kronig consistency check |
| `WLF_<name>.*` | Shift factors log(aT) vs T with fitted WLF curve |
| `WLF_stability_<name>.*` | WLF curves across all reference temperatures |

---

## 4. Fit a rheological model

Choose one of the three available models:

| Function | Model | Parameters |
|----------|-------|-----------|
| [`fit2S2P1D`](@ref) | 2 Springs, 2 Parabolic elements, 1 Dashpot | 7 |
| [`fit1S2P1D`](@ref) | 1 Spring, 2 Parabolic elements, 1 Dashpot | 6 |
| [`fitHS`](@ref) | Huet-Sayegh (no dashpot) | 6 |

```julia
# Fit the 2S2P1D model on the master curve at Tref = 10 °C
result = fit2S2P1D(series[1], 10.0)
println(result)   # prints all parameters and the residual
```

Example output:

```
2S2P1D model — Tref = 10.0 °C
  E∞     =  28500.0  MPa
  E₀     =      9.5  MPa
  δ      =      2.1
  τ_E    =  0.00032  s
  k      =    0.185
  h      =    0.625
  β      =    450.0
  residual = 0.00412
```

The returned `FitResult2S2P1D` object is **callable** — evaluate the fitted complex
modulus at any angular frequency:

```julia
ω = 2π * 10.0          # 10 Hz at Tref
E_star = result(ω)     # complex number [MPa]
@show abs(E_star)              # |E*|  [MPa]
@show angle(E_star) * 180/π   # φ     [°]
```

---

## 5. Plot the model fit

```julia
plot_model_fit(series, [result], "results/"; Tref=10.0)
```

Saves `Results_2S2P1D_Tref10.pdf` and `.png` showing the experimental master curve
and the fitted model overlay.

---

## 6. Compare multiple models

```julia
d = series[1]
r1 = fit2S2P1D(d, 10.0)
r2 = fit1S2P1D(d, 10.0)
r3 = fitHS(d, 10.0)

println(r1); println(r2); println(r3)

plot_model_fit([d], [r1], "results/"; Tref=10.0)
plot_model_fit([d], [r2], "results/"; Tref=10.0)
plot_model_fit([d], [r3], "results/"; Tref=10.0)
```

Each call generates a separate file whose name embeds the model name.

---

## 7. Access WLF coefficients

```julia
build_shift_factors!(series[1], 10.0)   # computes and stores WLF in d
d = series[1]
println("C1 = $(d.C1),  C2 = $(d.C2)")
log_aT = d.wlf(25.0)    # log₁₀(aT) at 25 °C
```

Convert the WLF to a different reference temperature:

```julia
f_new, C1_new, C2_new = change_Tref_WLF(d.C1, d.C2, 10.0, 0.0)
log_aT_at0 = f_new(25.0)   # log₁₀(aT) with Tref = 0 °C
```

---

## 8. Build and inspect a master curve manually

```julia
ω_red, E_complex = build_master_curve(series[1], "M*", 10.0)
ω_red, E_abs     = build_master_curve(series[1], "|M*|", 10.0)
ω_red, phi_deg   = build_master_curve(series[1], "delta", 10.0)
```

`ω_red` is the reduced angular frequency `ω × aT(T)` sorted in ascending order.

---

## Run the complete example

A ready-to-run script is available at [`examples/quickstart.jl`](../examples/quickstart.jl):

```bash
julia --project=. examples/quickstart.jl
```
