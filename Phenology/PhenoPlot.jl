include("Phenopred.jl")


"""
    Return the number of days since the CPO (chilling period onset). 
    If previous_year=true, we consider that the CPO happened the year before whatever the situation,
    so it's not appropriate if we want to return the NDSCPO before the Endodormancy break, which can happen in December for example. 
"""
function ScaleDate(date_::Date, CPO=(8, 1), previous_year=false)
    value_ = date_ - Date(year(date_) - (previous_year ? 1 : 0), CPO[1], CPO[2]) #The number days to go to the date_ from the CPO
    return value_ > Day(0) ? Dates.value(value_) : Dates.value(date_ - Date(year(date_) - 1, CPO[1], CPO[2])) #If this number < 0 (the CPO happened after date_, we automatically consider the CPO of the year before.)
end

first_of_month(m::Integer) = Date(0, m)
fifteen_of_month(m::Integer) = Date(0, m, 15)

name_first_of_month(m::Integer) = Month_vec_low[m] * ",1ˢᵗ"
name_fifteen_of_month(m::Integer) = Month_vec_low[m] * ",15ᵗʰ"


function Plot_Pheno_Dates_ax!(subfig, date_vecs, CPO; sample_=nothing, title=nothing, labelvec=nothing, BB=false, colors=nothing, dashindexes=Integer[])

    #If date_vecs is one series, it's transformed into a 1-length vector containing this series
    if typeof(date_vecs[1]) == Date
        isnothing(labelvec) ? date_vecs = [date_vecs] : (date_vecs, labelvec) = ([date_vecs], [labelvec])
    end

    ScaleDateCPO(date_) = ScaleDate(date_, CPO, BB) #If we consider the Budburst date, we are sure that the CPO happened the year before.

    #We get the number of days since the CPO for each date. (NDSCPO)
    NDSCPO_vecs = [ScaleDateCPO.(date_vec) for date_vec in date_vecs]

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs = isnothing(sample_) ? reduce(vcat, date_vecs) : [reduce(vcat, date_vecs); reduce(vcat, sample_)]

    #The months presents in each series.
    CurrentMonths = unique(month.(Conc_date_vecs))

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(CurrentMonths), fifteen_of_month.(CurrentMonths))
    Names_month = interleave2(name_first_of_month.(CurrentMonths), name_fifteen_of_month.(CurrentMonths)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateCPO.(Dates_month) #And their NDSCPO

    y_min = minimum(NDSCPO_month) #y_min : NDSCPO of the first day of the first month.
    y_max = ScaleDateCPO(Date(0, month(Dates_month[argmax(NDSCPO_month)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    last_month_str = name_first_of_month(month(Dates_month[argmax(NDSCPO_month)] + Month(1))) #And his string associated

    ax = Axis(subfig, yticks=([NDSCPO_month; y_max], [Names_month; last_month_str])) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = (nothing, [y_min, y_max])
    ax.xlabel = "Year"
    ax.ylabel = "Date"
    ax.ylabelpadding = 5.

    isnothing(title) ? nothing : ax.title = "$(title) dates for each year"

    pltvec = Plot[]
    bands = nothing

    if !isnothing(sample_) #If we want to consider a set of generated
        #Pre-treating the sample to have data per year
        Conc_sets = reduce(vcat, sample_)
        years_ = unique(year.(Conc_sets))

        Dictyears = Dict{Integer}{AbstractVector}()
        for year_ in years_
            Dictyears[year_] = Integer[]
        end

        for set in sample_
            for date_ in set
                push!(Dictyears[year(date_)], ScaleDateCPO(date_))
            end
        end

        #Now we can make the bands :
        bands = [(minimum.(values(Dictyears)), maximum.(values(Dictyears))), (quantile.(values(Dictyears), 0.25), quantile.(values(Dictyears), 0.75))]

        #Bands plots
        if isnothing(colors)
            for band in bands
                push!(pltvec, band!(ax, unique(year.(date_vecs[1])), band[1], band[2]))
            end
        else
            for (band, color_) in zip(bands, colors[1:length(bands)])
                push!(pltvec, band!(ax, unique(year.(date_vecs[1])), band[1], band[2], color=color_))
            end
        end
    end

    #NDSCPO plots
    if isnothing(colors)
        for (date_vec, NDSCPO_date_vec, i) in zip(date_vecs, NDSCPO_vecs, eachindex(NDSCPO_vecs))
            push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec, linestyle=i ∈ dashindexes ? :dash : :solid))
        end
    else
        for (date_vec, NDSCPO_date_vec, i, color_) in zip(date_vecs, NDSCPO_vecs, eachindex(NDSCPO_vecs), isnothing(bands) ? colors : colors[(length(bands)+1):end])
            push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec, linestyle=i ∈ dashindexes ? :dash : :solid, color=color_))
        end
    end

    # if isnothing(colors)
    #     for (date_vec, NDSCPO_date_vec) in zip(date_vecs, NDSCPO_vecs)
    #         push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec))
    #     end
    # else
    #     for (date_vec, NDSCPO_date_vec, color_) in zip(date_vecs, NDSCPO_vecs, isnothing(bands) ? colors : colors[(length(bands)+1):end])
    #         push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec, color=color_))
    #     end
    # end


    return pltvec
end


function Plot_Pheno_Dates(date_vecs, CPO; sample_=nothing, title=nothing, labelvec=nothing, BB=false, colors=nothing)

    fig = Figure(size=(700, 600))

    pltvec = Plot_Pheno_Dates_ax!(fig[1:2, 1:2], date_vecs, CPO,
        sample_=sample_,
        title=title,
        BB=BB,
        colors=colors)

    #legend
    isnothing(labelvec) ? nothing : Legend(fig[3, 1:2], pltvec, labelvec)

    return fig
end



function Plot_Both_Pheno_Dates(date_vecs_DB, date_vecs_BB, CPO; sample_DB=nothing, sample_BB=nothing, labelvec=nothing, colors=nothing, rightlegend=false)
    fig = Figure(size=(700, 600))

    Plot_Pheno_Dates_ax!(fig[1:2, 1:2], date_vecs_BB, CPO,
        sample_=sample_BB,
        title="Budburst",
        BB=true,
        colors=colors)

    pltvec = Plot_Pheno_Dates_ax!(fig[3:4, 1:2], date_vecs_DB, CPO,
        sample_=sample_DB,
        title="Endodormancy break",
        BB=false,
        colors=colors)

    isnothing(labelvec) ? nothing : (rightlegend ? Legend(fig[1:4, 3], pltvec, labelvec) : Legend(fig[5, 1:2], pltvec, labelvec))

    return fig
end

# using CairoMakie

# lines([1, 2, 3, 4, 5], [1, -2, 4, 3, -7], linestyle=:dash)





function Plot_Pheno_Dates_DB_BB(date_vecDB::Vector{Date}, date_vecBB::Vector{Date}, CPO; sample_DB=nothing, sample_BB=nothing, station_name="")

    fig = Figure(size=(900, 400))

    ScaleDateDB(date_) = ScaleDate(date_, CPO, false)
    ScaleDateBB(date_) = ScaleDate(date_, CPO, true)

    NDSCPO_DB = ScaleDateDB.(date_vecDB)
    NDSCPO_BB = ScaleDateBB.(date_vecBB)

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs_DB = isnothing(sample_DB) ? date_vecDB : [date_vecDB; reduce(vcat, sample_DB)]
    Conc_date_vecs_BB = isnothing(sample_BB) ? date_vecBB : [date_vecBB; reduce(vcat, sample_BB)]

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(1:12), fifteen_of_month.(1:12))
    Names_month = interleave2(name_first_of_month.(1:12), name_fifteen_of_month.(1:12)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateDB.(Dates_month) #And their NDSCPO

    NDSCPO_inf = maximum(NDSCPO_month[NDSCPO_month.<=minimum(ScaleDateDB.(Conc_date_vecs_DB))]) #The optimal NDSCPO_month to minimise the true NDSCPO.
    NDSCPO_sup = minimum(NDSCPO_month[NDSCPO_month.>=maximum(ScaleDateDB.(Conc_date_vecs_BB))]) #The optimal NDSCPO_month to maximise the true NDSCPO.

    Names_month = Names_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]
    NDSCPO_month = NDSCPO_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]

    # y_max = ScaleDateBB(Date(0, month(Dates_month[argmax(NDSCPO_month)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    ax = Axis(fig[1:4, 1:4], yticks=(NDSCPO_month, Names_month)) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = (nothing, [NDSCPO_inf, NDSCPO_sup])
    ax.xlabel = "Year"
    ax.ylabel = "Date"
    ax.ylabelpadding = 5.

    ax.title = "Endodormancy Break and Budburst dates for each year, $(station_name)"

    pltvec = Plot[]
    bands = nothing

    for (sample_, colors, SD_func) in zip([sample_DB, sample_BB], [[("#e5ca20", 0.2), ("#e5ca20", 0.5)], [("#009bff", 0.2), ("#009bff", 0.5)]], [ScaleDateDB, ScaleDateBB])
        if !isnothing(sample_) #If we want to consider a set of generated
            #Pre-treating the sample to have data per year
            Conc_sets = reduce(vcat, sample_)
            years_ = unique(year.(Conc_sets))

            Dictyears = Dict{Integer}{AbstractVector}()
            for year_ in years_
                Dictyears[year_] = Integer[]
            end

            for set in sample_
                for date_ in set
                    push!(Dictyears[year(date_)], SD_func(date_))
                end
            end

            #Now we can make the bands :
            bands = [(minimum.(values(Dictyears)), maximum.(values(Dictyears))), (quantile.(values(Dictyears), 0.25), quantile.(values(Dictyears), 0.75))]

            #Bands plots
            for (band, color_) in zip(bands, colors)
                push!(pltvec, band!(ax, years_, band[1], band[2], color=color_))
            end
        end
    end

    #NDSCPO plots
    push!(pltvec, lines!(ax, year.(date_vecDB), NDSCPO_DB, color="#ff6600"))
    push!(pltvec, lines!(ax, year.(date_vecBB), NDSCPO_BB, color="green"))

    #Legend

    Legend(fig[3:4, 5], pltvec[[1, 2, 5]], ["Simulated EB Min-Max interval",
        "Simulated EB [0.25 ; 0.75] quantile interval",
        "Predicted EB in $(station_name)"])

    Legend(fig[1:2, 5], pltvec[[3, 4, 6]], ["Simulated BB Min-Max interval",
        "Simulated BB [0.25 ; 0.75] quantile interval",
        "Predicted BB in $(station_name)"])

    return fig
