# Plotting

```@meta
CurrentModule = ViscoAnalysis
```

All plotting functions accept a `Vector{DataSeries}` and an output directory.
Each function saves the figure as both **PDF** and **PNG**.

---

## Convenience wrapper

```@docs
plot_all
```

---

## Individual plot functions

```@docs
plot_isothermes
plot_isochrones
plot_cole_cole
plot_black
plot_kramers_kronig
plot_wlf
plot_wlf_stability
plot_model_fit
```

---

## Output file naming

| Function | Output filename |
|----------|----------------|
| `plot_isothermes` | `isothermes_<sheetname>.pdf` / `.png` |
| `plot_isochrones` | `isochrones_<sheetname>.pdf` / `.png` |
| `plot_cole_cole` | `Cole-Cole_<sheetname>.pdf` / `.png` |
| `plot_black` | `Black_<sheetname>.pdf` / `.png` |
| `plot_kramers_kronig` | `Kramers-Kronig_<sheetname>.pdf` / `.png` |
| `plot_wlf` | `WLF_<sheetname>.pdf` / `.png` |
| `plot_wlf_stability` | `WLF_stability_<sheetname>.pdf` / `.png` |
| `plot_model_fit` | `Results_<modelname>_Tref<T>.pdf` / `.png` |

---

## Plot descriptions

### Isothermal curves

`plot_isothermes` shows |E\*| and φ as a function of frequency, with one curve
per temperature.  Temperatures are colour-coded from cold (blue) to hot (red).

### Isochrone curves

`plot_isochrones` shows |E\*| and φ as a function of temperature, with one curve
per frequency.

### Cole-Cole diagram

`plot_cole_cole` plots the loss modulus ``E_2`` (imaginary part) against the
storage modulus ``E_1`` (real part) on a log-log scale.  For a thermorheologically
simple material, all temperature curves collapse onto a single arc.

### Black diagram

`plot_black` plots |E\*| (log scale) against φ (linear scale).  Like the Cole-Cole
diagram, a unique curve indicates thermorheological simplicity.

### Kramers-Kronig verification

`plot_kramers_kronig` displays the BT2 approximation check:
``d\log|E^*|/d\log\omega`` vs ``\varphi/90°``.  Points should fall near the
``y = x`` line for consistent viscoelastic data.

### WLF shift factors

`plot_wlf` displays the computed shift factors ``\log_{10}(a_T)`` against temperature
together with the fitted WLF curve, for each reference temperature in
`d.list_temp`.

### WLF stability

`plot_wlf_stability` overlays the WLF curves computed for all tested reference
temperatures (solid lines) and intermediate midpoints (dashed lines) to assess
the stability of the WLF identification.

### Model overlay

`plot_model_fit` shows the experimental master curve (symbols) and the fitted
model (lines) on two panels: |E\*| and φ vs reduced angular frequency ``\omega a_T``.

---

## Usage examples

### Generate all plots at once

```julia
using ViscoAnalysis

series = load_data("data.xlsx"; MPa=true)
mkpath("figures/")
plot_all(series, "figures/"; Tref=10.0)
```

### Plot individual diagnostics

```julia
plot_isothermes(series, "figures/")
plot_cole_cole(series,  "figures/")
plot_black(series,      "figures/")
plot_wlf(series,        "figures/")
```

### Overlay a fitted model

```julia
r = fit2S2P1D(series[1], 10.0)
plot_model_fit(series, [r], "figures/"; Tref=10.0)
```

### Plot multiple models on the same data sheet

```julia
d = series[1]
r1 = fit2S2P1D(d, 10.0)
r2 = fitHS(d, 10.0)

# Each call creates a separate file, named after the model
plot_model_fit([d], [r1], "figures/"; Tref=10.0)
plot_model_fit([d], [r2], "figures/"; Tref=10.0)
```
