# ─────────────────────────────────────────────────────────────────────────────
# DataSeries — holds all measurements for one Excel sheet
# ─────────────────────────────────────────────────────────────────────────────

"""
    DataSeries

Container for complex-modulus measurements read from one Excel sheet.

# Fields
- `data`       — Dict keyed by temperature (°C) or frequency (Hz in Iso mode).
                 Each entry contains vectors for `"f"`, `"omega"`, `"|M*|"`,
                 `"delta"`, `"M*"`, `"M*_1"`, `"M*_2"`.
- `MPa`        — `true` if modulus values are already in MPa (no unit conversion).
- `Iso`        — `true` if data is organised by frequency (isochrone layout).
- `name`       — Sheet name from the workbook.
- `nb_sheet`   — Total number of sheets in the workbook.
- `list_temp`  — Sorted vector of temperatures (°C).
- `list_omega` — Sorted vector of angular frequencies (rad/s).
- `list_freq`  — Sorted vector of frequencies (Hz), or same as `list_omega` in
                 non-Iso mode.
- `wlf`        — Fitted WLF function `T -> log10(aT)`, set after calling
                 [`build_shift_factors!`](@ref).
- `C1`, `C2`   — WLF coefficients at the chosen `Tref`.
- `_wlf`, `_C1`, `_C2` — Internal WLF fit at the first temperature (used when
                 `Tref` is not in `list_temp`).
"""
mutable struct DataSeries
    data       :: Dict{Float64, Dict{String, Any}}
    MPa        :: Bool
    Iso        :: Bool
    name       :: String
    nb_sheet   :: Int
    list_temp  :: Vector{Float64}
    list_omega :: Vector{Float64}
    list_freq  :: Vector{Float64}
    wlf        :: Union{Nothing, Function}
    C1         :: Float64
    C2         :: Float64
    _wlf       :: Union{Nothing, Function}
    _C1        :: Float64
    _C2        :: Float64
end

# Dict-like interface: d[T], d[T] = val, haskey, keys, values, iterate, length
Base.getindex(d::DataSeries,  k::Float64)    = d.data[k]
Base.setindex!(d::DataSeries, v, k::Float64) = (d.data[k] = v)
Base.haskey(d::DataSeries, k)                = haskey(d.data, k)
Base.keys(d::DataSeries)                     = keys(d.data)
Base.values(d::DataSeries)                   = values(d.data)
Base.iterate(d::DataSeries, s...)            = iterate(d.data, s...)
Base.length(d::DataSeries)                   = length(d.data)

function Base.show(io::IO, d::DataSeries)
    print(io, "DataSeries(\"$(d.name)\", $(length(d.list_temp)) temps, ",
          "$(length(d.list_omega)) freqs)")
end

# ─────────────────────────────────────────────────────────────────────────────
# AbstractFitResult — common supertype for all model fit results
# ─────────────────────────────────────────────────────────────────────────────

"""
    AbstractFitResult

Abstract supertype for all rheological model fit results.
Every concrete subtype is callable: `result(ω)` returns E*(iω).

Concrete subtypes: [`FitResult2S2P1D`](@ref), [`FitResult1S2P1D`](@ref),
[`FitResultHS`](@ref).
"""
abstract type AbstractFitResult end

"""
    model_name(r::AbstractFitResult) -> String

Return the name of the rheological model used for `r`.
"""
model_name(::AbstractFitResult) = "unknown"

# ─────────────────────────────────────────────────────────────────────────────
# FitResult2S2P1D
# ─────────────────────────────────────────────────────────────────────────────

"""
    FitResult2S2P1D <: AbstractFitResult

Result of fitting the 2S2P1D model (2 Springs, 2 Parabolic, 1 Dashpot).

# Fields
- `Einf`, `E0` — Glassy / static modulus [MPa].
- `delta`      — δ shape parameter.
- `tauE`       — Relaxation time τ_E [s].
- `k`, `h`     — Exponents (0 < k < h ≤ 1).
- `beta`       — β dashpot coefficient.
- `residual`   — Weighted least-squares objective at optimum.
- `model`      — `E*(p)` function (callable).

```julia
r = fit2S2P1D(series[1], 10.0)
r(2π * 10.0)   # E* at 10 Hz
```
"""
struct FitResult2S2P1D <: AbstractFitResult
    Einf     :: Float64
    E0       :: Float64
    delta    :: Float64
    tauE     :: Float64
    k        :: Float64
    h        :: Float64
    beta     :: Float64
    residual :: Float64
    model    :: Function
