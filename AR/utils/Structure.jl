@tryusing "FileIO", "JLD2"

abstract type AR_SWG end

mutable struct SimpleAR <: AR_SWG
    Φ::AbstractVector
    σ::AbstractFloat
    nspart::AbstractVector
    y₁::AbstractVector
end

# mutable struct MonthlyAR <: AR_SWG
#     Φ::AbstractVector
#     σ::AbstractVector
#     trend::AbstractVector
#     period::AbstractVector
#     date_vec::AbstractVector
#     y₁::AbstractVector
# end


mutable struct MonthlyAR <: AR_SWG
    Φ::AbstractVector
    σ::AbstractVector
    trend::AbstractVector
    period::AbstractVector
    period_order::Integer
    σ_trend::AbstractVector
    σ_period::AbstractVector
    σ_period_order::Integer
    date_vec::AbstractVector
    y₁::AbstractVector
    z::AbstractVector
end


mutable struct Multi_MonthlyAR <: AR_SWG
    Φ::AbstractArray
    σ::AbstractArray
    trend::AbstractArray
    period::AbstractArray
    period_order::Integer
    σ_trend::AbstractArray
    σ_period::AbstractArray
    σ_period_order::Integer
    date_vec::AbstractArray
    y₁::AbstractArray
    z::AbstractArray
end


include("Periodicity.jl")
include("utils.jl")
include("../table_reader.jl")
include("Estimation.jl")
include("Simulation.jl")
include("Trend.jl")
include("Multi_AR_Estimation.jl")



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

# fit_simpleAR(x, date_vec, p=2, degree_period::Integer=5) = fit_simpleAR(x, date_vec, p, "trigo", degree_period)

# series = extract_series("TX_STAID000031.txt", plot=false)
# x, date_vec = (series[!, 2], series.DATE)
# myAR = fit_simpleAR(x, date_vec, 1)

inverse_dayofyear_Leap(n) = Date(0) + Day(n - 1)

ismatrix(M) = false
ismatrix(M::AbstractMatrix) = true

function Base.rand(rng::Random.AbstractRNG, model::AR_SWG, n::Integer=1, date_vec::AbstractVector{Date}=model.date_vec; y₁=model.y₁, correction="null")
    if ismatrix(model.period)
        period = model.period[dayofyear_Leap.(model.date_vec), :]
        σ_period = model.σ_period[dayofyear_Leap.(model.date_vec), :]
    else
        period = model.period[dayofyear_Leap.(model.date_vec)]
        σ_period = model.σ_period[dayofyear_Leap.(model.date_vec)]
    end
    if date_vec == model.date_vec
        nspart = model.trend .+ period
        σ_nspart = model.σ_trend .+ σ_period
    else
        index_nspart = findall(t -> t ∈ date_vec, model.date_vec)
        nspart = (model.trend .+ period)[index_nspart]
        σ_nspart = (model.σ_trend .+ σ_period)[index_nspart] 
    end
    return SimulateScenarios(y₁, date_vec, model.Φ, model.σ, nspart_, σ_nspart_, rng, n=n, correction=correction)
end
function Base.rand(rng::Random.AbstractRNG, model::AR_SWG, n::Integer, n2t::AbstractVector{Integer}; y₁=model.y₁, correction="null")
    return rand(rng, model, n, inverse_dayofyear_Leap.(n2t), y₁=y₁)
end
Base.rand(model::AR_SWG, n::Integer=1, date_vec::AbstractVector{Date}=model.date_vec; y₁=model.y₁, correction="null") = rand(Random.default_rng(), model, n, date_vec, y₁=y₁, correction=correction)
Base.rand(model::AR_SWG, n::Integer, n2t::AbstractVector{Integer}; y₁=model.y₁, correction="null") = rand(Random.default_rng(), model, n, inverse_dayofyear_Leap.(n2t), y₁=y₁, correction=correction)



# rand(myAR, date_vec[1]:date_vec[end], 100, y₁=0.1)


function fit_ARMonthlyParameters(y, date_vec, p, method_)
    method_ == "monthlyLL" ? nothing : Monthly_temp = MonthlySeparateX(y, date_vec)
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



