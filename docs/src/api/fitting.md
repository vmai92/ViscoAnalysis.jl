# Analysis & Fitting

Functions for master curve construction, Kramers-Kronig verification,
model identification, and result evaluation.

---

## Master curve

```@docs
build_shift_factors!
build_master_curve
```

**Example:**

```julia
# Compute shift factors and fit WLF at Tref = 10 °C
log_aT = build_shift_factors!(d, 10.0)

println("C₁ = $(d.C1)")
println("C₂ = $(d.C2)")

# Build complex master curve
ω_r, E_r = build_master_curve(d, "M*", 10.0)
```

---

## Kramers-Kronig verification

```@docs
build_Kramers_Kronig!
```

After calling `build_Kramers_Kronig!`, the following keys are added to each
temperature entry in the [`DataSeries`](@ref):

| Key | Description |
|-----|-------------|
| `"delta/90"` | ``\varphi / 90`` (normalised phase angle) |
| `"dlog\|M*\|/dlogomega"` | ``\mathrm{d}\log|E^*|/\mathrm{d}\log\omega`` |
| `"Erreur K.K."` | Relative error (dimensionless) |

The BT2 approximation (Booij & Thoone 1982):

```math
\varepsilon_\text{KK}(\omega) =
\left|\frac{\varphi(\omega)/90}
           {\mathrm{d}\log|E^*|/\mathrm{d}\log\omega} - 1\right|
```

Values below 5% indicate good data quality and TTS validity.

---

## Model identification

All `fit*` functions build the master curve internally, then minimise the
log-frequency-weighted objective:

```math
J = \sum_{i} \Delta\log\omega_i
    \left|1 - \frac{E^*_\text{model}(\omega_i)}{E^*_\text{data}(\omega_i)}\right|^2
```

```@docs
fit2S2P1D
fit1S2P1D
fitHS
```

### Optimisation settings

| Function | Algorithm | Max. evaluations |
|----------|-----------|-----------------|
| `fit2S2P1D` | `:LN_SBPLX` | 100 000 |
| `fit1S2P1D` | `:LN_NELDERMEAD` | 500 000 |
| `fitHS` | `:LN_NELDERMEAD` | 500 000 |

Initial bounds used by `fit2S2P1D`:

| Parameter | Lower | Upper |
|-----------|-------|-------|
| ``E_\infty`` | 0 | 10⁶ MPa |
| ``E_0`` | 10⁻⁶ | 10⁶ MPa |
| ``\delta`` | 10⁻⁶ | 10⁶ |
| ``\tau`` | 10⁻⁶ s | 10⁶ s |
| ``k`` | 0.1 | 1.0 |
| ``h`` | 0.1 | 1.0 |
| ``\beta`` | 10⁻⁶ | ∞ |

---

## Evaluation helpers

```@docs
eval_model
eval_array
```

**Example:**

```julia
# Evaluate a fitted model over a frequency sweep
ω_vec = 10 .^ range(-3, 4; length=300) .* 2π    # 1 mHz → 10 kHz

re, im_part, absval, deg = eval_model(result, ω_vec)

# Or decompose a pre-computed vector
E_vec = [result(ω) for ω in ω_vec]
re, im_part, absval, deg = eval_array(E_vec)
```

---

## WLF reference change

```@docs
change_Tref_WLF
```

**Example:**

```julia
# Fit at Tref = 10 °C, then convert to Tref = 0 °C
wlf_0, C1_0, C2_0 = change_Tref_WLF(d.C1, d.C2, 10.0, 0.0)
log_aT_at_50 = wlf_0(50.0)   # log₁₀(aT) at 50 °C relative to 0 °C
```
