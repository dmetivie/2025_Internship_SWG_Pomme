include("utils.jl")

@tryusing "CairoMakie"

##### PLOTTING #####
"""
    MiddleMonth(year::Int)

Return the indexes of the middle of each month of the input year. For now it's useful only to display month labels in plots.
"""
MiddleMonth(year::Integer) = (cumsum(DaysPerMonth(year)) .+ cumsum([0; DaysPerMonth(year)])[1:12]) ./ 2

"""
    PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=[], colorbands::AbstractVector=[])

Plot the annuel series in curvesvec. Their length must be 365 or 366. You can also plots bands : each band must be a tuple or a vector of two series, the first one corresponding to the bottom of the band.
You can choose the color of each band in the vector colorbands.
"""
function PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=Tuple[], colorbands::AbstractVector=Tuple[]; colors::AbstractVector=String[])
    length(curvesvec) != 0 ? length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing : nothing  #We test if curvesvec is one series or a vector of series
    n_days = length(curvesvec) != 0 ? length(curvesvec[1]) : length(bands[1][1])
    ReferenceYear = n_days == 366 ? 0 : 1
    fig = Figure(size=(900, 750))
    ax2 = Axis(fig[1:2, 1:2], xticks=(MiddleMonth(ReferenceYear), Month_vec),
        ygridvisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        xgridvisible=false,
        xticksvisible=false,
        xticklabelspace=5.0,
        xticklabelrotation=45.0)
    ax2.limits = ([0; n_days], nothing)
    ax = Axis(fig[1:2, 1:2], xticks=[0; cumsum(DaysPerMonth(ReferenceYear))], xticklabelsvisible=false)
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
    ax.ylabel = "Temperature (°C)"
    ax.xticks = [0; cumsum(DaysPerMonth(ReferenceYear))]
    ax.limits = ([0; n_days], nothing)
    Legend(fig[3, 1:2], pltvec, labelvec)
    return fig
end
# PlotYearCurves(curvesvec::AbstractVector{AbstractFloat}, labelvec::String, title::String) = PlotYearCurves(curvesvec, [labelvec], title)

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
function PlotMonthlyStats(RealStats::AbstractVector, SimulatedStats::AbstractMatrix, Stats::String, comment=nothing)
    fig = Figure(size=(900, 750))
    ax = Axis(fig[1:2, 1:2])
    ax.title = isnothing(comment) ? "Real monthly $(Stats) vs range of simulated monthly $(Stats)" : "Real monthly $(Stats) vs range of simulated monthly $(Stats) $(comment)"
    ax.xticks = (1:12, Month_vec)
    ax.xticklabelrotation = 45.0
    ax.ylabel = "Temperature (°C)"
    pltvec = Plot[]
    bands = [(minimum.(eachrow(SimulatedStats)), maximum.(eachrow(SimulatedStats))),
        (quantile.(eachrow(SimulatedStats), 0.25), quantile.(eachrow(SimulatedStats), 0.75))
    ]
    colorbands = [("#009bff", 0.2), ("#009bff", 0.5)]
    for (band_, colorband) in zip(bands, colorbands)
        push!(pltvec, CairoMakie.band!(ax, 1:12, band_[1], band_[2]; color=colorband))
    end
    push!(pltvec, CairoMakie.scatter!(ax, RealStats, color="Orange"))
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
