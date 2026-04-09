# ─────────────────────────────────────────────────────────────────────────────
# Rheological models and WLF time-temperature superposition
# ─────────────────────────────────────────────────────────────────────────────

"""
    Mod2S2P1D(Einf, E0, delta, tauE, k, h, beta) -> Function

Return the 2S2P1D complex modulus function `E*(p)`, where `p = iω`.

The 2S2P1D (2 Springs, 2 Parabolic elements, 1 Dashpot) model is:

    E*(p) = E∞ + (E₀ - E∞) / (1 + δ(pτ)^{-k} + (pτ)^{-h} + 1/(pβτ))

# Arguments
- `Einf`  — Glassy modulus E∞ [MPa] (high-frequency limit).
- `E0`    — Static modulus E₀ [MPa] (zero-frequency limit, E₀ < E∞).
- `delta` — δ shape parameter.
- `tauE`  — Relaxation time τ_E [s].
- `k`     — Low-frequency exponent (0 < k < h).
- `h`     — High-frequency exponent (k < h ≤ 1).
- `beta`  — β dashpot coefficient.

# Returns
A function `p -> ComplexF64` that evaluates E*(p) at complex frequency `p`.

# Example
```julia
model = Mod2S2P1D(30_000.0, 10.0, 2.0, 1e-3, 0.2, 0.6, 500.0)
E_star = model(1im * ω)     # complex modulus at angular frequency ω
```
"""
function Mod2S2P1D(Einf::Real, E0::Real, delta::Real,
                   tauE::Real, k::Real, h::Real, beta::Real)
    return p -> Einf + (E0 - Einf) /
                (1.0 + delta*(p*tauE)^(-k) + (p*tauE)^(-h) + 1.0/(p*beta*tauE))
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    ModGM(X; Ei=nothing, taui=nothing) -> Function

Return the Generalised Maxwell complex modulus function `G*(p)`.

Provide either:
- `Ei` (stiffnesses) → `X` is treated as the relaxation times τᵢ, **or**
- `taui` (times) → `X` is treated as the stiffnesses Eᵢ, **or**
- neither → `X = [E₁, E₂, …, τ₁, τ₂, …]` (concatenated, equal halves).

# Example
```julia
Ei   = [1e4, 5e3, 1e3]
taui = [1e-4, 1e-2, 1.0]
model = ModGM(taui; Ei=Ei)
G_star = model(1im * ω)
```
"""
function ModGM(X; Ei=nothing, taui=nothing)
    if Ei !== nothing
        Ei_v, τi_v = Float64.(Ei), Float64.(X)
    elseif taui !== nothing
        Ei_v, τi_v = Float64.(X), Float64.(taui)
    else
        n    = length(X) ÷ 2
        Ei_v = Float64.(X[begin:begin+n-1])
        τi_v = Float64.(X[begin+n:end])
    end
    function Gmod(p)
        l = Ei_v[1]
        for i in 2:length(Ei_v)
            l += (Ei_v[i] * τi_v[i] * p) / (1.0 + τi_v[i] * p)
        end
        return l
    end
    return Gmod
end

# ─────────────────────────────────────────────────────────────────────────────
# WLF time-temperature superposition
# ─────────────────────────────────────────────────────────────────────────────

"""
    wlf_scalar(T, Tref, C1, C2) -> Float64

Evaluate the WLF shift factor: `log₁₀(aT) = -C1·(T - Tref) / (C2 + T - Tref)`.
"""
wlf_scalar(T, Tref, C1, C2) = -C1 * (T - Tref) / (C2 + T - Tref)

"""
    T_TEV(Om, Tref, C1, C2, Omc) -> Float64

Inverse WLF: return the temperature at which angular frequency `Om` is
equivalent to `Omc` at `Tref`.
"""
function T_TEV(Om, Tref, C1, C2, Omc)
    return (Tref * C1 - (log10(Omc) - log10(Om)) * (C2 - Tref)) /
           (C1        + (log10(Omc) - log10(Om)))
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    Mod1S2P1D(E0, delta, tauE, k, h, beta) -> Function

Return the 1S2P1D complex modulus function `E*(p)` (one spring variant,
no glassy branch):

    E*(p) = E₀ / (1 + δ(pτ)^{-k} + (pτ)^{-h} + 1/(pβτ))

# Arguments
- `E0`    — Static modulus E₀ [MPa].
- `delta` — δ shape parameter.
- `tauE`  — Relaxation time τ_E [s].
- `k`     — Low-frequency exponent (0 < k < h).
- `h`     — High-frequency exponent (k < h ≤ 1).
- `beta`  — β dashpot coefficient.
"""
function Mod1S2P1D(E0::Real, delta::Real, tauE::Real,
                   k::Real, h::Real, beta::Real)
    return p -> E0 / (1.0 + delta*(p*tauE)^(-k) + (p*tauE)^(-h) + 1.0/(p*beta*tauE))
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    ModHS(Einf, E0, delta, tauE, k, h) -> Function

Return the Huet-Sayegh complex modulus function `E*(p)` (no dashpot, β → ∞):

    E*(p) = E∞ + (E₀ - E∞) / (1 + δ(pτ)^{-k} + (pτ)^{-h})

# Arguments
- `Einf`  — Glassy modulus E∞ [MPa].
- `E0`    — Static modulus E₀ [MPa].
- `delta` — δ shape parameter.
- `tauE`  — Relaxation time τ_E [s].
- `k`     — Low-frequency exponent (0 < k < h).
- `h`     — High-frequency exponent (k < h ≤ 1).
"""
function ModHS(Einf::Real, E0::Real, delta::Real,
               tauE::Real, k::Real, h::Real)
    return p -> Einf + (E0 - Einf) / (1.0 + delta*(p*tauE)^(-k) + (p*tauE)^(-h))
end

# ─────────────────────────────────────────────────────────────────────────────
# Internal: WLF model closure for LsqFit (T_vec → log10(aT) vector)
function _WLF_lsq(Tref)
    return (T_vec::AbstractVector, p::AbstractVector) ->
        [-p[1] * (T - Tref) / (p[2] + T - Tref) for T in T_vec]
end

# Internal: analytical Jacobian for LsqFit
function _jac_WLF_lsq(Tref)
    return (T_vec::AbstractVector, p::AbstractVector) -> begin
        c1, c2 = p[1], p[2]
        J = Matrix{Float64}(undef, length(T_vec), 2)
        for (i, T) in enumerate(T_vec)
            J[i, 1] = -(T - Tref) / (c2 + T - Tref)
            J[i, 2] =  c1 * (T - Tref) / (c2 + T - Tref)^2
        end
        J
    end
end