end



function Plot_Pheno_Dates_DB_BB(date_vecsDB, date_vecsBB, CPO;
    DB_colors=nothing,
    BB_colors=nothing,
    DB_label=nothing,
    BB_label=nothing,
    dashindexes=Integer[],
    size=(800, 400),
    breakpoints=true)

    fig = Figure(size=size)

    ScaleDateDB(date_) = ScaleDate(date_, CPO, false)
    ScaleDateBB(date_) = ScaleDate(date_, CPO, true)

    NDSCPO_vecs_DB = [ScaleDateDB.(date_vecDB) for date_vecDB in date_vecsDB]
    NDSCPO_vecs_BB = [ScaleDateBB.(date_vecBB) for date_vecBB in date_vecsBB]

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs_DB = reduce(vcat, date_vecsDB)
    Conc_date_vecs_BB = reduce(vcat, date_vecsBB)

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(1:12), fifteen_of_month.(1:12))
    Names_month = interleave2(name_first_of_month.(1:12), name_fifteen_of_month.(1:12)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateDB.(Dates_month) #And their NDSCPO

    NDSCPO_inf = maximum(NDSCPO_month[NDSCPO_month.<=minimum(ScaleDateDB.(Conc_date_vecs_DB))]) #The optimal NDSCPO_month to minimise the true NDSCPO.
    NDSCPO_sup = minimum(NDSCPO_month[NDSCPO_month.>=maximum(ScaleDateDB.(Conc_date_vecs_BB))]) #The optimal NDSCPO_month to maximise the true NDSCPO.

    Names_month = Names_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]
    NDSCPO_month = NDSCPO_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]

    # y_max = ScaleDateBB(Date(0, month(Dates_month[argmax(NDSCPO_month)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    ax = Axis(fig[1:4, 1:4], yticks=(NDSCPO_month, Names_month)) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = (nothing, [NDSCPO_inf, NDSCPO_sup])
    ax.xlabel = "Year"
    ax.ylabel = "Date"
    ax.ylabelpadding = 5.

    ax.title = "Endodormancy Break and Budburst dates for each year"

    pltvec = Plot[]

    #NDSCPO plots
    DB = true
    for (date_vecs, NDSCPO_vecs, colors) in zip([date_vecsDB, date_vecsBB], [NDSCPO_vecs_DB, NDSCPO_vecs_BB], [DB_colors, BB_colors])
        if isnothing(colors)
            for (date_vec, NDSCPO_date_vec, i) in zip(date_vecs, NDSCPO_vecs, eachindex(NDSCPO_vecs))
                push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec, linestyle=i ∈ dashindexes ? :dash : :solid))
            end
        else
            if breakpoints == true
                for (date_vec, NDSCPO_date_vec, i, color_) in zip(date_vecs, NDSCPO_vecs, eachindex(NDSCPO_vecs), colors)
                    push!(pltvec, scatterlines!(ax, year.(date_vec), NDSCPO_date_vec, linestyle=i ∈ dashindexes ? :dash : :solid, color=color_, marker=DB ? :vline : :star4))
                end
            else
                for (date_vec, NDSCPO_date_vec, i, color_) in zip(date_vecs, NDSCPO_vecs, eachindex(NDSCPO_vecs), colors)
                    push!(pltvec, lines!(ax, year.(date_vec), NDSCPO_date_vec, linestyle=i ∈ dashindexes ? :dash : :solid, color=color_))
                end
            end
        end
        DB = false
    end

    #Label
    isnothing(DB_label) ? nothing : Legend(fig[3:4, 5], pltvec[1:length(date_vecsDB)], DB_label)
    isnothing(BB_label) ? nothing : Legend(fig[1:2, 5], pltvec[length(date_vecsDB)+1:end], BB_label)

    return fig
