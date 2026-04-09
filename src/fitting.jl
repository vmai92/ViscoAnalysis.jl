# ─────────────────────────────────────────────────────────────────────────────
# Master curve, shift factors, WLF fitting, Kramers-Kronig, 2S2P1D fit
# ─────────────────────────────────────────────────────────────────────────────

"""
    build_Kramers_Kronig!(d::DataSeries)

Compute the Kramers-Kronig (BT2) verification data for every temperature entry
in `d` and store the results in-place:

- `d[T]["delta/90"]`            — δ/90 (normalised phase angle).
- `d[T]["dlog|M*|/dlogomega"]`  — d log|E*| / d log ω (numerical derivative).
- `d[T]["Erreur K.K."]`         — Relative error between the two quantities.
"""
function build_Kramers_Kronig!(d::DataSeries)
    for (_, e) in d.data
        e["delta/90"]           = Float64[]
        e["dlog|M*|/dlogomega"] = Float64[]
        e["Erreur K.K."]        = Float64[]
        ω  = e["omega"]
        nG = e["|M*|"]
        δ  = e["delta"]
        for i in (firstindex(ω)+1):lastindex(ω)
            dG = (log10(nG[i]) - log10(nG[i-1])) / (log10(ω[i]) - log10(ω[i-1]))
            dd = 0.5 / 90.0 * (δ[i] + δ[i-1])
            push!(e["delta/90"],           dd)
            push!(e["dlog|M*|/dlogomega"], dG)
            push!(e["Erreur K.K."],        abs(dd - dG) / dd)
        end
    end
end

# ─────────────────────────────────────────────────────────────────────────────
# Internal WLF helpers
# ─────────────────────────────────────────────────────────────────────────────

function _build_WLF(d::DataSeries, Tref::Float64, tloga::Vector{Float64})
    m   = _WLF_lsq(Tref)
    jac = _jac_WLF_lsq(Tref)
    lb  = [-Inf,  Tref - d.list_temp[1]]
    ub  = [ Inf,  Inf]
    p0  = [20.0,  max(100.0, lb[2] + 1.0)]
    T_v = collect(Float64, d.list_temp)
    fit = curve_fit(m, jac, T_v, tloga, p0; lower=lb, upper=ub)
    p   = fit.param
    f   = T -> wlf_scalar(T, Tref, p[1], p[2])
    return f, p[1], p[2]
end

"""
    change_Tref_WLF(C1, C2, Tref_old, Tref_new) -> (f, C1_new, C2_new)

Convert WLF coefficients from one reference temperature to another using the
standard transformation:

    C2_new = C2_old + (Tref_new − Tref_old)
    C1_new = C1_old · C2_old / C2_new
"""
function change_Tref_WLF(C1::Real, C2::Real, Tref_old::Real, Tref_new::Real)
    C2n = C2 + Tref_new - Tref_old
    C1n = C1 * C2 / C2n
    f   = T -> wlf_scalar(T, Float64(Tref_new), C1n, C2n)
    return f, C1n, C2n
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    build_shift_factors!(d::DataSeries, Tref; index_freq=1) -> Vector{Float64}

Compute log₁₀(aT) shift factors relative to `Tref` for every temperature in
`d.list_temp` and fit a WLF law. The fitted WLF function and coefficients are
stored in `d.wlf`, `d.C1`, `d.C2`.

# Arguments
- `d`          — A [`DataSeries`](@ref) with at least two temperatures.
- `Tref`       — Reference temperature (°C). Does not have to be in
                 `d.list_temp`; the WLF is re-referenced if needed.
- `index_freq` — Index into the frequency vector used to compute incremental
                 shift steps (default: `1`, i.e. the first frequency).

# Returns
Vector of log₁₀(aT) values aligned with `d.list_temp`.
"""
function build_shift_factors!(d::DataSeries, Tref::Float64, index_freq::Int=1)
    dloga = Float64[]
    for i in 1:(length(d.list_temp) - 1)
        ei   = d[d.list_temp[i]]
        eip1 = d[d.list_temp[i+1]]
        dG = log10(ei["|M*|"][index_freq]) - log10(eip1["|M*|"][index_freq])
        dd = 0.5 / 90.0 * (ei["delta"][index_freq] + eip1["delta"][index_freq])
        push!(dloga, dG / dd)
    end

    loga = zeros(Float64, length(dloga) + 1)
    iref = findfirst(==(Tref), d.list_temp)

    if iref !== nothing
        for i in (iref-1):-1:firstindex(loga)
            loga[i] = loga[i+1] + dloga[i]
        end
        for i in (iref+1):lastindex(loga)
            loga[i] = loga[i-1] - dloga[i-1]
        end
        d.wlf, d.C1, d.C2 = _build_WLF(d, Tref, loga)
    else
        _Tref = d.list_temp[1]
        _loga = zeros(Float64, length(dloga) + 1)
        for i in (firstindex(_loga)+1):lastindex(_loga)
            _loga[i] = _loga[i-1] - dloga[i-1]
        end
        d._wlf, d._C1, d._C2 = _build_WLF(d, _Tref, _loga)
        d.wlf,  d.C1,  d.C2  = change_Tref_WLF(d._C1, d._C2, _Tref, Tref)
        for i in eachindex(d.list_temp)
            loga[i] = d.wlf(d.list_temp[i])
        end
    end
    return loga
end

"""
    build_master_curve(d::DataSeries, field, Tref; index_freq=1)
        -> (ω_reduced, values)

