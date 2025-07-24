include("utils.jl")
include("../presentation/presutils.jl")
include("ACF_PACF.jl")

@tryusing "CairoMakie"

##### PLOTTING #####
"""
    MiddleMonth(year::Int)

Return the indexes of the middle of each month of the input year. For now it's useful only to display month labels in plots.
"""
MiddleMonth(year::Integer) = (cumsum(DaysPerMonth(year)) .+ cumsum([0; DaysPerMonth(year)])[1:12]) ./ 2

"""
    PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=[], colorbands::AbstractVector=[])

Plot the annual series in curvesvec. Their length must be 365 or 366. You can also plots bands : each band must be a tuple or a vector of two series, the first one corresponding to the bottom of the band.
You can choose the color of each band in the vector colorbands.
"""
function PlotYearCurvesAxes!(fig, curvesvec::AbstractVector, title::String="", bands::AbstractVector=Tuple[], colorbands::AbstractVector=Tuple[]; colors::AbstractVector=String[], ylabel=true)
    length(curvesvec) != 0 ? length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing : nothing  #We test if curvesvec is one series or a vector of series
    n_days = length(curvesvec) != 0 ? length(curvesvec[1]) : length(bands[1][1])
    ReferenceYear = n_days == 366 ? 0 : 1
    ax2 = Axis(fig, xticks=(MiddleMonth(ReferenceYear), Month_vec_low),
        ygridvisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        xgridvisible=false,
        xticksvisible=false,
        xticklabelspace=5.0)
    # xticklabelrotation=45.0)
    ax2.limits = ([0; n_days], nothing)
    ax = Axis(fig, xticks=[0; cumsum(DaysPerMonth(ReferenceYear))], xticklabelsvisible=false)
    pltbands = Plot[]
    for (band_, colorband) in zip(bands, colorbands)
        push!(pltbands, CairoMakie.band!(ax, 1:n_days, band_[1], band_[2]; color=colorband))
    end
    pltlines = Plot[]
    if length(colors) != 0
        for (vec, color_) in zip(curvesvec, colors)
            push!(pltlines, CairoMakie.lines!(ax, 1:n_days, vec, color=color_))
        end
    else
        for vec in curvesvec
            push!(pltlines, CairoMakie.lines!(ax, 1:n_days, vec))
        end
    end
    pltvec = [pltlines; pltbands]
    ax.title = title
    ax.xlabel = "Day"
    ax.xlabelpadding = 30.0
    ylabel ? ax.ylabel = "Temperature (°C)" : nothing
    ax.xticks = [0; cumsum(DaysPerMonth(ReferenceYear))]
    ax.limits = ([0; n_days], nothing)
    return pltvec
end

function PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=Tuple[], colorbands::AbstractVector=Tuple[]; colors::AbstractVector=String[])
    fig = Figure(size=(900, 750))
    pltvec = PlotYearCurvesAxes!(fig[1:2, 1:2], curvesvec, title, bands, colorbands; colors=colors)
    Legend(fig[3, 1:2], pltvec, labelvec)
    return fig
end









