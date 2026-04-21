# ─────────────────────────────────────────────────────────────────────────────
# Plotting functions
# All public functions accept Vector{DataSeries} and an output directory.
# Figures are saved as both PDF and PNG via _save_fig.
# ─────────────────────────────────────────────────────────────────────────────

# Matplotlib-compatible 10-colour palette
const _COLORS10 = ["#1f77b4","#ff7f0e","#2ca02c","#d62728","#9467bd",
                   "#8c564b","#e377c2","#7f7f7f","#bcbd22","#17becf"]
_couleur(n) = repeat(_COLORS10, ceil(Int, n / 10))[1:n]

# Suppress "No strict ticks found" warnings from PlotUtils (cosmetic, data-
# range-dependent: fires when a log axis spans less than one decade).
struct _SuppressPlotUtilsTicks <: AbstractLogger
    inner::AbstractLogger
end
Logging.min_enabled_level(l::_SuppressPlotUtilsTicks) =
    Logging.min_enabled_level(l.inner)
Logging.shouldlog(l::_SuppressPlotUtilsTicks, level, _mod, group, id) =
    Logging.shouldlog(l.inner, level, _mod, group, id)
Logging.catch_exceptions(l::_SuppressPlotUtilsTicks) =
    Logging.catch_exceptions(l.inner)
function Logging.handle_message(l::_SuppressPlotUtilsTicks,
                                 level, msg, _module, group, id, file, line;
                                 kwargs...)
    contains(string(msg), "No strict ticks found") && return
    Logging.handle_message(l.inner, level, msg, _module, group, id,
                            file, line; kwargs...)
end

function _save_fig(fig, dir::String, stem::String)
    Logging.with_logger(_SuppressPlotUtilsTicks(Logging.global_logger())) do
        savefig(fig, joinpath(dir, "$stem.pdf"))
        savefig(fig, joinpath(dir, "$stem.png"))
        display(fig)
    end
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    plot_isothermes(series, outdir)

Isotherm curves: |E*| and φ vs frequency f [Hz], one curve per temperature.
Saves `isothermes.pdf/.png` in `outdir`.
"""
function plot_isothermes(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom   = d.name
        clist = _couleur(length(d.list_temp))
        fig   = plot(layout=(1,2), size=(1200,500),
                     plot_title="Isotherm curves",
                     plot_titlefontsize=16,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=5)

        for (ic, T) in enumerate(d.list_temp)
            e   = d[T]
            c   = clist[ic]
            lbl = "T = $(round(Int, T)) °C"
            plot!(fig, e["f"], e["|M*|"]; subplot=1,
                  xscale=:log10, yscale=:log10,
                  markershape=:circle, ms=5, mc=:white, msc=c, msw=1.5,
                  lw=1.2, lc=c, label=lbl)
            plot!(fig, e["f"], e["delta"]; subplot=2,
                  xscale=:log10,
                  markershape=:circle, ms=5, mc=:white, msc=c, msw=1.5,
                  lw=1.2, lc=c, label=lbl)
        end

        plot!(fig; subplot=1,
              xlabel="f [Hz]", ylabel=L"|E^*|\;[\mathrm{MPa}]",
              title=L"|E^*|\;\mathrm{vs}\;f", grid=true, legend=:bottomright)
        plot!(fig; subplot=2,
              xlabel="f [Hz]", ylabel=L"\varphi\;[°]",
              title=L"\varphi\;\mathrm{vs}\;f", grid=true, legend=:topright)

        _save_fig(fig, outdir, "Isotherm curves")
    end
end

"""
    plot_isochrones(series, outdir)

