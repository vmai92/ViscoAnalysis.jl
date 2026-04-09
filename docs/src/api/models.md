# Models

```@meta
CurrentModule = ViscoAnalysis
```

This module provides analytical expressions for complex modulus models and
WLF time-temperature superposition functions.  All model constructors return
**callable functions** that accept a complex frequency `p = iω`.

---

## Rheological models

```@docs
Mod2S2P1D
Mod1S2P1D
ModHS
ModGM
```

---

## WLF functions

```@docs
wlf_scalar
change_Tref_WLF
T_TEV
```

---

## Usage examples

### Evaluate a 2S2P1D model manually

```julia
using ViscoAnalysis

# Build the model function from known parameters
model = Mod2S2P1D(
    28_500.0,   # Einf [MPa]
    9.5,        # E0   [MPa]
    2.1,        # delta
    3.2e-4,     # tauE [s]
    0.185,      # k
    0.625,      # h
    450.0,      # beta
)

# Evaluate at ω = 2π·10 rad/s  (f = 10 Hz)
ω = 2π * 10.0
E_star = model(1im * ω)
@show abs(E_star)              # |E*|  [MPa]
@show angle(E_star) * 180/π   # φ     [°]
```

### WLF shift factor

```julia
log_aT = wlf_scalar(25.0, 10.0, 19.5, 108.0)
# → log₁₀(aT) for T = 25 °C, Tref = 10 °C
```

### Change reference temperature

```julia
f_new, C1_new, C2_new = change_Tref_WLF(19.5, 108.0, 10.0, 0.0)
log_aT_at0 = f_new(25.0)   # log₁₀(aT) with Tref = 0 °C
```

### Generalised Maxwell model

```julia
# Specify stiffnesses; X = relaxation times
Ei    = [1000.0, 5000.0, 20000.0]   # MPa
tau_i = [1e-1,   1e-3,   1e-5]      # s
model_gm = ModGM(tau_i; Ei=Ei)

# Or concatenate [Ei..., taui...] into a single vector
X = vcat(Ei, tau_i)
model_gm2 = ModGM(X)
```
