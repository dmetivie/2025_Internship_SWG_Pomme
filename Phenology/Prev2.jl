include("../AR/utils/utils.jl")
include("vba/Action2.jl")
include("table_reader.jl")

# Weather variables
#* necessaire?
# Abstract type for Temperature Codes
abstract type AbstractWeatherTemperature end
abstract type AbstracTemperature <: AbstractWeatherTemperature end

# Struct for parameters used in the chilling and forcing model calculations
# struct ModelParams{TT<:AbstracTemperature,AC<:AbstractAction,F<:Real}
#     do_chilling::Bool
#     chilling_temp::TT
#     chilling_model::AC
#     CPO::F #Jour d'entrée en dormance (Chilling period onset)
#     chilling_threshold::F
#     chilling_scale::F
#     chilling_target::F
#     forcing_temp::TT
#     forcing_model::AC
#     # JLD::F #Jour de levée de dormance -> Output
#     forcing_threshold::F
#     forcing_scale::F
#     forcing_limits::Vector{F} # ?
# end

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


mutable struct VinePhenoModel
    TN_vec::AbstractVector{<:Real}
    TX_vec::AbstractVector{<:Real}
    DATE::AbstractVector{Date}
    CPO::Tuple{<:Integer,<:Integer}
    Q10::AbstractFloat
    Cc::AbstractFloat
    T0Bc::AbstractFloat
    TMBc::AbstractFloat
    Ghc::AbstractFloat
end

function InitVinePhenoModel(
    TN_vec::AbstractVector{<:Real},
    TX_vec::AbstractVector{<:Real},
    DATE::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.
)
    return VinePhenoModel(TN_vec,TX_vec,DATE,CPO,Q10,Cc,T0Bc,TMBc,Ghc)
end




function InitVinePhenoModel(
    file_TN::String,
    file_TX::String;
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.
)   
    TNdf = truncate_MV(extract_series(file_TN))
    TXdf = truncate_MV(extract_series(file_TX))
    if TNdf.DATE != TXdf.DATE
        date_vec = max(TNdf.DATE[1],TXdf.DATE[1]):min(TNdf.DATE[end],TXdf.DATE[end])
        TN_vec = TNdf.TN[findfirst(TNdf.DATE .== date_vec[1]):findfirst(TNdf.DATE .== date_vec[end])]
        TX_vec = TXdf.TX[findfirst(TXdf.DATE .== date_vec[1]):findfirst(TXdf.DATE .== date_vec[end])]
        return VinePhenoModel(TN_vec,TX_vec,date_vec,CPO,Q10,Cc,T0Bc,TMBc,Ghc)
    else
        return VinePhenoModel(TNdf.TN,TXdf.TX,TNdf.DATE,CPO,Q10,Cc,T0Bc,TMBc,Ghc)
    end
    
end

