# Data I/O

```@meta
CurrentModule = ViscoAnalysis
```

## Excel file format

Each sheet of the workbook must have exactly **four columns** and a header row:

| Column | Content | Unit |
|--------|---------|------|
| 1 | Temperature T | °C |
| 2 | Frequency f | Hz |
| 3 | Complex modulus norm \|E\*\| | Pa **or** MPa |
| 4 | Phase angle φ | degrees (°) |

**Isotherm layout (default):** rows are grouped by temperature — all frequencies
for one temperature appear consecutively.

**Isochrone layout (`Iso=true`):** rows are grouped by frequency — all temperatures
for one frequency appear consecutively.

Multiple sheets in the same workbook are each loaded as an independent [`DataSeries`](@ref).

---

## Types

```@docs
DataSeries
AbstractFitResult
FitResult2S2P1D
FitResult1S2P1D
FitResultHS
model_name
```

---

## Functions

```@docs
load_data
```

---

## DataSeries — field reference

After calling [`load_data`](@ref) the returned [`DataSeries`](@ref) objects have the
following fields:

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Sheet name from the workbook |
| `MPa` | `Bool` | `true` if modulus is stored in MPa |
| `Iso` | `Bool` | `true` if data is in isochrone layout |
| `list_temp` | `Vector{Float64}` | Sorted unique temperatures [°C] |
| `list_freq` | `Vector{Float64}` | Sorted unique frequencies [Hz] |
| `list_omega` | `Vector{Float64}` | Sorted unique angular frequencies [rad/s] |
| `wlf` | `Union{Nothing, Function}` | Fitted WLF function `T → log₁₀(aT)` |
| `C1`, `C2` | `Float64` | WLF coefficients at the chosen `Tref` |

Each temperature entry `d[T]` is a `Dict{String, Any}` with keys:

| Key | Description |
|-----|-------------|
| `"f"` | Frequencies [Hz] |
| `"omega"` | Angular frequencies [rad/s] |
| `"\|M*\|"` | Modulus norm [MPa] |
| `"delta"` | Phase angle [°] |
| `"M*"` | Complex modulus [MPa] |
| `"M*_1"` | Storage modulus E₁ [MPa] |
| `"M*_2"` | Loss modulus E₂ [MPa] |

### Dict-like access

`DataSeries` supports a dict-like interface:

```julia
d = series[1]
d[10.0]              # entry at T = 10 °C
haskey(d, 10.0)      # check if temperature exists
keys(d)              # all temperatures
length(d)            # number of temperature entries
for (T, entry) in d  # iteration
    ...
end
```