Isochrone curves: |E*| and φ vs temperature T [°C], one curve per frequency.
Saves `isochrones.pdf/.png` in `outdir`.
"""
function plot_isochrones(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom          = d.name
        list_freq_hz = sort(d[d.list_temp[1]]["f"])
        clist        = _couleur(length(list_freq_hz))
        fig          = plot(layout=(1,2), size=(1200,500),
                            plot_title="Isochrone curves",
                            plot_titlefontsize=16,
                            bottom_margin=10Plots.mm, left_margin=8Plots.mm)

        for (ic, f_hz) in enumerate(list_freq_hz)
            T_vals   = d.list_temp
            E_vals   = [d[T]["|M*|"][argmin(abs.(d[T]["f"] .- f_hz))] for T in T_vals]
            phi_vals = [d[T]["delta"][argmin(abs.(d[T]["f"] .- f_hz))] for T in T_vals]
            c        = clist[ic]

            plot!(fig, T_vals, E_vals; subplot=1,
                  yscale=:log10, markershape=:circle, ms=5,
                  mc=:white, msc=c, msw=1.5, lw=1.2, lc=c, label="f = $f_hz Hz")
            plot!(fig, T_vals, phi_vals; subplot=2,
                  markershape=:circle, ms=5,
                  mc=:white, msc=c, msw=1.5, lw=1.2, lc=c, label="f = $f_hz Hz")
        end

        plot!(fig; subplot=1,
              xlabel="T [°C]", ylabel=L"|E^*|\;[\mathrm{MPa}]",
              title=L"|E^*|\;\mathrm{vs}\;T", grid=true, legend=:topright)
        plot!(fig; subplot=2,
              xlabel="T [°C]", ylabel=L"\varphi\;[°]",
              title=L"\varphi\;\mathrm{vs}\;T", grid=true, legend=:topleft)

        _save_fig(fig, outdir, "Isochrone curves")
    end
end

"""
    plot_cole_cole(series, outdir)

Cole-Cole diagram: E₂ (imaginary) vs E₁ (real) on log-log axes,
one scatter series per temperature.
Saves `Cole-Cole.pdf/.png` in `outdir`.
"""
function plot_cole_cole(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom   = d.name
        clist = _couleur(length(d.list_temp))
        nT    = length(d.list_temp)
        ncol  = nT > 8 ? 2 : 1
        fig   = plot(size=(900, 750),
                     plot_title="Cole-Cole diagram",
                     plot_titlefontsize=14,
                     legend_column=ncol,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=7)

        for (ic, T) in enumerate(d.list_temp)
            e    = d[T]
            mask = (e["M*_1"] .> 0) .& (e["M*_2"] .> 0)
            any(mask) || continue
            scatter!(fig, e["M*_1"][mask], e["M*_2"][mask];
                     xscale=:log10, yscale=:log10,
                     ms=6, mc=:white, msc=clist[ic], msw=1.5,
                     label="T = $(round(Int, T)) °C")
        end

        plot!(fig, xlabel=L"E_1\;[\mathrm{MPa}]",
              ylabel=L"E_2\;[\mathrm{MPa}]", grid=true, legend=:topright)
        _save_fig(fig, outdir, "Cole-Cole diagram")
    end
end

"""
    plot_black(series, outdir)

Black diagram: |E*| vs φ on a semi-log axis, one scatter series per temperature.
Saves `Black.pdf/.png` in `outdir`.
"""
function plot_black(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom   = d.name
        nT    = length(d.list_temp)
        clist = _couleur(nT)
        # Largeur adaptée : plus de colonnes dans la légende si beaucoup de températures
        ncol  = nT > 8 ? 2 : 1
        fig   = plot(size=(900, 750),
                     plot_title="Black diagram",
                     plot_titlefontsize=14,
                     legend_column=ncol,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=7)

        for (ic, T) in enumerate(d.list_temp)
            e = d[T]
            scatter!(fig, e["delta"], e["|M*|"];
                     yscale=:log10, ms=6, mc=:white, msc=clist[ic], msw=1.5,
                     label="T = $(round(Int, T)) °C")
        end

        plot!(fig,
              xlabel=L"\varphi\;[°]",
              ylabel=L"|E^*|\;[\mathrm{MPa}]",
              grid=true, legend=:topright)
        _save_fig(fig, outdir, "Black diagram")
    end
end

"""
    plot_kramers_kronig(series, outdir)