end


function Plot_Freeze_Risk(TN_vecs, dates_vecs_TN, date_vecsBB;
    CPO=(8, 1),
    colors=nothing,
    label=nothing,
    size=(800, 400),
    threshold=-2)

    Streak_vecs, date_vecsBB2 = Vector[], Vector[]

    for (TN_vec, dates_vec_TN, date_vecBB) in zip(TN_vecs, dates_vecs_TN, date_vecsBB)
        FreezingRiskBB(BB) = FreezingRisk(TN_vec, dates_vec_TN, BB, CPO=CPO, threshold=threshold)
        Streak_vec = FreezingRiskBB.(date_vecBB)
        Streak_vec, date_vecBB2 = Streak_vec[Streak_vec.>0], date_vecBB[Streak_vec.>0]
        push!(Streak_vecs, Streak_vec)
        push!(date_vecsBB2, date_vecBB2)
    end

    Ω = sort(unique(reduce(vcat, Streak_vecs)))
    if length(Ω)==0
        println("No days with TN ≤ -2°C after budburst in any of the series !")
        return nothing
    end

    fig = Figure(size=size)

    ax = Axis(fig[1:2, 1:2], yticks=Ω)
    ax.xlabel = "Year"
    ax.ylabel = "Days"
    ax.title = "Max number of consecutives days with TN ≤ -2°C after budburst"

    pltvec = Plot[]
    K = length(Streak_vecs)
    L = 0.05 * K

    if isnothing(colors)
        for (date_vecBB, Streak_vec, k) in zip(date_vecsBB2, Streak_vecs, eachindex(Streak_vecs))
            push!(pltvec, scatter!(ax, year.(date_vecBB), Streak_vec - L / 2 + (k - 1) * L / (K - 1)))
        end
    else
        for (date_vecBB, Streak_vec, color_, k) in zip(date_vecsBB2, Streak_vecs, colors, eachindex(Streak_vecs))
            push!(pltvec, scatter!(ax, year.(date_vecBB), Streak_vec .- L / 2 .+ (k - 1) * L / (K - 1), color=color_))
        end
    end

    isnothing(label) ? nothing : Legend(fig[1:2, 3], pltvec, label)

    return fig
