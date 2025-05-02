include("utils.jl")

@tryusing "CairoMakie"

##### PLOTTING #####
"""
    MiddleMonth(year::Int)

Return the indexes of the middle of each month of the input year. For now it's useful only to display month labels in plots.
"""
MiddleMonth(year::Integer) = (cumsum([0; DaysPerMonth(year)])[2:13] .+ cumsum([0; DaysPerMonth(year)])[1:12]) ./ 2

"""
    PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=[], colorbands::AbstractVector=[])

Plot the annuel series in curvesvec. Their length must be 365. You can also plots bands : each band must be a tuple or a vector of two series, the first one corresponding to the bottom of the band.
You can choose the color of each band in the vector colorbands.
"""
function PlotYearCurves(curvesvec::AbstractVector, labelvec::AbstractVector, title::String="", bands::AbstractVector=Tuple[], colorbands::AbstractVector=Tuple[])
    length(curvesvec) != 0 ? length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing : nothing  #We test if curvesvec is one series or a vector of series
    fig = Figure()
    ax2 = Axis(fig[1:2, 1:2], xticks=(MiddleMonth(1), Month_vec),
        ygridvisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        xgridvisible=false,
        xticksvisible=false,
        xticklabelspace=5.0,
        xticklabelrotation=45.0)
    ax2.limits = ([0; 365], nothing)
    ax = Axis(fig[1:2, 1:2], xticks=[0; cumsum(DaysPerMonth(1))], xticklabelsvisible=false)
    pltbands = Plot[]
    for (band_, colorband) in zip(bands, colorbands)
        append!(pltbands, [band!(ax, 1:365, band_[1], band_[2]; color=colorband)])
    end
    pltlines = Plot[]
    for vec in curvesvec
        append!(pltlines, [lines!(ax, 1:365, vec)])
    end
    pltvec = [pltlines; pltbands]
    ax.title = title
    ax.xlabel = "Day"
    ax.xlabelpadding = 30.0
    ax.ylabel = "Temperature (°C)"
    ax.xticks = [0; cumsum(DaysPerMonth(1))]
    ax.limits = ([0; 365], nothing)
    Legend(fig[3, 1:2], pltvec, labelvec)
    return fig
end
# PlotYearCurves(curvesvec::AbstractVector{AbstractFloat}, labelvec::String, title::String) = PlotYearCurves(curvesvec, [labelvec], title)

"""
    PlotParameters(Parameters_vec::AbstractVector)

With a list of parameters estimated with the three methods studied in this project, this function return a figure object with all the parameters estimated.
You can add the real parameters values, but it is optional.
The input must be like this : [[Φ1_month_vec,Φ1_month_concat,Φ1_month_sumLL,Φ1_true_param],[Φ2_month_vec,Φ2_month_concat,Φ2_month_sumLL,Φ2_true_param],...,[σ_month_vec,σ_month_concat,σ_month_sumLL,σ_true_param]]
"""
function PlotParameters(Parameters_vec::AbstractVector, lines_::Bool=false)
    fig = Figure(size=(800, 600 * length(Parameters_vec)))
    month_vec, month_concat, month_sumLL, true_param = 0, 0, 0, 0
    for (j, Parameters) in enumerate(Parameters_vec)
        try
            month_vec, month_concat, month_sumLL, true_param = Parameters
        catch BoundsError
            month_vec, month_concat, month_sumLL = Parameters
            true_param = nothing
        end
        ax, plt1 = boxplot(fig[1+3(j-1):2+3(j-1), 1:2], fill(1, length(month_vec[1])), month_vec[1]; width=0.3, color="orange")
        for i in 2:12
            boxplot!(ax, fill(i, length(month_vec[i])), month_vec[i]; width=0.3, color="orange")
        end
        lines_ ? pltl = lines!(ax, collect(1:12), median.(month_vec); color="blue") : nothing
        plt2 = isnothing(true_param) ? nothing : scatter!(ax, collect(1:12), true_param; color="Blue", markersize=15)
        plt3 = scatter!(ax, collect(1:12) .+ 0.15, month_concat; color="red", marker=:utriangle, markersize=12.5)
        plt4 = scatter!(ax, collect(1:12) .- 0.15, month_sumLL; color="green", marker=:dtriangle, markersize=12.5)
        str = j == length(Parameters_vec) ? "σ" : "Φ$(j)"
        ax.title = isnothing(true_param) ? "Estimated $(str) with 3 methods" : "Real $(str) vs estimated $(str) with 3 methods"
        ax.xticks = (1:12, Month_vec)
        ax.xticklabelrotation = 45.0
        if isnothing(true_param)
            if lines_
                Legend(fig[3+3(j-1), 1:2], [plt1, pltl, plt3, plt4], ["Boxplots of $(str) estimated on each year and month", "Median of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
            else
                Legend(fig[3+3(j-1), 1:2], [plt1, plt3, plt4], ["Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
            end
        else
            if lines_
                Legend(fig[3+3(j-1), 1:2], [plt2, plt1, pltl, plt3, plt4], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", "Median of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
            else
                Legend(fig[3+3(j-1), 1:2], [plt2, plt1, plt3, plt4], ["Real $(str)", "Boxplots of $(str) estimated on each year and month", "Estimated $(str) with months concatanated", "Estimated $(str) with sum of likelihoods"])
            end
        end
    end
    return fig
end