Shift all isothermal sweeps onto a single master curve at `Tref`.

# Arguments
- `d`          — [`DataSeries`](@ref).
- `field`      — Key to extract from each temperature entry, e.g. `"M*"`,
                 `"|M*|"`, `"delta"`.
- `Tref`       — Reference temperature (°C).
- `index_freq` — Frequency index used internally by [`build_shift_factors!`](@ref).

# Returns
`(ω_reduced, values)` — both sorted by reduced angular frequency.
"""
function build_master_curve(d::DataSeries, field::String,
                            Tref::Float64, index_freq::Int=1)
    ωv   = Float64[]
    fv   = Any[]
    loga = build_shift_factors!(d, Tref, index_freq)
    for (iT, T) in enumerate(d.list_temp)
        e  = d[T]
        aT = 10.0^loga[iT]
        append!(ωv, e["omega"] .* aT)
        append!(fv, e[field])
    end
    inds = sortperm(ωv)
    return ωv[inds], fv[inds]
end

# ─────────────────────────────────────────────────────────────────────────────
# Shared objective builder (used by all fit* functions)
# ─────────────────────────────────────────────────────────────────────────────

# _make_J(mc, model_ctor, guard) -> NLopt-compatible objective closure
#
# mc         — (ω_arr, G_arr) from build_master_curve
# model_ctor — function(params...) that returns a callable E*(p)
# guard      — function(X) -> Bool; return true to reject a parameter vector
#              (e.g. enforcing k < h via `X -> X[4] > X[5]`)
function _make_J(mc, model_ctor, guard::Function)
    ω_arr   = mc[1]
    G_arr   = ComplexF64.(mc[2])
    n_calls = Ref(0)
    return function (X::Vector{Float64}, ::Vector{Float64})
        n_calls[] += 1
        print("\rEvaluations: $(n_calls[])")
        guard(X) && return Inf
        try
            model = model_ctor(X...)
            res   = 0.0
            for i in eachindex(ω_arr)
                ω   = ω_arr[i]
                G   = G_arr[i]
                dlo = i > 1 ? log10(ω) - log10(ω_arr[i-1]) :
                              log10(ω_arr[i+1]) - log10(ω)
                res += dlo * abs(1.0 - model(1im * ω) / G)^2
            end
            return res
        catch
            return Inf
        end
    end
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    fit2S2P1D(d, Tref; index_freq=1) -> FitResult2S2P1D

Identify 2S2P1D parameters (E∞, E₀, δ, τ, k, h, β) on the complex master
curve at `Tref` using NLopt `:LN_SBPLX` (up to 100 000 evaluations).

```julia
r = fit2S2P1D(series[1], 10.0)
println(r)
r(2π * 10.0)    # E* at 10 Hz
```
"""
function fit2S2P1D(d::DataSeries, Tref::Float64; index_freq::Int=1)
    mc = build_master_curve(d, "M*", Tref, index_freq)
    println(lpad(" 2S2P1D ", 40, '-') * rpad("", 30, '-'))
    println("Sheet: $(d.name)   Tref = $Tref °C")

    J  = _make_J(mc, Mod2S2P1D, X -> X[5] > X[6])
    p0 = [minimum(abs.(ComplexF64.(mc[2]))), maximum(abs.(ComplexF64.(mc[2]))),
          2.8, 2e-2, 0.2, 0.6, 1e3]
    lb = [0.0,  1e-6, 1e-6, 1e-6, 0.1, 0.1, 1e-6]
    ub = [1e6,  1e6,  1e6,  1e6,  1.0, 1.0, Inf]

    opt = Opt(:LN_SBPLX, length(p0))
    lower_bounds!(opt, lb);  upper_bounds!(opt, ub)
    min_objective!(opt, J);  ftol_rel!(opt, 1e-15)
    xtol_rel!(opt, 1e-15);   maxeval!(opt, 100_000)

    minf, X, _ = NLopt.optimize(opt, p0)
    println("\nDone — residual = $minf")
    println("-"^70)

    return FitResult2S2P1D(X[1], X[2], X[3], X[4], X[5], X[6], X[7],
                           minf, Mod2S2P1D(X...))
end

