include("../utils/utils.jl")

@tryusing "CairoMakie"

# istickable(date_) = (month(date_) ∈ [1, 7]) && day(date_) == 1
istickablemonth(date_) = day(date_) == 1
istickableyear(date_) = month(date_) == 1 && day(date_) == 1


function PlotCurves(curvesvec, date_vec; bands=nothing, labelvec=nothing, colors=nothing, ylimits=nothing, size_=nothing, noylabel=false, xtlfreq="", rotate_xtl=false)
    length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing
    isnothing(size_) ? size_ = isnothing(labelvec) ? (750, 400) : (750, 600) : nothing

    n_days = length(date_vec)
    xlimits = [-5., n_days + 5]
    strfunc(date_) = "$(year(date_))"

    # if xtlfreq == "year"
    #     ticksindexes = findall(istickableyear, date_vec)
    #     xticklabel = strfunc.(date_vec[ticksindexes])
    # elseif xtlfreq == "month"

    #     xticklabel = [ ; "" ] #[Month_vec_low .* ",1ˢᵗ" ; Month_vec_low[1] * ",1ˢᵗ" ]
    # end

    # ticksindexes = findall(smallscale ? istickableday : istickable, date_vec)
    # strfunc(date_) = yearlabel ? "$(year(date_))" : "$(year(date_))-$(month(date_))"

    fig = Figure(size=size_)

    if xtlfreq == "month"
        ticksindexes = findall(istickablemonth, date_vec)
        nameindexes = (ticksindexes[1:end-1] + ticksindexes[2:end]) / 2

        ax12 = Axis(fig[1:2, 1:2], xticks=(nameindexes, Month_vec_low[month.(date_vec[ticksindexes])][1:end-1]), #Only to show the xtickslabel at the right places
            ygridvisible=false,
            yticksvisible=false,
            yticklabelsvisible=false,
            xgridvisible=false,
            xticksvisible=false,
            xticklabelspace=24.0,
            xticklabelsize=18)

        rotate_xtl ? ax12.xticklabelrotation=45 : nothing

        isnothing(ylimits) ? nothing : ax12.limits = (xlimits, ylimits)

        ax = Axis(fig[1:2, 1:2])
        noylabel ? nothing : ax.ylabel = "Temperature (°C)"
        ax.ylabelsize = 25
        ax.yticklabelsize = 25
        ax.xticks = ticksindexes
        ax.xticklabelsvisible = false

        isnothing(ylimits) ? nothing : ax.limits = (xlimits, ylimits)

    else

        if xtlfreq == "year"
            ticksindexes = findall(istickableyear, date_vec)
            xticklabel = strfunc.(date_vec[ticksindexes])
        else
            ticksindexes = findall(istickablemonth, date_vec)
            xticklabel = string.(date_vec[ticksindexes])
        end

        ax = Axis(fig[1:2, 1:2], xticks=(ticksindexes, xticklabel))
        noylabel ? nothing : ax.ylabel = "Temperature (°C)"
        ax.ylabelsize = 25
        ax.yticklabelsize = 25
        ax.xticklabelsize = xtlfreq == "year" ? 25 : 18
        rotate_xtl ? ax.xticklabelrotation=45 : nothing

        isnothing(ylimits) ? nothing : ax.limits = (nothing, ylimits)
    end

    pltvec = Plot[]

    #Bands plots
    if !isnothing(bands)
        if isnothing(colors)
            for band in bands
                push!(pltvec, band!(ax, 1:n_days, band[1], band[2]))
            end
        else
            for (band, color_) in zip(bands, colors[1:length(bands)])
                push!(pltvec, band!(ax, 1:n_days, band[1], band[2], color=color_))
            end
        end
    end

    #temp series plots
    if isnothing(colors)
        for vec in curvesvec
            push!(pltvec, lines!(ax, 1:n_days, vec))
        end
    else
        for (vec, color_) in zip(curvesvec, isnothing(bands) ? colors : colors[(length(bands)+1):end])
            push!(pltvec, lines!(ax, 1:n_days, vec, color=color_))
        end
    end

    #legend
    isnothing(labelvec) ? nothing : Legend(fig[3, 1:2], pltvec, labelvec)

    return fig
