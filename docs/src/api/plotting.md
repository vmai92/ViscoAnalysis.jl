# Plotting

All plotting functions accept a `Vector{DataSeries}` and an output directory,
and save figures as both **PDF** and **PNG**.
Figures are named automatically from the sheet name (e.g. `isothermes_Sheet1.pdf`).

---

## Convenience wrapper

```@docs
plot_all
```

`plot_all` calls, in order:
`plot_isothermes`, `plot_isochrones`, `plot_cole_cole`, `plot_black`,
`plot_kramers_kronig`, `plot_wlf`, `plot_wlf_stability`.

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

| Function | File name |
|----------|-----------|
| `plot_isothermes` | `isothermes_<name>.{pdf,png}` |
| `plot_isochrones` | `isochrones_<name>.{pdf,png}` |
| `plot_cole_cole` | `Cole-Cole_<name>.{pdf,png}` |
| `plot_black` | `Black_<name>.{pdf,png}` |
| `plot_kramers_kronig` | `Kramers-Kronig_<name>.{pdf,png}` |
| `plot_wlf` | `WLF_<name>.{pdf,png}` |
| `plot_wlf_stability` | `WLF_stability_<name>.{pdf,png}` |
| `plot_model_fit` | `Results_<model>_Tref<T>.{pdf,png}` |

---

## Diagram descriptions

### Isothermal sweeps
``|E^*|`` and ``\varphi`` versus frequency ``f`` [Hz], with one curve per
temperature. Useful to identify the measured frequency range and spot
outliers.

### Isochronal sweeps
``|E^*|`` and ``\varphi`` versus temperature ``T`` [°C], with one curve per
frequency. Useful to assess the thermal sensitivity of the material.

### Cole-Cole diagram
Loss modulus ``E_2 = |E^*|\sin\varphi`` versus storage modulus
``E_1 = |E^*|\cos\varphi`` on log-log axes.
For a TTS-valid material all isotherms collapse onto a single arch.

### Black diagram
``|E^*|`` (log scale) versus ``\varphi``.
Like the Cole-Cole diagram, a TTS-valid material traces a unique master curve
independent of temperature.

### Kramers-Kronig diagram
Normalised phase angle ``\varphi/90`` versus the slope
``\mathrm{d}\log|E^*|/\mathrm{d}\log\omega``.
Points lying close to the diagonal ``y = x`` indicate causally consistent data.

### WLF diagram
Experimental shift factors ``\log_{10} a_T`` versus temperature, with the
fitted WLF curve overlaid. Iterated for every available reference temperature.

### WLF stability diagram
WLF curves fitted at all available reference temperatures and at midpoints
between consecutive temperatures, plotted together. A stable fit gives nearly
coincident curves.

### Model fit diagram
Experimental master curve (``|E^*|`` and ``\varphi`` versus reduced frequency)
with the identified model overlaid. Accepts multiple model results simultaneously.

---

## Example

```julia
series = load_data("data.xlsx"; MPa=true)
mkpath("figs")

# All diagnostics
plot_all(series, "figs/"; Tref=10.0)

# Fit and plot model
r = fit2S2P1D(series[1], 10.0)
plot_model_fit(series, [r], "figs/"; Tref=10.0)
```