end


function Plot_Freeze_Risk_Bar(TN_vec, dates_vec_TN, date_vecBB;
    CPO=(8, 1),
    color=nothing,
    label=nothing,
    size=(800, 400),
    threshold=-2)

    FreezingRiskBB(BB) = FreezingRisk(TN_vec, dates_vec_TN, BB, CPO=CPO, threshold=threshold)
    Streak_vec = FreezingRiskBB.(date_vecBB)
    Streak_vec, date_vecBB2 = Streak_vec[Streak_vec.>0], date_vecBB[Streak_vec.>0]

    Ω = 0:maximum(Streak_vec)

    fig = Figure(size=size)

    ax = Axis(fig[1:2, 1:2], yticks=Ω, xticks=year.(date_vecBB2))
    ax.xgridvisible = false
    ax.xticklabelrotation = 65 * (2π)/360
    ax.xlabel = "Year"
    ax.ylabel = "Days"
    ax.title = "Max number of consecutives days with TN ≤ -2°C after budburst"
    ax.titlesize = 17

    println(Streak_vec)

    if isnothing(colors)        
        plt = barplot!(ax, year.(date_vecBB2), Streak_vec)
    else
        plt = barplot!(ax, year.(date_vecBB2), Streak_vec, color=color)
    end

    isnothing(label) ? nothing : Legend(fig[1:2, 3], [plt], [label])

    return fig
end

function Plot_Freeze_Risk_Bar(temp::TN, date_vecBB;
    CPO=(8, 1),
    color=nothing,
    label=nothing,
    size=(800, 400),
    threshold=-2)
    return (Plot_Freeze_Risk_Bar(temp.df.TN, temp.df.DATE, date_vecBB;
    CPO=CPO,
    color=color,
    label=label,
    size=size,
    threshold=threshold))
end

# using CairoMakie
# barplot([1,2,5,7],[8,8,8,8.])