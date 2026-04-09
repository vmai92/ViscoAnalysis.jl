# Data I/O

Functions for reading experimental data from Excel workbooks.

---

## Types

```@docs
DataSeries
```

---

## Loading data

```@docs
load_data
```

---

## Data access

A [`DataSeries`](@ref) supports dict-like indexing. The key is a temperature
(in °C, as `Float64`):

```julia
d = series[1]

# Access all measurements at T = 10 °C
e = d[10.0]

e["f"]      # frequencies [Hz]
e["omega"]  # angular frequencies [rad/s] = 2π·f
e["|M*|"]   # modulus magnitudes [MPa]
e["delta"]  # phase angles [°]
e["M*"]     # complex moduli [MPa]
e["M*_1"]   # storage moduli  E₁ = |E*|·cos φ [MPa]
e["M*_2"]   # loss moduli     E₂ = |E*|·sin φ [MPa]
```

Additional keys added by [`build_Kramers_Kronig!`](@ref):

```julia
e["delta/90"]            # φ/90 (normalised phase angle)
e["dlog|M*|/dlogomega"]  # d log|E*| / d log ω
e["Erreur K.K."]         # relative Kramers-Kronig error
```

---

## Utility methods on DataSeries

| Method | Description |
|--------|-------------|
| `d[T]` | Access entry at temperature `T` |
| `haskey(d, T)` | Check if temperature `T` is present |
| `keys(d)` | All temperatures |
| `length(d)` | Number of temperature entries |
| `println(d)` | Human-readable summary |

---

## Excel format specification

```
┌─────────┬──────────┬──────────────┬──────────┐
│  T (°C) │  f (Hz)  │  |E*| (Pa)  │  φ (°)   │
├─────────┼──────────┼──────────────┼──────────┤
│    0    │   0.01   │   2.450e9    │   12.5   │
│    0    │   0.1    │   2.521e9    │   13.1   │
│   10    │   0.01   │   2.200e9    │   15.2   │
│   …     │    …     │      …       │    …     │
└─────────┴──────────┴──────────────┴──────────┘
```

- Rows grouped by temperature (isothermal layout, `Iso=false`, default)
- Or grouped by frequency (isochrone layout, `Iso=true`)
- Modulus in Pa by default (`MPa=false`); set `MPa=true` if already in MPa
