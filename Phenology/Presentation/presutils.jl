include("../PhenoPred.jl")

cd(@__DIR__)

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
    fig = Figure(size=(600, 450))
    ax = Axis(fig[1:2, 1:2])
    ax.title = "Real monthly $(Stats)"
    ax.xticks = (1:12, Month_vec2)
    ax.ylabel = "Temperature (°C)"
    lines!(ax, RealStats, color=color)
    return fig
end

PlotMonthlyRealStats(x::AbstractVector, date_vec::AbstractVector, Stats::String, color="#ff6600") = (
    PlotMonthlyRealStats(DataFrame(DATE=date_vec, TEMP=x), Stats, color))




function PlotCurveApple(temp, date_vec;
    labelvec=nothing,
    ylimits=nothing,
    size_=nothing,
    smallscale=false,
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)

    isnothing(size_) ? size_ = isnothing(labelvec) ? (750, 400) : (750, 600) : nothing

    ind(date_) = findfirst(date_vec .== date_)
    sumchillingvec, sumforcingvec = [0.], [0.]
    chilling, forcing = false, false
    sumchilling, sumforcing, CPO_date, DB, BB = 0., 0., Date(0), Date(0), Date(0)

    for (Tg, date_) in zip(temp, date_vec)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            chilling = true
            sumchilling = 0.
            CPO_date = date_
        end
        if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumchilling += Rc(Tg, chilling_model)
            push!(sumchillingvec, sumchilling)
            if sumchilling > chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
                DB = date_
                chilling = false
                forcing = true
                sumforcing = 0.
            end
        end
        if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
            sumforcing += Rf(Tg, forcing_model)
            push!(sumforcingvec, sumforcing)
            if sumforcing > forcing_target
                BB = date_
                forcing = false
            end
        end
    end


    # n_days = length(date_vec)
    ticksindexes = findall(istickableday, date_vec)
    nameindexes = (ticksindexes[1:end-1] + ticksindexes[2:end]) / 2
    # println(ticksindexes)
    # println(nameindexes)

    fig = Figure(size=size_)

    ax12 = Axis(fig[1:2, 1:2], xticks=(nameindexes, Month_vec2[month.(date_vec[ticksindexes])][1:end-1]),
        ygridvisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        xgridvisible=false,
        xticksvisible=false,
        xticklabelspace=5.0)

    ax12.limits = ([ind.(date_vec[1]) - 5, ind.(date_vec[end]) + 5], [-10., 40])

    ax = Axis(fig[1:2, 1:2],
        xticks=ticksindexes,
        xticklabelsvisible=false,
        ylabel="Temperature (°C)")

    ax.limits = ([ind.(date_vec[1]) - 5, ind.(date_vec[end]) + 5], [-10., 40])

    pltvec = Plot[]

    #temp series plots
    push!(pltvec, lines!(ax, ind.(date_vec), temp, color="black"))
    push!(pltvec, lines!(ax, [ind.(CPO_date), ind.(CPO_date)], [-10., 40], color="blue"))
    push!(pltvec, lines!(ax, [ind.(DB), ind.(DB)], [-10., 40], color="#ff6600"))
    push!(pltvec, lines!(ax, [ind.(BB), ind.(BB)], [-10., 40], color="green"))

    ax22 = Axis(fig[3:4, 1:2], xticks=(nameindexes, Month_vec2[month.(date_vec[ticksindexes])][1:end-1]),
        ygridvisible=false,
        yticksvisible=false,
        yticklabelsvisible=false,
        xgridvisible=false,
        xticksvisible=false,
        xticklabelspace=5.0)

    ax22.limits = ([ind.(date_vec[1]) - 5, ind.(date_vec[end]) + 5], [-5, 100])

    ax2 = Axis(fig[3:4, 1:2],
        xticks=ticksindexes,
        ylabel="Chilling/Forcing units",
        xticklabelsvisible=false)

    ax2.limits = ([ind.(date_vec[1]) - 5, ind.(date_vec[end]) + 5], [-5, 100])

    lines!(ax2, [ind.(CPO_date), ind.(CPO_date)], [-5., 100], color="blue")
    lines!(ax2, [ind.(DB), ind.(DB)], [-5., 100], color="#ff6600")
    lines!(ax2, [ind.(BB), ind.(BB)], [-5., 100], color="green")

    push!(pltvec, band!(ax2, (ind.(CPO_date)-1):ind.(DB), fill(0, length(sumchillingvec)), sumchillingvec, color=("blue", 0.7)))
    push!(pltvec, band!(ax2, (ind.(DB)-1):ind.(BB), fill(0, length(sumforcingvec)), sumforcingvec, color=("#ff6600", 0.7)))

    labelvec = ["TG",
        "Chilling period onset",
        "Endodormancy break",
        "Budburst",
        "Chilling units sum",
        "Forcing units sum"]

    Legend(fig[1:4, 3], pltvec, labelvec)

    return fig
end