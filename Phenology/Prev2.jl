include("../AR/utils/utils.jl")
include("vba/Action2.jl")
include("table_reader.jl")

# Weather variables
#* necessaire?
# Abstract type for Temperature Codes
abstract type AbstractWeatherTemperature end
abstract type AbstracTemperature <: AbstractWeatherTemperature end

# Struct for parameters used in the chilling and forcing model calculations
struct ModelParams{TT<:AbstracTemperature,AC<:AbstractAction,F<:Real}
    do_chilling::Bool
    chilling_temp::TT
    chilling_model::AC
    CPO::F #Jour d'entrée en dormance (Chilling period onset)
    chilling_threshold::F
    chilling_scale::F
    chilling_target::F
    forcing_temp::TT
    forcing_model::AC
    # JLD::F #Jour de levée de dormance -> Output
    forcing_threshold::F
    forcing_scale::F
    forcing_limits::Vector{F} # ?
end

# Concrete types for temperature codes
mutable struct TN <: AbstracTemperature
    df::DataFrame
end
mutable struct TG <: AbstracTemperature
    df::DataFrame
end
mutable struct TX <: AbstracTemperature
    df::DataFrame
end

initTN(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TN(DataFrame(Dict(:DATE => date_vec, :TN => x)))
initTN(df::DataFrame) = TN(df[:, [:DATE, :TN]])
initTN(file::String) = initTN(truncate_MV(extract_series(file, plot=false), "TN"))

initTG(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TG(DataFrame(Dict(:DATE => date_vec, :TG => x)))
initTG(df::DataFrame) = TG(df[:, [:DATE, :TG]])
initTG(file::String) = initTG(truncate_MV(extract_series(file, plot=false), "TG"))

initTX(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TX(DataFrame(Dict(:DATE => date_vec, :TX => x)))
initTX(df::DataFrame) = TX(df[:, [:DATE, :TX]])
initTX(file::String) = initTX(truncate_MV(extract_series(file, plot=false), "TX"))
