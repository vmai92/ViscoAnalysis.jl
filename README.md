# ViscoAnalysis.jl

Julia package for analysing complex-modulus (viscoelastic) data from dynamic
mechanical experiments on bituminous materials.

## Features

- Reads multi-sheet Excel workbooks (one test condition per sheet)
- Builds master curves via WLF time-temperature superposition
- Fits the **2S2P1D** or **1S2P1D** or **Huet-Sayegh** rheological model 
- Produces publication-quality figures: isothermal, isochrone, Cole-Cole, Black,
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

## API reference

### Data loading

#### `load_data(filename; MPa=false, Iso=false) -> Vector{DataSeries}`

Read all sheets of an Excel workbook.

| Keyword | Default | Description |
|---------|---------|-------------|
| `MPa`   | `false` | Set `true` if the modulus column is in MPa |
| `Iso`   | `false` | Set `true` for isochrone layout (rows indexed by frequency) |

```julia
series = load_data("data.xlsx"; MPa=true)
d = series[1]           # first sheet
d.list_temp             # Vector of temperatures [°C]
d.list_omega            # Vector of angular frequencies [rad/s]
d[20.0]                 # Dict with keys: "f", "omega", "|M*|", "delta", "M*", …
```

---

### Models

#### `Mod2S2P1D(Einf, E0, delta, tauE, k, h, beta) -> Function`

Returns a callable `E*(p)` for the 2S2P1D complex modulus model:

```
E*(p) = E∞ + (E₀ - E∞) / (1 + δ(pτ)^{-k} + (pτ)^{-h} + 1/(pβτ))
```

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| `Einf`    | E∞     | Glassy (high-freq) modulus [MPa] |
| `E0`      | E₀     | Static (zero-freq) modulus [MPa] |
| `delta`   | δ      | Shape parameter |
| `tauE`    | τ_E    | Relaxation time [s] |
| `k`       | k      | Low-frequency exponent (0 < k < h) |
| `h`       | h      | High-frequency exponent (k < h ≤ 1) |
| `beta`    | β      | Dashpot coefficient |

```julia
model = Mod2S2P1D(30_000.0, 10.0, 2.0, 1e-3, 0.2, 0.6, 500.0)
E_star = model(1im * ω)   # evaluate at angular frequency ω
```

#### `ModGM(X; Ei=nothing, taui=nothing) -> Function`

Generalised Maxwell model. Provide stiffnesses `Ei` (then `X` = relaxation
times), relaxation times `taui` (then `X` = stiffnesses), or pass both
concatenated in `X`.

#### `wlf_scalar(T, Tref, C1, C2) -> Float64`

WLF shift factor: `log₁₀(aT) = -C1·(T - Tref) / (C2 + T - Tref)`.

#### `change_Tref_WLF(C1, C2, Tref_old, Tref_new) -> (f, C1_new, C2_new)`

Convert WLF coefficients from one reference temperature to another.

#### `T_TEV(Om, Tref, C1, C2, Omc) -> Float64`

Inverse WLF: temperature at which frequency `Om` is equivalent to `Omc`.

---

### Analysis

#### `build_shift_factors!(d, Tref; index_freq=1) -> Vector{Float64}`

Compute log₁₀(aT) shift factors and fit the WLF law.  Stores the result in
`d.wlf`, `d.C1`, `d.C2`.

```julia
loga = build_shift_factors!(series[1], 10.0)
println("C1 = $(series[1].C1),  C2 = $(series[1].C2)")
```

#### `build_master_curve(d, field, Tref; index_freq=1) -> (ω_red, values)`

Shift all isothermal sweeps onto a single master curve.

```julia
ω, G = build_master_curve(series[1], "M*", 10.0)
```

#### `build_Kramers_Kronig!(d)`

Compute Kramers-Kronig (BT2) verification data in-place.  Adds keys
`"delta/90"`, `"dlog|M*|/dlogomega"`, and `"Erreur K.K."` to each temperature
entry.

#### `fit2S2P1D(d, Tref; index_freq=1) -> FitResult2S2P1D`

Identify the 2S2P1D model parameters on the complex master curve at `Tref`.

```julia
result = fit2S2P1D(series[1], 10.0)
println(result)          # pretty-print all 7 parameters + residual

ω = 2π * 10.0            # 10 Hz → rad/s
E_star = result(ω)       # E*(ω) at Tref
@show abs(E_star)        # |E*| [MPa]
@show angle(E_star) * 180/π   # φ [°]
```

##### `FitResult2S2P1D` fields

| Field      | Description                            |
|------------|----------------------------------------|
| `Einf`     | E∞ [MPa]                               |
| `E0`       | E₀ [MPa]                               |
| `delta`    | δ                                      |
| `tauE`     | τ_E [s]                                |
| `k`        | k exponent                             |
| `h`        | h exponent                             |
| `beta`     | β                                      |
| `residual` | Final weighted least-squares objective |
| `model`    | Callable `E*(p)` function              |

---

### Plotting

All plot functions write PDF and PNG files to the specified output directory.

| Function | Output file(s) | Description |
|----------|---------------|-------------|
| `plot_all(series, outdir)` | (all below) | Run every diagnostic plot |
| `plot_isothermes(series, outdir)` | `isothermes_<name>.*` | \|E*\| and φ vs f, per temperature |
| `plot_isochrones(series, outdir)` | `isochrones_<name>.*` | \|E*\| and φ vs T, per frequency |
| `plot_cole_cole(series, outdir)` | `Cole-Cole_<name>.*` | E₂ vs E₁ (log-log) |
| `plot_black(series, outdir)` | `Black_<name>.*` | \|E*\| vs φ (semi-log) |
| `plot_kramers_kronig(series, outdir)` | `Kramers-Kronig_<name>.*` | KK verification |
| `plot_wlf(series, outdir)` | `WLF_<name>.*` | Shift factors + WLF fit |
| `plot_wlf_stability(series, outdir)` | `WLF_stability_<name>.*` | WLF across all Tref |
| `plot_model_fit(series, results, outdir; Tref)` | `Results_Tref<T>.*` | Master curve + 2S2P1D overlay |

---

## Output file structure

After running the quickstart example, the output directory contains:

```
results/
├── isothermes_<name>.pdf / .png
├── isochrones_<name>.pdf / .png
├── Cole-Cole_<name>.pdf / .png
├── Black_<name>.pdf / .png
├── Kramers-Kronig_<name>.pdf / .png
├── WLF_<name>.pdf / .png
├── WLF_stability_<name>.pdf / .png
└── Results_Tref10.pdf / .png
```

---

## Dependencies

| Package       | Purpose                          |
|---------------|----------------------------------|
| XLSX.jl       | Read Excel files                 |
| DataFrames.jl | Tabular data handling            |
| Plots.jl (GR) | Figure rendering                 |
| LaTeXStrings  | Axis labels with LaTeX           |
| LsqFit.jl     | WLF nonlinear least-squares fit  |
| NLopt.jl      | 2S2P1D global optimisation       |