Kramers-Kronig verification: d log|E*|/d logω vs δ/90.
A perfect material follows the identity line y = x.
Saves `Kramers-Kronig.pdf/.png` in `outdir`.
"""
function plot_kramers_kronig(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom   = d.name
        build_Kramers_Kronig!(d)   
        nT    = length(d.list_temp)
        clist = _couleur(nT)
        ncol  = nT > 8 ? 2 : 1
        fig   = plot(size=(900, 750),
                     plot_title="Kramers-Kronig Verification",
                     plot_titlefontsize=14,
                     legend_column=ncol,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=7)

        for (ic, T) in enumerate(d.list_temp)
            e = d[T]
            isempty(e["delta/90"]) && continue   
            scatter!(fig, e["delta/90"], e["dlog|M*|/dlogomega"];
                     ms=6, mc=:white, msc=clist[ic], msw=1.5,
                     label="T = $(round(Int, T)) °C")
        end

        plot!(fig, [0.0, 1.0], [0.0, 1.0];
              lw=1.5, lc=:black, label="y = x (référence)")
        plot!(fig, xlabel=L"\delta\;/\;90",
              ylabel=L"\mathrm{d}\log|E^*|\;/\;\mathrm{d}\log\omega",
              grid=true, legend=:topleft)
        _save_fig(fig, outdir, "Kramers-Kronig verification")
    end
end

"""
    plot_wlf(series, outdir)

Shift factors log(aT) vs T with WLF curve, iterated over all reference
temperatures.
Saves `WLF.pdf/.png` in `outdir`.
"""
function plot_wlf(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom   = d.name
        lT    = range(d.list_temp[1], d.list_temp[end], length=100)
        nT    = max(length(d.list_temp) - 1, 1)
        clist = _couleur(nT)
        ncol  = nT > 8 ? 2 : 1
        fig   = plot(size=(900, 750),
                     plot_title="Shift factors calculation",
                     plot_titlefontsize=14,
                     legend_column=ncol,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=7)

        for (ic, Tref) in enumerate(d.list_temp[2:end])
            loga = build_shift_factors!(d, Float64(Tref), 1)
            c    = clist[ic]
            scatter!(fig, d.list_temp, loga;
                     ms=5, mc=:white, msc=c, msw=1.5,
                     label="T_ref = $Tref °C")
            plot!(fig, collect(lT), d.wlf.(collect(lT));
                  lw=1.5, lc=c,
                  label="WLF C1=$(round(d.C1,digits=1)) C2=$(round(d.C2,digits=1))")
        end

        plot!(fig, xlabel="T (°C)",
              ylabel=L"\log(a_{T,T_{\mathrm{ref}}})", grid=true, legend=:topright)
        _save_fig(fig, outdir, "Shift factors calculation")
    end
end

"""
    plot_wlf_stability(series, outdir)

WLF stability plot: shift factors and WLF curves for all reference temperatures
(tested values and intermediate midpoints), showing robustness of the WLF fit.
Saves `WLF_stability_<sheetname>.pdf/.png` in `outdir`.
"""
function plot_wlf_stability(series::Vector{DataSeries}, outdir::String)
    for d in series
        nom  = d.name
        lT   = range(d.list_temp[1], d.list_temp[end], length=100)
        lT_v = collect(lT)

        _Tref = d.list_temp[1]
        build_shift_factors!(d, _Tref, 1)
        _C1, _C2 = d.C1, d.C2

        nT    = length(d.list_temp)
        clist = _couleur(nT)
        ncol  = nT > 8 ? 2 : 1
        fig   = plot(size=(900, 750),
                     plot_title="WLF multiple Trefs",
                     plot_titlefontsize=14,
                     legend_column=ncol,
                     bottom_margin=10Plots.mm, left_margin=8Plots.mm,
                     legendfontsize=7)

        for (ic, Tref) in enumerate(d.list_temp)
            loga = build_shift_factors!(d, Float64(Tref), 1)
            scatter!(fig, d.list_temp, loga;
                     ms=5, mc=:white, msc=clist[ic], msw=1.5,
                     label="T_ref = $Tref °C")

            wlf_f, _, _ = change_Tref_WLF(_C1, _C2, _Tref, Float64(Tref))
            plot!(fig, lT_v, wlf_f.(lT_v); lw=1.2, lc=:black, label="")

            if ic > 1
                tref_mid      = 0.5*(Tref + d.list_temp[ic-1])
                wlf_mid, _, _ = change_Tref_WLF(_C1, _C2, _Tref, tref_mid)
                plot!(fig, lT_v, wlf_mid.(lT_v); lw=1.0, lc=:black, ls=:dash, label="")
            end
        end

        plot!(fig, [NaN], [NaN]; lw=1.2, lc=:black,           label="WLF (Test Tref)")
        plot!(fig, [NaN], [NaN]; lw=1.0, lc=:black, ls=:dash, label="WLF (Intermediate Tref)")

        plot!(fig, xlabel="T (°C)",
              ylabel=L"\log(a_{T,T_{\mathrm{ref}}})", grid=true, legend=:topright)
        _save_fig(fig, outdir, "WLF multiple Trefs")
    end
end

"""
    plot_model_fit(series, fit_results, outdir; Tref=10.0, ind_freq=1)

