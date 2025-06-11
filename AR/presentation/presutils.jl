include("../utils/utils.jl")

@tryusing "CairoMakie"

istickable(date_) = (month(date_) ∈ [1, 7]) && day(date_) == 1
istickableday(date_) = day(date_) == 1


function PlotCurves(curvesvec, date_vec; bands=nothing, labelvec=nothing, colors=nothing, ylimits=nothing, size_=nothing, smallscale=false)
    length(curvesvec[1]) == 1 ? curvesvec = [curvesvec] : nothing
    isnothing(size_) ? size_ = isnothing(labelvec) ? (750, 400) : (750, 600) : nothing

    n_days = length(date_vec)
    ticksindexes = findall(smallscale ? istickableday : istickable, date_vec)

    fig = Figure(size=size_)
    ax = Axis(fig[1:2, 1:2], xticks=(ticksindexes, string.(date_vec[ticksindexes])),
        ylabel="Temperature (°C)")
    isnothing(ylimits) ? nothing : ax.limits = (nothing, ylimits)

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

    colors = RGBf.((00:(160÷iend-1):160) ./ 255, 151 / 255, 223 / 255)

    M = 30
    H, L = 2 * M + 195 + 135 * (iend - 1), 400 + 50 * iend + M
    f = Figure(size=(L, H))

    axs = [CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), H - M - 195 - 135 * (i - 1), H - M - (i - 1) * 135), backgroundcolor=(:white, 1), ylabel="T (°C)") for i in 1:iend-1]
    i = iend
    axend = CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), H - M - 195 - 135 * (i - 1), H - M - (i - 1) * 135), xlabelrotation=30, xlabelsize=12, ylabel="T (°C)")

    CairoMakie.linkxaxes!(axs..., axend)
    CairoMakie.linkyaxes!(axs..., axend)

    #temp series plots
    for (i, ax) in enumerate(axs)
        CairoMakie.lines!(ax, date_vec, curvesvec[i]; linewidth=2, color=colors[i])
        CairoMakie.hidexdecorations!(ax)
        CairoMakie.translate!(ax.blockscene, 0, 0, 200 - 200 * (iend - i))
    end
    setproperty!.((axs..., axend), :backgroundcolor, ((:white, 0.6),))
    CairoMakie.translate!(axend.blockscene, 0, 0, 200)
    CairoMakie.lines!(axend, date_vec, curvesvec[iend]; linewidth=2, color=colors[iend])
    CairoMakie.hidexdecorations!(axend, ticklabels=false)

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
    fig = Figure(size=(600, 450), fontsize = 17)
    ax = Axis(fig[1:2, 1:2])
    ax.title = "Real monthly $(Stats)"
    ax.xticks = (1:12, Month_vec2)
    ax.ylabel = "Temperature (°C)"
    lines!(ax, RealStats, color=color)
    return fig
end

PlotMonthlyRealStats(x::AbstractVector, date_vec::AbstractVector, Stats::String, color="#ff6600") = (
    PlotMonthlyRealStats(DataFrame(DATE=date_vec, TEMP=x), Stats, color))