"""
    fit1S2P1D(d, Tref; index_freq=1) -> FitResult1S2P1D

Identify 1S2P1D parameters (E₀, δ, τ, k, h, β) on the complex master curve
at `Tref` using NLopt `:LN_NELDERMEAD` (up to 500 000 evaluations).

The 1S2P1D model has no glassy branch (E∞ is implicit):
`E*(p) = E₀ / (1 + δ(pτ)^{-k} + (pτ)^{-h} + 1/(pβτ))`

```julia
r = fit1S2P1D(series[1], 10.0)
println(r)
```
"""
function fit1S2P1D(d::DataSeries, Tref::Float64; index_freq::Int=1)
    mc = build_master_curve(d, "M*", Tref, index_freq)
    println(lpad(" 1S2P1D ", 40, '-') * rpad("", 30, '-'))
    println("Sheet: $(d.name)   Tref = $Tref °C")

    J  = _make_J(mc, Mod1S2P1D, X -> X[4] > X[5])
    p0 = [maximum(abs.(ComplexF64.(mc[2]))), 2.8, 2e-2, 0.2, 0.6, 1e3]
    lb = [1e-6, 1e-6, 1e-6, 0.1, 0.1, 1e-6]
    ub = [1e6,  1e6,  1e6,  1.0, 1.0, Inf]

    opt = Opt(:LN_NELDERMEAD, length(p0))
    lower_bounds!(opt, lb);  upper_bounds!(opt, ub)
    min_objective!(opt, J);  ftol_rel!(opt, 1e-15)
    xtol_rel!(opt, 1e-15);   maxeval!(opt, 500_000)

    minf, X, _ = NLopt.optimize(opt, p0)
    println("\nDone — residual = $minf")
    println("-"^70)

    return FitResult1S2P1D(X[1], X[2], X[3], X[4], X[5], X[6],
                           minf, Mod1S2P1D(X...))
end

"""
    fitHS(d, Tref; index_freq=1) -> FitResultHS

Identify Huet-Sayegh parameters (E∞, E₀, δ, τ, k, h) on the complex master
curve at `Tref` using NLopt `:LN_NELDERMEAD` (up to 500 000 evaluations).

The Huet-Sayegh model has no dashpot (β → ∞):
`E*(p) = E∞ + (E₀ - E∞) / (1 + δ(pτ)^{-k} + (pτ)^{-h})`

```julia
r = fitHS(series[1], 10.0)
println(r)
```
"""
function fitHS(d::DataSeries, Tref::Float64; index_freq::Int=1)
    mc = build_master_curve(d, "M*", Tref, index_freq)
    println(lpad(" Huet-Sayegh ", 40, '-') * rpad("", 30, '-'))
    println("Sheet: $(d.name)   Tref = $Tref °C")

    J  = _make_J(mc, ModHS, X -> X[5] > X[6])
    G  = abs.(ComplexF64.(mc[2]))
    p0 = [minimum(G), maximum(G), 2.8, 2e-2, 0.2, 0.6]
    lb = [0.0, 1e-6, 1e-6, 1e-6, 0.1, 0.1]
    ub = [1e6, 1e6,  1e6,  1e6,  1.0, 1.0]

    opt = Opt(:LN_NELDERMEAD, length(p0))
    lower_bounds!(opt, lb);  upper_bounds!(opt, ub)
    min_objective!(opt, J);  ftol_rel!(opt, 1e-15)
    xtol_rel!(opt, 1e-15);   maxeval!(opt, 500_000)

    minf, X, _ = NLopt.optimize(opt, p0)
    println("\nDone — residual = $minf")
    println("-"^70)

    return FitResultHS(X[1], X[2], X[3], X[4], X[5], X[6],
                       minf, ModHS(X...))
end

# ─────────────────────────────────────────────────────────────────────────────
# Helpers used by the plotting layer
# ─────────────────────────────────────────────────────────────────────────────

"""
    eval_model(model_func, ω; rtd=180/π) -> (re, im, absval, deg)

Evaluate a complex-modulus function at each frequency in `ω` (rad/s) and
return real part, imaginary part, magnitude, and phase in degrees.
"""
function eval_model(model_func, ω::AbstractVector; rtd::Float64=180.0/π)
    zs = [ComplexF64(model_func(ωᵢ * 1im)) for ωᵢ in ω]
    return real.(zs), imag.(zs), abs.(zs), angle.(zs) .* rtd
end

"""
    eval_array(G_arr; rtd=180/π) -> (re, im, absval, deg)

Decompose a pre-computed vector of complex modulus values into real, imaginary,
magnitude, and phase (degrees).
"""
function eval_array(G_arr::AbstractVector; rtd::Float64=180.0/π)
    zs = ComplexF64.(G_arr)
    return real.(zs), imag.(zs), abs.(zs), angle.(zs) .* rtd
end