end

(r::FitResult2S2P1D)(ω::Real) = r.model(1im * ω)
model_name(::FitResult2S2P1D) = "2S2P1D"

function Base.show(io::IO, r::FitResult2S2P1D)
    @printf(io, "FitResult2S2P1D\n")
    @printf(io, "  E∞   = %.4e MPa\n", r.Einf)
    @printf(io, "  E₀   = %.4e MPa\n", r.E0)
    @printf(io, "  δ    = %.4f\n",     r.delta)
    @printf(io, "  τ_E  = %.4e s\n",   r.tauE)
    @printf(io, "  k    = %.4f\n",     r.k)
    @printf(io, "  h    = %.4f\n",     r.h)
    @printf(io, "  β    = %.4e\n",     r.beta)
    @printf(io, "  residual = %.6e\n", r.residual)
end

# ─────────────────────────────────────────────────────────────────────────────
# FitResult1S2P1D
# ─────────────────────────────────────────────────────────────────────────────

"""
    FitResult1S2P1D <: AbstractFitResult

Result of fitting the 1S2P1D model (no glassy spring; E∞ is implicitly ∞).

# Fields
- `E0`       — Static modulus [MPa].
- `delta`    — δ shape parameter.
- `tauE`     — Relaxation time τ_E [s].
- `k`, `h`   — Exponents (0 < k < h ≤ 1).
- `beta`     — β dashpot coefficient.
- `residual` — Weighted least-squares objective at optimum.
- `model`    — `E*(p)` function (callable).

```julia
r = fit1S2P1D(series[1], 10.0)
r(2π * 10.0)
```
"""
struct FitResult1S2P1D <: AbstractFitResult
    E0       :: Float64
    delta    :: Float64
    tauE     :: Float64
    k        :: Float64
    h        :: Float64
    beta     :: Float64
    residual :: Float64
    model    :: Function
end

(r::FitResult1S2P1D)(ω::Real) = r.model(1im * ω)
model_name(::FitResult1S2P1D) = "1S2P1D"

function Base.show(io::IO, r::FitResult1S2P1D)
    @printf(io, "FitResult1S2P1D\n")
    @printf(io, "  E₀   = %.4e MPa\n", r.E0)
    @printf(io, "  δ    = %.4f\n",     r.delta)
    @printf(io, "  τ_E  = %.4e s\n",   r.tauE)
    @printf(io, "  k    = %.4f\n",     r.k)
    @printf(io, "  h    = %.4f\n",     r.h)
    @printf(io, "  β    = %.4e\n",     r.beta)
    @printf(io, "  residual = %.6e\n", r.residual)
end

# ─────────────────────────────────────────────────────────────────────────────
# FitResultHS
# ─────────────────────────────────────────────────────────────────────────────

"""
    FitResultHS <: AbstractFitResult

Result of fitting the Huet-Sayegh model (no dashpot; β → ∞).

# Fields
- `Einf`, `E0` — Glassy / static modulus [MPa].
- `delta`      — δ shape parameter.
- `tauE`       — Relaxation time τ_E [s].
- `k`, `h`     — Exponents (0 < k < h ≤ 1).
- `residual`   — Weighted least-squares objective at optimum.
- `model`      — `E*(p)` function (callable).

```julia
r = fitHS(series[1], 10.0)
r(2π * 10.0)
```
"""
struct FitResultHS <: AbstractFitResult
    Einf     :: Float64
    E0       :: Float64
    delta    :: Float64
    tauE     :: Float64
    k        :: Float64
    h        :: Float64
    residual :: Float64
    model    :: Function
end

(r::FitResultHS)(ω::Real) = r.model(1im * ω)
model_name(::FitResultHS) = "Huet-Sayegh"

function Base.show(io::IO, r::FitResultHS)
    @printf(io, "FitResultHS (Huet-Sayegh)\n")
    @printf(io, "  E∞   = %.4e MPa\n", r.Einf)
    @printf(io, "  E₀   = %.4e MPa\n", r.E0)
    @printf(io, "  δ    = %.4f\n",     r.delta)
    @printf(io, "  τ_E  = %.4e s\n",   r.tauE)
    @printf(io, "  k    = %.4f\n",     r.k)
    @printf(io, "  h    = %.4f\n",     r.h)
    @printf(io, "  residual = %.6e\n", r.residual)
end
