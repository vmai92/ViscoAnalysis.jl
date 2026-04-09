# Rheological Models

Functions that return a callable ``E^*(p)`` function given model parameters.
See [Theory](@ref) for the mathematical definition of each model.

---

## 2S2P1D model

```@docs
Mod2S2P1D
```

**Formula:**

```math
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + (p\beta\tau)^{-1}}
```

**Usage:**

```julia
model = Mod2S2P1D(28_000.0, 8.0, 2.3, 0.02, 0.19, 0.62, 500.0)
#                 E∞ [MPa]  E₀   δ    τ [s]  k     h     β

E_star = model(1im * ω)     # evaluate at angular frequency ω [rad/s]
```

---

## 1S2P1D model

```@docs
Mod1S2P1D
```

**Formula:**

```math
E^*(p) = \frac{E_0}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + (p\beta\tau)^{-1}}
```

---

## Huet-Sayegh model

```@docs
ModHS
```

**Formula:**

```math
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h}}
```

---

## Generalised Maxwell model

```@docs
ModGM
```

**Formula:**

```math
G^*(p) = E_1 + \sum_{i=2}^{N} \frac{E_i\,\tau_i\,p}{1 + \tau_i\,p}
```

---

## WLF time-temperature superposition

```@docs
wlf_scalar
T_TEV
change_Tref_WLF
```

**WLF equation:**

```math
\log_{10} a_T(T) = \frac{-C_1\,(T - T_\text{ref})}{C_2 + T - T_\text{ref}}
```

**Reference temperature change:**

```math
C_2^\text{new} = C_2^\text{old} + T_\text{ref}^\text{new} - T_\text{ref}^\text{old}
\qquad
C_1^\text{new} = \frac{C_1^\text{old}\,C_2^\text{old}}{C_2^\text{new}}
```

---

## Fit result types

```@docs
AbstractFitResult
FitResult2S2P1D
FitResult1S2P1D
FitResultHS
model_name
```

All `FitResult*` types are **callable**: `result(ω)` returns the complex modulus
at angular frequency `ω` (rad/s).

```julia
r = fit2S2P1D(series[1], 10.0)
r(2π * 10.0)       # E* at 10 Hz [MPa]
abs(r(2π * 10.0))  # |E*| [MPa]
```