defaultparam = Dict([("LOESS", 0.08), ("polynomial", 1), ("null", 1)])
defaultorder = Dict([("trigo", 5), ("smooth", 9), ("autotrigo", 50), ("stepwise_trigo", 50)])
function fit_AR(x, date_vec;
    p::Integer=1,
    method_::String="monthlyLL",
    periodicity_model::String="autotrigo",
    degree_period::Integer=0,
    Trendtype="LOESS",
    trendparam=nothing,
    σ_periodicity_model::String="autotrigo",
    σ_degree_period::Integer=0,
    σ_Trendtype="LOESS",
    σ_trendparam=nothing)

    isnothing(trendparam) ? trendparam = defaultparam[Trendtype] : nothing

    if Trendtype == "LOESS"
        trend = LOESS(x, trendparam)
    elseif Trendtype == "polynomial"
        trend = PolyTrendFunc(x, trendparam).(eachindex(x))
    else
        trend = zero(x)
    end
    y = x - trend


    degree_period == 0 ? degree_period = defaultorder[periodicity_model] : nothing

    if periodicity_model == "trigo"
        period_order = degree_period
        trigo_function = fitted_periodicity_fonc(y, date_vec, OrderTrig=degree_period)
        periodicity, period = trigo_function.(date_vec), trigo_function.(Date(0):(Date(1)-Day(1)))

    elseif periodicity_model == "smooth"
        period_order = degree_period
        smooth_function = fitted_smooth_periodicity_fonc(y, date_vec, OrderDiff=degree_period)
        periodicity, period = smooth_function.(date_vec), smooth_function.(Date(0):(Date(1)-Day(1)))

    elseif periodicity_model == "autotrigo"
        autotrigo_function, period_order = fitted_periodicity_fonc_auto(y, date_vec, MaxOrder=degree_period)
        periodicity, period = autotrigo_function.(date_vec), autotrigo_function.(Date(0):(Date(1)-Day(1)))

    elseif periodicity_model == "stepwise_trigo"
        autotrigo_function, period_order = fitted_periodicity_fonc_stepwise(y, date_vec, MaxOrder=degree_period)
        periodicity, period = autotrigo_function.(date_vec), autotrigo_function.(Date(0):(Date(1)-Day(1)))
    end
    z = y - periodicity


    if σ_Trendtype != "null"
        isnothing(σ_trendparam) ? σ_trendparam = defaultparam[σ_Trendtype] : nothing
        if σ_Trendtype == "LOESS"
            σ_trend_sq = LOESS(z .^ 2, σ_trendparam)
        elseif σ_Trendtype == "polynomial"
            σ_trend_sq = PolyTrendFunc(z^2, σ_trendparam).(eachindex(x))
        end
        σ_trend = σ_trend_sq .^ 0.5
    else
        σ_trend = ones(length(z))
    end
    z = z ./ σ_trend


    σ_periodicity_model != "null" ? σ_degree_period == 0 ? σ_degree_period = defaultorder[σ_periodicity_model] : nothing : nothing

    if σ_periodicity_model == "trigo"
        σ_period_order = σ_degree_period
        trigo_function = fitted_periodicity_fonc(z .^ 2, date_vec, OrderTrig=σ_degree_period)
        σ_periodicity, σ_period = trigo_function.(date_vec) .^ 0.5, trigo_function.(Date(0):(Date(1)-Day(1))) .^ 0.5

    elseif σ_periodicity_model == "smooth"
        σ_period_order = σ_degree_period
        smooth_function = fitted_smooth_periodicity_fonc(z .^ 2, date_vec, OrderDiff=σ_degree_period)
        σ_periodicity, σ_period = smooth_function.(date_vec) .^ 0.5, smooth_function.(Date(0):(Date(1)-Day(1))) .^ 0.5

    elseif σ_periodicity_model == "autotrigo"
        autotrigo_function, σ_period_order = fitted_periodicity_fonc_auto(z .^ 2, date_vec, MaxOrder=σ_degree_period)
        σ_periodicity, σ_period = autotrigo_function.(date_vec) .^ 0.5, autotrigo_function.(Date(0):(Date(1)-Day(1))) .^ 0.5

    elseif σ_periodicity_model == "stepwise_trigo"
        autotrigo_function, σ_period_order = fitted_periodicity_fonc_stepwise(z .^ 2, date_vec, MaxOrder=σ_degree_period)
        σ_periodicity, σ_period = autotrigo_function.(date_vec) .^ 0.5, autotrigo_function.(Date(0):(Date(1)-Day(1))) .^ 0.5

    else
        σ_periodicity, σ_period = ones(length(z)), ones(366)
    end
    z = z ./ σ_periodicity



    Φ, σ = fit_ARMonthlyParameters(z, date_vec, p, method_)

    return MonthlyAR(Φ, σ, trend, period, period_order, σ_trend, σ_period, σ_period_order, date_vec, z[1:p], z)
end





