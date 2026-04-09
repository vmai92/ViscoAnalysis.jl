# ─────────────────────────────────────────────────────────────────────────────
# ViscoAnalysis — quickstart example
#
# Workflow:
#   1. Load experimental data from an Excel file
#   2. Generate all diagnostic plots
#   3. Fit one or more rheological models on the master curve
#   4. Save model results and overlay plots
#
# Run from the ViscoAnalysis/ directory:
#   julia --project=. examples/quickstart.jl
# ─────────────────────────────────────────────────────────────────────────────

using ViscoAnalysis

# ── 1. Configuration ──────────────────────────────────────────────────────────

# Path to your Excel file (columns: T [°C], f [Hz], |E*| [MPa], φ [°])
DATAFILE = joinpath(@__DIR__, "..", "..", "EBR_T0_T10_Ep2_test.xlsx")

# Output directory for figures (created automatically)
OUTDIR   = joinpath(@__DIR__, "..", "..", "results_quickstart")

# Reference temperature for the master curve [°C]
TREF     = 10.0

# Modulus unit flag: true = MPa (no conversion), false = Pa (÷ 10⁶)
USE_MPA  = true

# Choose which model(s) to fit:
#   :fit2S2P1D   — 2 Springs 2 Parabolic 1 Dashpot  (7 parameters)
#   :fit1S2P1D   — 1 Spring  2 Parabolic 1 Dashpot  (6 parameters, no E∞)
#   :fitHS       — Huet-Sayegh                       (6 parameters, no dashpot)
MODEL = :fit2S2P1D

# ── 2. Load data ──────────────────────────────────────────────────────────────

println("Loading data from: $DATAFILE")
series = load_data(DATAFILE; MPa=USE_MPA)

println("Loaded $(length(series)) sheet(s):")
for (i, d) in enumerate(series)
    println("  [$i] $(d.name)  — $(length(d.list_temp)) temperatures, ",
            "$(length(d.list_omega)) frequencies")
end

# ── 3. Diagnostic plots ───────────────────────────────────────────────────────

println("\nGenerating diagnostic plots → $OUTDIR")
mkpath(OUTDIR)
plot_all(series, OUTDIR; Tref=TREF)

# ── 4. Model identification ───────────────────────────────────────────────────

println("\nFitting model [$MODEL] at Tref = $TREF °C …")

fit_func = if MODEL === :fit2S2P1D
    fit2S2P1D
elseif MODEL === :fit1S2P1D
    fit1S2P1D
elseif MODEL === :fitHS
    fitHS
else
    error("Unknown model: $MODEL. Choose :fit2S2P1D, :fit1S2P1D, or :fitHS")
end

fit_results = [fit_func(d, TREF) for d in series]

# Display fitted parameters
for (d, r) in zip(series, fit_results)
    println("\n── Sheet: $(d.name) ──")
    println(r)
end

# ── 5. Model overlay plot ─────────────────────────────────────────────────────

println("\nSaving model-fit plot → $OUTDIR")
plot_model_fit(series, fit_results, OUTDIR; Tref=TREF)

println("\nDone. All figures saved in: $OUTDIR")

# ── 6. Compare multiple models on the same sheet ─────────────────────────────
#
# To compare all three models on series[1]:
#
#   d = series[1]
#   r_2s2p1d = fit2S2P1D(d, TREF)
#   r_1s2p1d = fit1S2P1D(d, TREF)
#   r_hs     = fitHS(d, TREF)
#
#   println(r_2s2p1d)
#   println(r_1s2p1d)
#   println(r_hs)
#
#   # Each model gets its own overlay plot (filename reflects the model name)
#   plot_model_fit([d], [r_2s2p1d], OUTDIR; Tref=TREF)
#   plot_model_fit([d], [r_1s2p1d], OUTDIR; Tref=TREF)
#   plot_model_fit([d], [r_hs],     OUTDIR; Tref=TREF)

# ── 7. Evaluate the fitted model at specific frequencies ─────────────────────
#
#   r = fit_results[1]
#   ω = 2π * 10.0          # 10 Hz → rad/s at Tref
#   E_star = r(ω)
#   @show abs(E_star)               # |E*|  [MPa]
#   @show angle(E_star) * 180/π    # φ     [°]
#
# Access WLF coefficients:
#   d = series[1]
#   build_shift_factors!(d, TREF)
#   println("C1 = $(d.C1),  C2 = $(d.C2)")
#   log_aT = d.wlf(25.0)            # log₁₀(aT) at 25 °C
