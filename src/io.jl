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