function fit_Multi_AR(x, date_vec;
    p::Integer=1,
    method_::String="monthly",
    periodicity_model::String="autotrigo",
    degree_period::Integer=0,
    Trendtype="LOESS",
    trendparam=nothing,
    σ_periodicity_model::String="autotrigo",
    σ_degree_period::Integer=0,
    σ_Trendtype="LOESS",
    σ_trendparam=nothing)

    isnothing(trendparam) ? trendparam = defaultparam[Trendtype] : nothing
    degree_period == 0 ? degree_period = defaultorder[periodicity_model] : nothing
    isnothing(σ_trendparam) ? σ_trendparam = defaultparam[σ_Trendtype] : nothing
    σ_periodicity_model != "null" ? σ_degree_period == 0 ? σ_degree_period = defaultorder[σ_periodicity_model] : nothing : nothing

    z, trend_mat, period_mat, σ_trend_mat, σ_period_mat = AbstractVector[], AbstractVector[], AbstractVector[], AbstractVector[], AbstractVector[]

    for x_ in eachcol(x)
        if Trendtype == "LOESS"
            trend = LOESS(x_, trendparam)
        elseif Trendtype == "polynomial"
            trend = PolyTrendFunc(x_, trendparam).(eachindex(x))
        else
            trend = zero(x_)
        end
        y_ = x_ - trend
        push!(trend_mat, trend)

        if periodicity_model == "trigo"
            trigo_function = fitted_periodicity_fonc(y_, date_vec, OrderTrig=degree_period)
            periodicity, period = trigo_function.(date_vec), trigo_function.(Date(0):(Date(1)-Day(1)))
        elseif periodicity_model == "smooth"
            smooth_function = fitted_smooth_periodicity_fonc(y_, date_vec, OrderDiff=degree_period)
            periodicity, period = smooth_function.(date_vec), smooth_function.(Date(0):(Date(1)-Day(1)))
        elseif periodicity_model == "autotrigo"
            autotrigo_function = fitted_periodicity_fonc_auto(y_, date_vec, MaxOrder=degree_period)
            periodicity, period = autotrigo_function.(date_vec), autotrigo_function.(Date(0):(Date(1)-Day(1)))
        end
        z_ = y_ - periodicity
        push!(period_mat, period)


        if σ_Trendtype != "null"

            if σ_Trendtype == "LOESS"
                σ_trend_sq = LOESS(z_ .^ 2, σ_trendparam)
            elseif σ_Trendtype == "polynomial"
                σ_trend_sq = PolyTrendFunc(z_ .^ 2, σ_trendparam).(eachindex(x))
            end
            σ_trend = σ_trend_sq .^ 0.5
        else
            σ_trend = ones(length(z_))
        end
        z_ = z_ ./ σ_trend
        push!(σ_trend_mat, σ_trend)


        if σ_periodicity_model == "trigo"
            trigo_function = fitted_periodicity_fonc(z_ .^ 2, date_vec, OrderTrig=σ_degree_period)
            σ_periodicity, σ_period = trigo_function.(date_vec) .^ 0.5, trigo_function.(Date(0):(Date(1)-Day(1))) .^ 0.5
        elseif σ_periodicity_model == "smooth"
            smooth_function = fitted_smooth_periodicity_fonc(z_ .^ 2, date_vec, OrderDiff=σ_degree_period)
            σ_periodicity, σ_period = smooth_function.(date_vec) .^ 0.5, smooth_function.(Date(0):(Date(1)-Day(1))) .^ 0.5
        elseif σ_periodicity_model == "autotrigo"
            autotrigo_function = fitted_periodicity_fonc_auto(z_ .^ 2, date_vec, MaxOrder=σ_degree_period)
            σ_periodicity, σ_period = autotrigo_function.(date_vec) .^ 0.5, autotrigo_function.(Date(0):(Date(1)-Day(1))) .^ 0.5
        else
            σ_periodicity, σ_period = ones(length(z_)), ones(366)
        end
        z_ = z_ ./ σ_periodicity
        push!(σ_period_mat, σ_period)
        push!(z, z_)
    end
    z, trend_mat, period_mat, σ_trend_mat, σ_period_mat = stack.((z, trend_mat, period_mat, σ_trend_mat, σ_period_mat))

    if method_ == "monthly"
        Φ, Σ = ParseMonthlyParameter(LL_Multi_AR_Estimation_monthly(z, date_vec, p), size(x)[2])
    else
        nothing #Take Φ Σ daily (e.g 366-length list of matrix for Σ)
    end

    return Multi_MonthlyAR(Φ, Σ, trend_mat, period_mat, degree_period, σ_trend_mat, σ_period_mat, σ_degree_period, date_vec, z[1:p, :], z)
end
#works

save_model(model, title="model.jld2") = save(title, "model", model)
load_model(file, struct_=Multi_MonthlyAR) = load(file)["model"]

mutable struct CaracteristicsSeries
    avg_day::AbstractVector
    max_day::AbstractVector
    df_month::DataFrame
end

function init_CaracteristicsSeries(series)
    Days_list = GatherYearScenario(series[!, 2], series.DATE)
    avg_day = mean.(Days_list)
    max_day = maximum.(Days_list)
    df_month = @chain series begin
        @transform(:TEMP = series[!, 2]) #Give a common name for TX, TN, etc...
        @transform(:MONTH = month.(:DATE)) #add month column
        @by(:MONTH, :MONTHLY_MEAN = mean(:TEMP), :MONTHLY_STD = std(:TEMP), :MONTHLY_MAX = maximum(:TEMP)) # grouby MONTH + takes the mean/std in each category 
    end
    return CaracteristicsSeries(avg_day, max_day, df_month)
end