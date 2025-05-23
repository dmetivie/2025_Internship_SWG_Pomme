include("Periodicity.jl")
include("utils.jl")
include("../table_reader.jl")
include("Estimation.jl")
include("Simulation.jl")

@tryusing "Random"

abstract type AR_SWG end

mutable struct SimpleAR <: AR_SWG
    Φ::AbstractVector
    σ::AbstractFloat
    nspart::AbstractVector
    y₁::AbstractVector
end

mutable struct MonthlyAR <: AR_SWG
    Φ::AbstractVector
    σ::AbstractVector
    nspart::AbstractVector
    y₁::AbstractVector
end

function fit_simpleAR(x, date_vec, p, periodicity_model::String, degree_period::Integer)
    if periodicity_model == "trigo"
        trigo_function = fitted_periodicity_fonc(x, date_vec, OrderTrig=degree_period)
        periodicity = trigo_function.(date_vec)
        nspart = trigo_function.(Date(0):Date(1)-Day(1))
    elseif periodicity_model == "smooth"
        smooth_function = fitted_smooth_periodicity_fonc(x, date_vec, OrderDiff=degree_period)
        periodicity = smooth_function.(date_vec)
        nspart = smooth_function.(Date(0):Date(1)-Day(1))
    elseif periodicity_model == "autotrigo"
        autotrigo_function = fitted_periodicity_fonc_stepwise(x, date_vec, MaxOrder=degree_period)
        periodicity = autotrigo_function.(date_vec)
        nspart = autotrigo_function.(Date(0):Date(1)-Day(1))
    end
    y = x - periodicity
    Φ, σ = LL_AR_Estimation(y, p)
    return SimpleAR(Φ, σ, nspart, y[1:p])
end

function fit_simpleAR(x, date_vec, p, periodicity_model::String="trigo")
    if periodicity_model == "trigo"
        return fit_simpleAR(x, date_vec, p, periodicity_model, 5)
    elseif periodicity_model == "smooth"
        return fit_simpleAR(x, date_vec, p, periodicity_model, 9)
    elseif periodicity_model == "mean"
        nspart = mean.(GatherYearScenario(x, date_vec))
        y = x - nspart[dayofyear_Leap.(date_vec)]
        Φ, σ = LL_AR_Estimation(y, p)
        return SimpleAR(Φ, σ, nspart, y[1:p])
    end
end

inverse_dayofyear_Leap(n) = Date(0) + Day(n - 1)

function Base.rand(rng::Random.AbstractRNG, model::AR_SWG, date_vec::AbstractVector{Date}, n::Integer=1; y₁=model.y₁)
    return n == 1 ? SimulateScenario(y₁, date_vec, model.Φ, model.σ, model.nspart, rng) : SimulateScenarios(y₁, date_vec, model.Φ, model.σ, model.nspart, rng, n=n)
end
function Base.rand(rng::Random.AbstractRNG, model::AR_SWG, n2t::AbstractVector{Integer}, n::Integer=1; y₁=model.y₁)
    return rand(rng, model, inverse_dayofyear_Leap.(n2t), n, y₁=y₁)
end
Base.rand(model::AR_SWG, date_vec::AbstractVector{Date}, n::Integer=1; y₁=model.y₁) = rand(Random.default_rng(), model, date_vec, n, y₁=y₁)
Base.rand(model::AR_SWG, n2t::AbstractVector{Integer}, n::Integer=1; y₁=model.y₁) = rand(Random.default_rng(), model, inverse_dayofyear_Leap.(n2t), n, y₁=y₁)


function fit_ARMonthlyParameters(y, date_vec, p, method_)
    Monthly_temp = MonthlySeparateX(y, date_vec)
    if method_ == "mean"
        Monthly_Estimators = MonthlyEstimation(Monthly_temp, p) #Monthly_Estimators[i][j][k][l] i-> month, j-> year, k-> 1 for [Φ_1,Φ_2,...], 2 for σ, l -> index of the parameter (Φⱼ) of year if k=1 
        Monthly_Estimators2 = [[[year_[1]; year_[2]] for year_ in Month] |> stack for Month in Monthly_Estimators]
        meanparam = mulmean.(eachrow.(Monthly_Estimators2)) |> stack
        return eachrow(meanparam[1:2, :]'), meanparam[3, :]
    elseif method_ == "median"
        Monthly_Estimators = MonthlyEstimation(Monthly_temp, p) #Monthly_Estimators[i][j][k][l] i-> month, j-> year, k-> 1 for [Φ_1,Φ_2,...], 2 for σ, l -> index of the parameter (Φⱼ) of year if k=1 
        Monthly_Estimators2 = [[[year_[1]; year_[2]] for year_ in Month] |> stack for Month in Monthly_Estimators]
        medianparam = mulmedian.(eachrow.(Monthly_Estimators2)) |> stack
        return eachrow(medianparam[1:2, :]'), medianparam[3, :]
    elseif method_ == "concat"
        return MonthlyConcatanatedEstimation(Monthly_temp, p) #Φ[i][j] : i-> month, j-> index of the parameter (Φⱼ) or (σ)
    elseif method_ == "sumLL"
        return MonthlyEstimationSumLL(Monthly_temp, p)
    elseif method_ == "monthlyLL"
        return LL_AR_Estimation_monthly(y, date_vec, p)
    end
end

defaultorder=Dict([("trigo",5),("smooth",9),("autotrigo",50)])
function fit_MonthlyAR(x, date_vec; p::Integer=1, method_::String="monthlyLL", periodicity_model::String="autotrigo", degree_period::Integer=0)
    degree_period == 0 ? degree_period = defaultorder[periodicity_model] : nothing

    if periodicity_model == "trigo"
        trigo_function = fitted_periodicity_fonc(x, date_vec, OrderTrig=degree_period)
        periodicity = trigo_function.(date_vec)
        nspart = trigo_function.(Date(0):Date(1)-Day(1))
    elseif periodicity_model == "smooth"
        smooth_function = fitted_smooth_periodicity_fonc(x, date_vec, OrderDiff=degree_period)
        periodicity = smooth_function.(date_vec)
        nspart = smooth_function.(Date(0):Date(1)-Day(1))
    elseif periodicity_model == "autotrigo"
        autotrigo_function = fitted_periodicity_fonc_stepwise(x, date_vec, MaxOrder=degree_period)
        periodicity = autotrigo_function.(date_vec)
        nspart = autotrigo_function.(Date(0):Date(1)-Day(1))
    end
    y = x - periodicity
    Φ, σ = fit_ARMonthlyParameters(y, date_vec, p, method_)
    return MonthlyAR(Φ, σ, nspart, y[1:p])
end
