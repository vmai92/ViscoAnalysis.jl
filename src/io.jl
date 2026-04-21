# ─────────────────────────────────────────────────────────────────────────────
# Excel I/O — read complex-modulus data from .xlsx files
# ─────────────────────────────────────────────────────────────────────────────

"""
    load_data(filename; MPa=false, Iso=false) -> Vector{DataSeries}

Read all sheets of an Excel workbook and return one [`DataSeries`](@ref) per
sheet.

# Arguments
- `filename` — Path to the `.xlsx` file.
- `MPa`      — Set `true` if the modulus column is already in MPa; otherwise
               values are assumed to be in Pa and converted (÷ 10⁶).
- `Iso`      — Set `true` for an isochrone layout where rows are indexed by
               frequency instead of temperature.

# Excel format expected
| Column 1    | Column 2    | Column 3        | Column 4       |
|-------------|-------------|-----------------|----------------|
| T (°C)      | f (Hz)      | E* norm (Pa/MPa)   | φ (degrees) |

All sheets in the workbook must share the same layout.

# Example
```julia
using ViscoAnalysis
series = load_data("EBR_T0_T10.xlsx"; MPa=true)
series[1]          # first sheet
series[1].list_temp   # available temperatures
```
"""
function load_data(filename::String; MPa::Bool=false, Iso::Bool=false)::Vector{DataSeries}
    sheetnames = XLSX.sheetnames(XLSX.readxlsx(filename))
    return [_parse_sheet(filename, i - 1, MPa, Iso) for i in eachindex(sheetnames)]
end

# ─────────────────────────────────────────────────────────────────────────────
# Internal: parse one sheet (0-indexed sheet number)
# ─────────────────────────────────────────────────────────────────────────────
function _parse_sheet(filename::String, sheet::Int,
                      MPa::Bool, Iso::Bool)::DataSeries

    coefPa  = MPa ? 1.0 : 1.0e-6
    dtr     = π / 180.0

    xf       = XLSX.readxlsx(filename)
    snames   = XLSX.sheetnames(xf)
    sname    = snames[sheet + 1]
    nb_sheet = length(snames)

    raw   = XLSX.readtable(filename, sname)
    df    = DataFrame(raw)
    nrows = nrow(df)

    _f(v) = Float64(coalesce(v, NaN))
    data  = Dict{Float64, Dict{String, Any}}()
    row   = 1

    if Iso
        while row ≤ nrows
            fv = _f(df[row, 2])
            if !haskey(data, fv)
                mask = [_f(df[i, 2]) == fv for i in 1:nrows]
                e = Dict{String, Any}()
                e["T"]     = _f.(df[mask, 1])
                e["|M*|"]  = _f.(df[mask, 3]) .* coefPa
                e["delta"] = _f.(df[mask, 4])
                δr = e["delta"] .* dtr
                e["M*"]    = e["|M*|"] .* exp.(1im .* δr)
                e["M*_1"]  = e["|M*|"] .* cos.(δr)
                e["M*_2"]  = e["|M*|"] .* sin.(δr)
                data[fv]   = e
            else
                break
            end
            row += 1
        end
        lf = sort(collect(keys(data)))
        lt = sort(data[lf[1]]["T"])
        return DataSeries(data, MPa, Iso, sname, nb_sheet,
                          lt, Float64[], lf,
                          nothing, 0.0, 0.0, nothing, 0.0, 0.0)
    else
        while row ≤ nrows
            tv = _f(df[row, 1])
            if !haskey(data, tv)
                mask = [_f(df[i, 1]) == tv for i in 1:nrows]
                e  = Dict{String, Any}()
                fv = _f.(df[mask, 2])
                e["f"]     = fv
                e["omega"] = fv .* (2π)
                e["|M*|"]  = _f.(df[mask, 3]) .* coefPa
                e["delta"] = _f.(df[mask, 4])
                δr = e["delta"] .* dtr
                e["M*"]    = e["|M*|"] .* exp.(1im .* δr)
                e["M*_1"]  = e["|M*|"] .* cos.(δr)
                e["M*_2"]  = e["|M*|"] .* sin.(δr)
                data[tv]   = e
                row += length(fv)
            else
                row += length(data[tv]["f"])
            end
        end
        lt = sort(collect(keys(data)))
        lo = sort(data[lt[1]]["omega"])
        return DataSeries(data, MPa, Iso, sname, nb_sheet,
                          lt, lo, lo,
                          nothing, 0.0, 0.0, nothing, 0.0, 0.0)
    end
end

# ─────────────────────────────────────────────────────────────────────────────

"""
    save_fitting_results(series, results, Tref, outdir)

Export fitting parameters to an Excel file `parametres_fitting.xlsx` in `outdir`.

Each row corresponds to one `DataSeries` / `FitResult` pair.
Columns are automatically adapted to the model type (2S2P1D, 1S2P1D, Huet-Sayegh).

# Arguments
- `series`  — `Vector{DataSeries}` used for fitting (sheet names become row labels).
- `results` — `Vector{<:AbstractFitResult}` returned by `fit2S2P1D`, `fit1S2P1D`, or `fitHS`.
- `Tref`    — Reference temperature used during fitting [°C].
- `outdir`  — Output directory (must exist).

# Example
```julia
results = [fit2S2P1D(d, 10.0) for d in series]
save_fitting_results(series, results, 10.0, "results/")
```
"""
function save_fitting_results(series::Vector{DataSeries},
                               results::Vector{<:AbstractFitResult},
                               Tref::Float64, outdir::String)

    _param_headers(::FitResult2S2P1D) = ["E∞ [MPa]", "E₀ [MPa]", "δ", "τ_E [s]", "k", "h", "β"]
    _param_headers(::FitResult1S2P1D) = ["E₀ [MPa]", "δ", "τ_E [s]", "k", "h", "β"]
    _param_headers(::FitResultHS)     = ["E∞ [MPa]", "E₀ [MPa]", "δ", "τ_E [s]", "k", "h"]

    _param_values(r::FitResult2S2P1D) = [r.Einf, r.E0, r.delta, r.tauE, r.k, r.h, r.beta]
    _param_values(r::FitResult1S2P1D) = [r.E0,   r.delta, r.tauE, r.k, r.h, r.beta]
    _param_values(r::FitResultHS)     = [r.Einf, r.E0, r.delta, r.tauE, r.k, r.h]

    excel_path = joinpath(outdir, "parametres_fitting.xlsx")
    XLSX.openxlsx(excel_path, mode="w") do xf
        sheet = xf[1]
        XLSX.rename!(sheet, "Fitting Results")

        param_hdrs = _param_headers(results[1])
        headers    = vcat(["Echantillon", "Modèle", "Tref (°C)"], param_hdrs, ["Résidu"])
        for (j, h) in enumerate(headers)
            sheet[1, j] = h
        end

        for (i, (d, r)) in enumerate(zip(series, results))
            sheet[i+1, 1] = d.name
            sheet[i+1, 2] = model_name(r)
            sheet[i+1, 3] = Tref
            for (j, v) in enumerate(_param_values(r))
                sheet[i+1, 3+j] = v
            end
            sheet[i+1, 3 + length(_param_values(r)) + 1] = r.residual
        end
    end

    println("Fitting results saved → $excel_path")
end
