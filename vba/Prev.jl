# Struct for parameters used in the chilling and forcing model calculations
struct ModelParams{TT<:AbstracTemperature, AC<:AbstractAction, F<:Real}
    do_chilling::Bool
    chilling_temp::TT
    chilling_model::AC
    JED::F
    chilling_threshold::F
    chilling_scale::F
    chilling_target::F
    forcing_temp::TT
    forcing_model::AC
    JLD::F
    forcing_threshold::F
    forcing_scale::F
    forcing_limits::Vector{F}
end

# Weather variables
#* necessaire?
# Abstract type for Temperature Codes
abstract type AbstractWeatherTemperature end
abstract type AbstracTemperature <: AbstractWeatherTemperature end

# Concrete types for temperature codes
struct TN <: AbstracTemperature end
struct TG <: AbstracTemperature end
struct TX <: AbstracTemperature end