Master curve with model overlay: |E*| and φ vs reduced angular frequency ωaT.
Works with any [`AbstractFitResult`](@ref) (2S2P1D, 1S2P1D, Huet-Sayegh, …).
Saves `Results_<model>_Tref<T>.pdf/.png` in `outdir`.

# Arguments
- `series`      — Vector of [`DataSeries`](@ref).
- `fit_results` — Vector of [`AbstractFitResult`](@ref), one per series entry.
- `outdir`      — Output directory.
- `Tref`        — Reference temperature used when building the master curves.
"""
function plot_model_fit(series::Vector{DataSeries},
                        fit_results::Vector{<:AbstractFitResult},
                        outdir::String;
                        Tref::Float64 = 10.0,
                        ind_freq::Int = 1)

    clist  = _couleur(length(series))
    fig   = plot(layout=(1,2), size=(1200,500),
                 bottom_margin=10Plots.mm, left_margin=8Plots.mm)
    mnames = unique(model_name.(fit_results))
    mlabel = length(mnames) == 1 ? mnames[1] : join(mnames, "/")

    for (isheet, (d, result)) in enumerate(zip(series, fit_results))
        nom    = d.name
        ω, G   = build_master_curve(d, "M*", Tref, ind_freq)
        G_cplx = ComplexF64.(G)

        _, _, Eᵢ, ϕᵢ = eval_array(G_cplx)
        c = clist[isheet]

        scatter!(fig, ω, Eᵢ; subplot=1,
                 xscale=:log10, yscale=:log10,
                 ms=3, mc=:white, msc=c, msw=1.5, label="$nom — exp")
        scatter!(fig, ω, ϕᵢ; subplot=2,
                 xscale=:log10,
                 ms=3, mc=:white, msc=c, msw=1.5, label="")

        ω_fit = exp10.(range(log10(minimum(ω)) * 1.25,
                             log10(maximum(ω)) * 1.25, length=200))
        _, _, Ef, ϕf = eval_model(result.model, ω_fit)

        plot!(fig, ω_fit, Ef; subplot=1,
              xscale=:log10, yscale=:log10,
              lw=2, lc=c, label="$nom — $(model_name(result))")
        plot!(fig, ω_fit, ϕf; subplot=2,
              xscale=:log10, lw=2, lc=c, label="")
    end

    plot!(fig; subplot=1,
          xlabel=L"\omega a_T \;[\mathrm{rad\cdot s}^{-1}]",
          ylabel=L"|E^*|\;[\mathrm{MPa}]", grid=true, legend=:bottomright)
    plot!(fig; subplot=2,
          xlabel=L"\omega a_T \;[\mathrm{rad\cdot s}^{-1}]",
          ylabel=L"\phi\;[°]", grid=true, legend=:bottomright)

    _save_fig(fig, outdir, "Results_$(mlabel)_Tref$(round(Int, Tref))")
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    plot_all(series, outdir; Tref=10.0, ind_freq=1)

Convenience wrapper that runs every diagnostic plot in sequence.
Does **not** run the model identification; call [`fit2S2P1D`](@ref) separately
and pass the results to [`plot_model_fit`](@ref).

Plots produced (one file per sheet unless noted):
- Isothermal curves
- Isochrone curves
- Cole-Cole diagram
- Black diagram
- Kramers-Kronig verification
- WLF shift factors
- WLF stability
"""
function plot_all(series::Vector{DataSeries}, outdir::String;
                  Tref::Float64 = 10.0, ind_freq::Int = 1)
    mkpath(outdir)
    plot_isothermes(series, outdir)
    plot_isochrones(series, outdir)
    plot_cole_cole(series, outdir)
    plot_black(series, outdir)
    plot_kramers_kronig(series, outdir)
    plot_wlf(series, outdir)
    plot_wlf_stability(series, outdir)
end
