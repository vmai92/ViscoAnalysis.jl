# Fitting & Analysis

```@meta
CurrentModule = ViscoAnalysis
```

This module implements:

- **Shift factor computation** and WLF fitting ([`build_shift_factors!`](@ref))
- **Master curve construction** ([`build_master_curve`](@ref))
- **Kramers-Kronig verification** ([`build_Kramers_Kronig!`](@ref))
- **Global model identification** ([`fit2S2P1D`](@ref), [`fit1S2P1D`](@ref), [`fitHS`](@ref))
- **Model evaluation helpers** ([`eval_model`](@ref), [`eval_array`](@ref))

---

## Shift factors and master curve

```@docs
build_shift_factors!
build_master_curve
build_Kramers_Kronig!
```

---

## Model identification

```@docs
fit2S2P1D
fit1S2P1D
fitHS
```

---

## Model evaluation

```@docs
eval_model
eval_array
```

---

## Optimisation details

All three fitters minimise the same **frequency-weighted least-squares** objective
over the complex master curve:

```math
J = \sum_k \Delta\log\omega_k \left|1 - \frac{E^*(\omega_k)}{E^*_{\text{exp}}(\omega_k)}\right|^2
```

The ``\Delta\log\omega_k`` weight is computed as half the log-frequency spacing to
adjacent points, so that every frequency decade contributes equally regardless of
sampling density.

| Fitter | Optimiser | Max evals | Parameters |
|--------|-----------|-----------|-----------|
| `fit2S2P1D` | NLopt `:LN_SBPLX` | 100 000 | E∞, E₀, δ, τ, k, h, β |
| `fit1S2P1D` | NLopt `:LN_NELDERMEAD` | 500 000 | E₀, δ, τ, k, h, β |
| `fitHS` | NLopt `:LN_NELDERMEAD` | 500 000 | E∞, E₀, δ, τ, k, h |

The constraint ``k < h`` is enforced for all models.

---

## FitResult fields

### `FitResult2S2P1D`

| Field | Description |
|-------|-------------|
| `Einf` | ``E_\infty`` — glassy modulus [MPa] |
| `E0` | ``E_0`` — static modulus [MPa] |
| `delta` | ``\delta`` — shape parameter |
| `tauE` | ``\tau_E`` — relaxation time [s] |
| `k` | low-frequency exponent |
| `h` | high-frequency exponent |
| `beta` | ``\beta`` — dashpot coefficient |
| `residual` | final value of the objective function J |
| `model` | callable `E*(p)` function |

### `FitResult1S2P1D`

Same as above except no `Einf` field (6 parameters total).

### `FitResultHS`

Same as `FitResult2S2P1D` except no `beta` field (6 parameters total).

---

## Usage examples

### Full pipeline

```julia
using ViscoAnalysis

series = load_data("data.xlsx"; MPa=true)
d = series[1]

# Compute shift factors and WLF
loga = build_shift_factors!(d, 10.0)
println("C1 = $(d.C1),  C2 = $(d.C2)")

# Build the complex master curve
ω_red, E_complex = build_master_curve(d, "M*", 10.0)

# Fit the 2S2P1D model
r = fit2S2P1D(d, 10.0)
println(r)

# Evaluate the model over a frequency range
ω_range = 10 .^ range(-4, 4, length=200) .* 2π
re, im_part, absval, deg = eval_model(r.model, ω_range)
```

### Kramers-Kronig check

```julia
build_Kramers_Kronig!(d)
entry = d[10.0]
println("KK error at T=10°C: ", entry["Erreur K.K."])
```

### Evaluate a pre-computed array

```julia
E_arr = [r(ω) for ω in ω_range]   # Vector{Complex}
re, im_part, absval, deg = eval_array(E_arr)
```