end


function PlotCards(curvesvec, date_vec)
    length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing
    iend = length(curvesvec)
    n_days = length(date_vec)
    ticksindexes = findall(istickablemonth, date_vec)

    colors = RGBf.((00:(160÷iend-1):160) ./ 255, 151 / 255, 223 / 255)

    M = 30
    H, L = 2 * M + 195 + 135 * (iend - 1), 400 + 50 * iend + M
    f = Figure(size=(L, H))

    axs = [CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), H - M - 195 - 135 * (i - 1), H - M - (i - 1) * 135), backgroundcolor=(:white, 1), ylabel="T (°C)", xticks=ticksindexes, xticklabelsvisible=false) for i in 1:iend-1]
    for ax in axs
        ax.limits = ([-10, length(curvesvec[end]) + 10], [-13., 45.])
    end
    i = iend


    #####
    nameindexes = (ticksindexes[1:end-1] + ticksindexes[2:end]) / 2

    axendm = CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), H - M - 195 - 135 * (i - 1), H - M - (i - 1) * 135), xticks=(nameindexes, Month_vec_low)) #Only to show the xtickslabel at the right places
    axendm.ygridvisible = false
    axendm.yticksvisible = false
    axendm.yticklabelsvisible = false
    axendm.xgridvisible = false
    axendm.xticksvisible = false
    # axendm.xticklabelspace = 24.0

    axendm.limits = ([-10, length(curvesvec[end]) + 10], [-13., 45.])

    axend = CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), H - M - 195 - 135 * (i - 1), H - M - (i - 1) * 135))
    axend.ylabel = "T (°C)"
    axend.xticks = ticksindexes
    axend.xticklabelsvisible = false

    axend.limits = ([-10, length(curvesvec[end]) + 10], [-10, 40])
    ######

    CairoMakie.linkxaxes!(axs..., axend)
    CairoMakie.linkyaxes!(axs..., axend)

    #temp series plots
    for (i, ax) in enumerate(axs)
        CairoMakie.lines!(ax, 1:n_days, curvesvec[i]; linewidth=2, color=colors[i])
        # CairoMakie.hidexdecorations!(ax)
        CairoMakie.translate!(ax.blockscene, 0, 0, 200 - 200 * (iend - i))
    end
    setproperty!.((axs..., axendm, axend), :backgroundcolor, ((:white, 0.6),))
    CairoMakie.translate!(axend.blockscene, 0, 0, 200)
    CairoMakie.translate!(axendm.blockscene, 0, 0, 200)
    CairoMakie.lines!(axend, 1:n_days, curvesvec[iend]; linewidth=2, color=colors[iend])
    # CairoMakie.hidexdecorations!(axend, ticklabels=false)

    return f
end


function PlotMonthlyRealStats(series::DataFrame, Stats::String; color="#ff6600")
    df_month = @chain series begin
        @transform(:TEMP = series[!, 2]) #Give a common name for TX, TN, etc...
        @transform(:MONTH = month.(:DATE)) #add month column
        @by(:MONTH, :MONTHLY_MEAN = mean(:TEMP), :MONTHLY_STD = std(:TEMP), :MONTHLY_MAX = maximum(:TEMP)) # grouby MONTH + takes the mean/std in each category 
    end
    Dictcase = Dict([("mean", df_month.MONTHLY_MEAN), ("standard deviation", df_month.MONTHLY_STD), ("maximum", df_month.MONTHLY_MAX)])
    RealStats = Dictcase[Stats]
    fig = Figure(size=(600, 450), fontsize=17)
    ax = Axis(fig[1:2, 1:2])
    ax.title = "Real monthly $(Stats)"
    ax.xticks = (1:12, Month_vec2)
    ax.ylabel = "Temperature (°C)"
    lines!(ax, RealStats, color=color)
    return fig
end

PlotMonthlyRealStats(x::AbstractVector, date_vec::AbstractVector, Stats::String, color="#ff6600") = (
    PlotMonthlyRealStats(DataFrame(DATE=date_vec, TEMP=x), Stats, color))