"""
    PlotParameters(Parameters_vec::AbstractVector)

With a list of parameters estimated with the three methods studied in this project, this function return a figure object with all the parameters estimated.
You can add the real parameters values, but it is optional.
The input must be like this : [[Φ1_month_vec,Φ1_month_concat,Φ1_month_sumLL,Φ1_month_MLL,Φ1_true_param],[Φ2_month_vec,Φ2_month_concat,Φ2_month_sumLL,Φ2_month_MLL,Φ2_true_param],...,[σ_month_vec,σ_month_concat,σ_month_sumLL,σ_month_MLL,σ_true_param]]
"""
function PlotParametersMLL(Parameters_vec::AbstractVector, lines_::Bool=false)
    fig = Figure(size=(800, 600 * length(Parameters_vec)))
    month_vec, month_concat, month_sumLL, month_MLL, true_param = 0, 0, 0, 0, 0
    for (j, Parameters) in enumerate(Parameters_vec)
        try
            month_vec, month_concat, month_sumLL, month_MLL, true_param = Parameters
        catch BoundsError
            month_vec, month_concat, month_sumLL, month_MLL = Parameters
            true_param = nothing
        end
        if j == length(Parameters_vec) #i.e Parameter = σ
            for i in 1:12
                month_vec[i] = month_vec[i][month_vec[i].>1e-2] #I remove the values estimated close to 0.
            end
        end
        month_vec[1] = month_vec[1][abs.(month_vec[1]).<1e5] #To remove problematical values (exploded values)
        ax, plt1 = CairoMakie.boxplot(fig[1+3(j-1):2+3(j-1), 1:2], fill(1, length(month_vec[1])), month_vec[1]; width=0.3, color="orange")
        for i in 2:12
            month_vec[i] = month_vec[i][abs.(month_vec[i]).<1e5]
            CairoMakie.boxplot!(ax, fill(i, length(month_vec[i])), month_vec[i]; width=0.3, color="orange")
        end
        lines_ ? pltl = lines!(ax, collect(1:12), j == length(Parameters_vec) ? mean.(month_vec) : median.(month_vec); color="blue") : nothing
        plt2 = isnothing(true_param) ? nothing : CairoMakie.scatter!(ax, collect(1:12), true_param; color="Blue", markersize=15)
        I_concat = findall(abs.(month_concat) .< 1e4) #To remove problematical values (exploded values)
        plt3 = CairoMakie.scatter!(ax, I_concat .+ 0.15, month_concat[I_concat]; color="red", marker=:utriangle, markersize=12.5)
        I_sumLL = findall(abs.(month_sumLL) .< 1e4) #To remove problematical values (exploded values)
        plt4 = CairoMakie.scatter!(ax, I_sumLL .- 0.15, month_sumLL[I_sumLL]; color="green", marker=:dtriangle, markersize=12.5)
        plt5 = CairoMakie.scatter!(ax, collect(1:12), month_MLL; color="Purple", markersize=12.5)
        str = j == length(Parameters_vec) ? "σ" : "Φ$(j)"
        ax.title = isnothing(true_param) ? "Estimated $(str) with 3 methods" : "Real $(str) vs estimated $(str) with 3 methods"
        ax.xticks = (1:12, Month_vec)
        ax.xticklabelrotation = 45.0
        j == length(Parameters_vec) ? ax.ylabel = "Temperature (°C)" : nothing
        strline = j == length(Parameters_vec) ? "Mean of $(str) estimated on each year and month" : "Median of $(str) estimated on each year and month"
        if isnothing(true_param)
            if lines_
                Legend(fig[3+3(j-1), 1:2], [plt1, pltl, plt3, plt4, plt5], ["Boxplots of $(str) estimated on each year and month", strline, "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods", "Estimated $(str) with monthly likelihood"])
            else
                Legend(fig[3+3(j-1), 1:2], [plt1, plt3, plt4, plt5], ["Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods", "Estimated $(str) with monthly likelihood"])
            end
        else
            if lines_
                Legend(fig[3+3(j-1), 1:2], [plt2, plt1, pltl, plt3, plt4, plt5], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", strline, "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods", "Estimated $(str) with monthly likelihood"])
            else
                Legend(fig[3+3(j-1), 1:2], [plt2, plt1, plt3, plt4, plt5], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods", "Estimated $(str) with monthly likelihood"])
            end
        end
    end
    return fig
end
function PlotParameters(Parameters_vec::AbstractVector, lines_::Bool=false, MLL::Bool=false)
    if MLL
        return PlotParametersMLL(Parameters_vec, lines_)
    else
        fig = Figure(size=(800, 600 * length(Parameters_vec)))
        month_vec, month_concat, month_sumLL, true_param = 0, 0, 0, 0
        for (j, Parameters) in enumerate(Parameters_vec)
            try
                month_vec, month_concat, month_sumLL, true_param = Parameters
            catch BoundsError
                month_vec, month_concat, month_sumLL = Parameters
                true_param = nothing
            end
            if j == length(Parameters_vec) #i.e Parameter = σ
                for i in 1:12
                    month_vec[i] = month_vec[i][month_vec[i].>1e-2] #I remove the values estimated close to 0.
                end
            end
            month_vec[1] = month_vec[1][abs.(month_vec[1]).<1e5] #To remove problematical values (exploded values)
            ax, plt1 = CairoMakie.boxplot(fig[1+3(j-1):2+3(j-1), 1:2], fill(1, length(month_vec[1])), month_vec[1]; width=0.3, color="orange")
            for i in 2:12
                month_vec[i] = month_vec[i][abs.(month_vec[i]).<1e5]
                CairoMakie.boxplot!(ax, fill(i, length(month_vec[i])), month_vec[i]; width=0.3, color="orange")
            end
            lines_ ? pltl = lines!(ax, collect(1:12), j == length(Parameters_vec) ? mean.(month_vec) : median.(month_vec); color="blue") : nothing
            plt2 = isnothing(true_param) ? nothing : CairoMakie.scatter!(ax, collect(1:12), true_param; color="Blue", markersize=15)
            I_concat = findall(abs.(month_concat) .< 1e4) #To remove problematical values (exploded values)
            plt3 = CairoMakie.scatter!(ax, I_concat .+ 0.15, month_concat[I_concat]; color="red", marker=:utriangle, markersize=12.5)
            I_sumLL = findall(abs.(month_sumLL) .< 1e4) #To remove problematical values (exploded values)
            plt4 = CairoMakie.scatter!(ax, I_sumLL .- 0.15, month_sumLL[I_sumLL]; color="green", marker=:dtriangle, markersize=12.5)
            str = j == length(Parameters_vec) ? "σ" : "Φ$(j)"
            ax.title = isnothing(true_param) ? "Estimated $(str) with 3 methods" : "Real $(str) vs estimated $(str) with 3 methods"
            ax.xticks = (1:12, Month_vec)
            ax.xticklabelrotation = 45.0
            j == length(Parameters_vec) ? ax.ylabel = "Temperature (°C)" : nothing
            strline = j == length(Parameters_vec) ? "Mean of $(str) estimated on each year and month" : "Median of $(str) estimated on each year and month"
            if isnothing(true_param)
                if lines_
                    Legend(fig[3+3(j-1), 1:2], [plt1, pltl, plt3, plt4], ["Boxplots of $(str) estimated on each year and month", strline, "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
                else
                    Legend(fig[3+3(j-1), 1:2], [plt1, plt3, plt4], ["Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
                end
            else
                if lines_
                    Legend(fig[3+3(j-1), 1:2], [plt2, plt1, pltl, plt3, plt4], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", strline, "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
                else
                    Legend(fig[3+3(j-1), 1:2], [plt2, plt1, plt3, plt4], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
                end
            end
        end
        return fig
    end
end



"""
    PlotMonthlyStats(RealStats::AbstractVector,SimulatedStats::AbstractMatrix,Stats::String)

Plot the monthly statistics in RealStats, the range of the monthly stats from simulations in SimulatedStats (row=month,column=simulations) and the quantile interval (0.25,0.75) of the monthly stats from these simulations.
"""
function PlotMonthlyStatsAx!(fig, RealStats::AbstractVector, SimulatedStats::AbstractMatrix, Stats::String, comment=nothing; ylabel=true)
    ax = Axis(fig)
    ax.title = isnothing(comment) ? "Real monthly $(Stats) vs range of simulated monthly $(Stats)" : "Real monthly $(Stats) vs range of simulated monthly $(Stats) $(comment)"
    ax.xticks = (1:12, Month_vec_low)
    # ax.xticklabelrotation = 45.0
    ylabel ? ax.ylabel = "Temperature (°C)" : nothing
    pltvec = Plot[]
    bands = [(minimum.(eachrow(SimulatedStats)), maximum.(eachrow(SimulatedStats))),
        (quantile.(eachrow(SimulatedStats), 0.25), quantile.(eachrow(SimulatedStats), 0.75))
    ]
    colorbands = [("#009bff", 0.2), ("#009bff", 0.5)]
    for (band_, colorband) in zip(bands, colorbands)
        push!(pltvec, CairoMakie.band!(ax, 1:12, band_[1], band_[2]; color=colorband))
    end
    push!(pltvec, CairoMakie.scatter!(ax, RealStats, color="Orange"))
    return pltvec
end

function PlotMonthlyStats(RealStats::AbstractVector, SimulatedStats::AbstractMatrix, Stats::String, comment=nothing)
    fig = Figure(size=(900, 750))
    pltvec = PlotMonthlyStatsAx!(fig[1:2, 1:2], RealStats, SimulatedStats, Stats, comment)
    Legend(fig[3, 1:2], pltvec, ["Range of simulated monthly $(Stats)", "Simulated monthly $(Stats) quantile interval, p ∈ [0.25,0.75]", "Real monthly $(Stats)"])
    return fig
end


"""
    WrapPlotMonthlyStats(df_month::DataFrame,sample_::AbstractVector,sample_timeline::AbstractVector{Date})

A wrapper for PlotMonthlyStats, where the real monthly statistics are in df_month (row=month), sample_ is a vector containing the simulations and sample_timeline a vector of the timeline of the simulations.
Return three plots, for the mean, the standard deviation and the maximum.
"""
function WrapPlotMonthlyStats(df_month::DataFrame, sample_::AbstractVector, sample_timeline::AbstractVector{Date}, comment=nothing)
    idx_m = [findall(month.(sample_timeline) .== m) for m in 1:12]
    mean_ts = [[mean(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack
    std_ts = [[std(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack
    max_ts = [[maximum(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack
    return PlotMonthlyStats(df_month.MONTHLY_MEAN, mean_ts, "mean", comment),
    PlotMonthlyStats(df_month.MONTHLY_STD, std_ts, "standard deviation", comment),
    PlotMonthlyStats(df_month.MONTHLY_MAX, max_ts, "maximum", comment)
end

"""
    Plot the monthly parameters in the vector MonthlyParams (MonthlyParams = [[Φ1Jan,Φ1Feb...],...[σJan,σFeb]])
"""
function PlotMonthlyparams(MonthlyParams)
    fig = Figure(size=(100 + 420 * length(MonthlyParams), 400))
    for (i, MonthlyParam) in enumerate(MonthlyParams)
        if i == length(MonthlyParams)
            PlotMonthlyStatsAx(fig[1, i], MonthlyParam, "σ", unit="C°")
        else
            PlotMonthlyStatsAx(fig[1, i], MonthlyParam, "Φ$(i)")
        end
    end
    return fig
end



function Sample_diagnostic(sample_, date_vec, period, avg_day, max_day, df_month; format_="vertical", size=format_ == "vertical" ? (1200, 1900) : (1600, 900))
    year_sample = GatherYearScenarios(sample_, date_vec)

    idx_m = [findall(month.(date_vec) .== m) for m in 1:12]
    mean_ts = [[mean(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack
    std_ts = [[std(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack
    max_ts = [[maximum(ts[idx_m[m]]) for m in 1:12] for ts in sample_] |> stack

    fig = Figure(size=size)

    if format_ == "horizontal"
        figvec = [(fig[1:2, 1:3], fig[3, 2]),
            (fig[1:2, 4:6], fig[3, 5]),
            (fig[1:2, 7:9], fig[3, 8]),
            (fig[4:5, 1:3], fig[6, 2]),
            (fig[4:5, 4:6], fig[6, 5]),
            (fig[4:5, 7:9], fig[6, 8])]
    else
        figvec = [(fig[1:2, 1:3], fig[3, 2]),
            (fig[1:2, 4:6], fig[3, 5]),
            (fig[4:5, 1:3], fig[6, 2]),
            (fig[4:5, 4:6], fig[6, 5]),
            (fig[7:8, 1:3], fig[9, 2]),
            (fig[7:8, 4:6], fig[9, 5])]
    end

    ylabelBoolVec = format_ == "horizontal" ? [true, false, false, true, false, false] : [true, false, true, false, true, false]

    plt1 = PlotYearCurvesAxes!(figvec[1][1], [period, mean.(year_sample)], "Average daily temperature during a year (centered)", ylabel=ylabelBoolVec[1])
    Legend(figvec[1][2], plt1, ["Periodicity estimation", "Mean simulated temperatures"])

    plt2 = PlotYearCurvesAxes!(figvec[2][1], [period, avg_day, max_day],
        "Average daily temperature during a year (centered)",
        [(minimum.(year_sample), maximum.(year_sample)), (quantile.(year_sample, 0.25), quantile.(year_sample, 0.75))],
        [("#009bff", 0.2), ("#009bff", 0.5)],
        colors=["blue", "orange", "red"],
        ylabel=ylabelBoolVec[2])
    Legend(figvec[2][2], plt2, ["Periodicity estimation", "Average recorded temperatures", "Maximum recorded temperatures", "Simulated temperatures range", "Simulated temperatures quantile interval, p ∈ [0.25,0.75]"])

    plt3 = PlotYearCurvesAxes!(figvec[3][1], [maximum.(year_sample) .- minimum.(year_sample), quantile.(year_sample, 0.75) .- quantile.(year_sample, 0.25)],
        "Simulated temperatures interquartile range",
        ylabel=ylabelBoolVec[3])
    Legend(figvec[3][2], plt3, ["Simulated temperatures range", "Simulated temperatures interquartile range, p ∈ [0.25,0.75]"])

    plt4 = PlotMonthlyStatsAx!(figvec[4][1], df_month.MONTHLY_MEAN, mean_ts, "mean", ylabel=ylabelBoolVec[4])
    Legend(figvec[4][2], plt4, ["Range of simulated monthly mean", "Simulated monthly mean quantile interval, p ∈ [0.25,0.75]", "Real monthly mean"])

    plt5 = PlotMonthlyStatsAx!(figvec[5][1], df_month.MONTHLY_STD, std_ts, "standard deviation", ylabel=ylabelBoolVec[5])
    Legend(figvec[5][2], plt5, ["Range of simulated monthly standard deviation", "Simulated monthly standard deviation quantile interval, p ∈ [0.25,0.75]", "Real monthly standard deviation"])

    plt6 = PlotMonthlyStatsAx!(figvec[6][1], df_month.MONTHLY_MAX, max_ts, "maximum", ylabel=ylabelBoolVec[6])
    Legend(figvec[6][2], plt6, ["Range of simulated monthly maximum", "Simulated monthly maximum quantile interval, p ∈ [0.25,0.75]", "Real monthly maximum"])

    return fig
end


function Sample_diagnostic(sample_,Caracteristics_Series,Model;format_="vertical", size=format_ == "vertical" ? (1200, 1900) : (1600, 900))
    fig1 = PlotMonthlyparams([invert(Model.Φ) ; [Model.σ]])
    fig2 = Sample_diagnostic(sample_, 
    Model.date_vec,
    Model.period .+ mean(Model.trend), 
    Caracteristics_Series.avg_day,
    Caracteristics_Series.max_day,
    Caracteristics_Series.df_month,
    format_=format_,
    size=size
    )
    fig3=Plot_Sample_MonthlyACF(sample_,Model.date_vec,Model.z)
    fig4=Plot_Sample_MonthlyPACF(sample_,Model.date_vec,Model.z)
    return (fig1,fig2,fig3,fig4)
end

