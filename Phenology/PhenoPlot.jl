include("Phenopred.jl")


# ========= PhenoDatesPlot ========= #

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





function Plot_Pheno_Dates_DB_BB(date_vecDB::Vector{Date}, date_vecBB::Vector{Date}, CPO; sample_DB=nothing, sample_BB=nothing, station_name="", YearCut=nothing, save_file=nothing, loaded_data=nothing)

    if !isnothing(loaded_data)
        both_dict = load(loaded_data)
        EB_dict = both_dict["EB"]
        BB_dict = both_dict["BB"]
    end

    fig = Figure(size=(900, 400))

    ScaleDateDB(date_) = ScaleDate(date_, CPO, false)
    ScaleDateBB(date_) = ScaleDate(date_, CPO, true)

    NDSCPO_DB = ScaleDateDB.(date_vecDB) #NDSCPO : Number of dates since chilling period onset
    NDSCPO_BB = ScaleDateBB.(date_vecBB)

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs_DB = isnothing(sample_DB) ? date_vecDB : ([date_vecDB; reduce(vcat, sample_DB)])
    Conc_date_vecs_BB = isnothing(sample_BB) ? date_vecBB : ([date_vecBB; reduce(vcat, sample_BB)])

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(1:12), fifteen_of_month.(1:12))
    Names_month = interleave2(name_first_of_month.(1:12), name_fifteen_of_month.(1:12)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateDB.(Dates_month) #And their NDSCPO

    if isnothing(loaded_data)
        NDSCPO_inf = maximum(NDSCPO_month[NDSCPO_month.<=minimum(ScaleDateDB.(Conc_date_vecs_DB))]) #The optimal NDSCPO_month to minimise the true NDSCPO.
        NDSCPO_sup = minimum(NDSCPO_month[NDSCPO_month.>=maximum(ScaleDateDB.(Conc_date_vecs_BB))]) #The optimal NDSCPO_month to maximise the true NDSCPO.
    else
        raw_NDSCPO_inf = minimum([ScaleDateDB.(Conc_date_vecs_DB); EB_dict["NDSCPO"]; EB_dict["minimum"]])
        NDSCPO_inf = maximum(NDSCPO_month[NDSCPO_month.<=raw_NDSCPO_inf])
        raw_NDSCPO_sup = maximum([ScaleDateDB.(Conc_date_vecs_BB); BB_dict["NDSCPO"]; BB_dict["maximum"]])
        NDSCPO_sup = minimum(NDSCPO_month[NDSCPO_month.>=raw_NDSCPO_sup])
    end

    Names_month = Names_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]
    NDSCPO_month = NDSCPO_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]

    # y_max = ScaleDateBB(Date(0, month(Dates_month[argmax(NDSCPO_month)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    ax = Axis(fig[1:4, 1:4], yticks=(NDSCPO_month, Names_month)) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = (nothing, [NDSCPO_inf, NDSCPO_sup])
    ax.xlabel = "Year"
    ax.ylabel = "Date"
    ax.ylabelpadding = 5.

    ax.title = "Predicted Endodormancy Break and Budburst dates for each year, $(station_name)"

    pltvec = Plot[]

    inyear(date_, year_) = year(date_ + min(Month(2), Year(1) - Month(CPO[1]) - Day(CPO[2]))) == year_
    #For exemple is the EB happens the 15/12/2010, I consider that it belongs to the year 2011, so I had the time to reach 2011.
    #If the CPO is very early (eg the 1st of august 2010) and the BB is very late (e.g the 15th of august 2010), I don't want to consider this BB
    #to belong to year 2011 so I consider EB to belongs to 2011 at least two months before 2011 not before.
    Dictionnaries = (Dict(), Dict())
    for (sample_, colors, SD_func, Dict_) in zip([sample_DB, sample_BB], [[("#e5ca20", 0.2), ("#e5ca20", 0.5)], [("#009bff", 0.2), ("#009bff", 0.5)]], [ScaleDateDB, ScaleDateBB], Dictionnaries)
        if !isnothing(sample_)
            Conc_sets = reduce(vcat, sample_)

            years_ = unique(year.(Conc_sets + min(Month(2), Year(1) - Month(CPO[1]) - Day(CPO[2]))))

            DictYearsVec = [SD_func.(Conc_sets[inyear.(Conc_sets, year_)]) for year_ in years_]
            if isnothing(save_file)
                push!(pltvec, band!(ax, years_, minimum.(DictYearsVec), maximum.(DictYearsVec), color=colors[1]))
                push!(pltvec, band!(ax, years_, quantile.(DictYearsVec, 0.25), quantile.(DictYearsVec, 0.75), color=colors[2]))
            else
                Dict_["minimum"] = minimum.(DictYearsVec)
                Dict_["maximum"] = maximum.(DictYearsVec)
                Dict_["q25"] = quantile.(DictYearsVec, 0.25)
                Dict_["q75"] = quantile.(DictYearsVec, 0.75)
                push!(pltvec, band!(ax, years_, Dict_["minimum"], Dict_["maximum"], color=colors[1]))
                push!(pltvec, band!(ax, years_, Dict_["q25"], Dict_["q75"], color=colors[2]))
            end
        end
    end

    #Plot data from loaded file
    if !isnothing(loaded_data)
        for (dict_, color_) in zip([EB_dict, BB_dict], ["brown4", "magenta"])
            years = dict_["years"]
            push!(pltvec, lines!(ax, years, dict_["minimum"], color=color_, linestyle=(:dot, :loose)))
            push!(pltvec, lines!(ax, years, dict_["maximum"], color=color_, linestyle=(:dot, :loose)))
            push!(pltvec, lines!(ax, years, dict_["q25"], color=color_, linestyle=(:dash, :dense)))
            push!(pltvec, lines!(ax, years, dict_["q75"], color=color_, linestyle=(:dash, :dense)))
            push!(pltvec, lines!(ax, years, dict_["NDSCPO"], color=color_,))
        end
    end

    #NDSCPO plots
    push!(pltvec, lines!(ax, year.(date_vecDB + min(Month(2), Year(1) - Month(CPO[1]) - Day(CPO[2]))), NDSCPO_DB, color="#ff6600"))
    push!(pltvec, lines!(ax, year.(date_vecBB), NDSCPO_BB, color="green"))
    
    if !isnothing(save_file)
        Dictionnaries[1]["years"] = year.(date_vecDB + min(Month(2), Year(1) - Month(CPO[1]) - Day(CPO[2])))
        Dictionnaries[1]["NDSCPO"] = NDSCPO_DB
        Dictionnaries[2]["years"] = year.(date_vecBB)
        Dictionnaries[2]["NDSCPO"] = NDSCPO_BB
        save(save_file, "EB", Dictionnaries[1], "BB", Dictionnaries[2])
    end

    #Cut
    isnothing(YearCut) ? nothing : lines!(ax, [YearCut, YearCut], [NDSCPO_inf, NDSCPO_sup], color="purple")

    #Legend
    if isnothing(loaded_data)
        Legend(fig[3:4, 5], pltvec[[1, 2, 5]], ["Min-Max interval of predictions\non simulated temperatures",
                "Quartile interval of predictions\non simulated temperatures",
                "Predictions on recorded\ntemperatures in $(station_name)"], "Endodormancy break", framevisible=false)

        Legend(fig[1:2, 5], pltvec[[3, 4, 6]], ["Min-Max interval of predictions\non simulated temperatures",
                "Quartile interval of predictions\non simulated temperatures",
                "Predictions on recorded\ntemperatures in $(station_name)"], "Budburst", framevisible=false)
    else
        Legend(fig[3:4, 5], pltvec[[1, 2, 15, 9]], ["Min-Max interval of predictions\non simulated temperatures",
                "Quartile interval of predictions\non simulated temperatures", "Predictions on $(station_name) simulation", "Predictions on recorded temperatures"], "Endodormancy break", framevisible=false)

        Legend(fig[1:2, 5], pltvec[[3, 4, 16, 14]], ["Min-Max interval of predictions\non simulated temperatures",
                "Quartile interval of predictions\non simulated temperatures",
                "Predictions on $(station_name) simulation", "Predictions on recorded temperatures"], "Budburst", framevisible=false)
    end
    return fig
end



# ["Simulated EB\nMin-Max interval",
#         "Simulated EB\n[0.25 ; 0.75]\nquantile interval",
#         "EB pred from recorded\ntemperatures in $(station_name)"]

function Plot_Pheno_Dates_DB_BB(date_vecsDB, date_vecsBB, CPO;
    DB_colors=nothing,
    BB_colors=nothing,
    DB_label=nothing,
    BB_label=nothing,
    dashindexes=Integer[],
    size=(800, 400),
    breakpoints=true,
    comments="")

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

    ax.title = "Predicted Endodormancy Break and Budburst dates for each year $(comments)"

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
    isnothing(DB_label) ? nothing : Legend(fig[3:4, 5], pltvec[1:length(date_vecsDB)], DB_label, "Endodormancy break", framevisible=false)
    isnothing(BB_label) ? nothing : Legend(fig[1:2, 5], pltvec[length(date_vecsDB)+1:end], BB_label, "Budburst", framevisible=false)

    return fig
end

# ========= Freezing Risk ========= #

function Plot_Freeze_Risk(TN_vecs, dates_vecs_TN, date_vecsBB;
    CPO=(8, 1),
    colors=nothing,
    label=nothing,
    size=(800, 400),
    threshold=-2)

    Counter_vecs, date_vecsBB2 = Vector[], Vector[]

    for (TN_vec, dates_vec_TN, date_vecBB) in zip(TN_vecs, dates_vecs_TN, date_vecsBB)
        FreezingRiskBB(BB) = FreezingRisk(TN_vec, dates_vec_TN, BB, CPO=CPO, threshold=threshold)
        Counter_vec = FreezingRiskBB.(date_vecBB)
        Counter_vec, date_vecBB2 = Counter_vec[Counter_vec.>0], date_vecBB[Counter_vec.>0]
        push!(Counter_vecs, Counter_vec)
        push!(date_vecsBB2, date_vecBB2)
    end

    Ω = sort(unique(reduce(vcat, Counter_vecs)))

    fig = Figure(size=size)

    ax = Axis(fig[1:2, 1:2], yticks=Ω)
    ax.xlabel = "Year"
    ax.ylabel = "Days"
    ax.title = "Number of days with TN ≤ -2°C after budburst"

    pltvec = Plot[]
    K = length(Counter_vecs)
    L = 0.05 * K

    if isnothing(colors)
        for (date_vecBB, Counter_vec, k) in zip(date_vecsBB2, Counter_vecs, eachindex(Counter_vecs))
            push!(pltvec, scatter!(ax, year.(date_vecBB), Counter_vec - L / 2 + (k - 1) * L / (K - 1)))
        end
    else
        for (date_vecBB, Counter_vec, color_, k) in zip(date_vecsBB2, Counter_vecs, colors, eachindex(Counter_vecs))
            push!(pltvec, scatter!(ax, year.(date_vecBB), Counter_vec .- L / 2 .+ (k - 1) * L / (K - 1), color=color_))
        end
    end

    isnothing(label) ? nothing : Legend(fig[1:2, 3], pltvec, label, framevisible=false)

    return fig
end


function Plot_Freeze_Risk_Bar(TN_vec, dates_vec_TN, date_vecBB;
    CPO=(8, 1),
    color=nothing,
    label=nothing,
    size=(800, 400),
    threshold=-2)

    FreezingRiskBB(BB) = FreezingRisk(TN_vec, dates_vec_TN, BB, CPO=CPO, threshold=threshold)
    Counter_vec = FreezingRiskBB.(date_vecBB)
    Counter_vec, date_vecBB2 = Counter_vec[Counter_vec.>0], date_vecBB[Counter_vec.>0]

    Ω = 0:maximum(Counter_vec)

    fig = Figure(size=size)

    ax = Axis(fig[1:2, 1:2], yticks=Ω, xticks=year.(date_vecBB2))
    ax.xgridvisible = false
    ax.xticklabelrotation = 65 * (2π) / 360
    ax.xlabel = "Year"
    ax.ylabel = "Days"
    ax.title = "Number of days with TN ≤ -2°C after budburst"
    ax.titlesize = 17

    println(Counter_vec)

    if isnothing(colors)
        plt = barplot!(ax, year.(date_vecBB2), Counter_vec)
    else
        plt = barplot!(ax, year.(date_vecBB2), Counter_vec, color=color)
    end

    isnothing(label) ? nothing : Legend(fig[1:2, 3], [plt], [label], framevisible=false)

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


function Plot_Freeze_Risk_heatmap(TN_vecs, Date_vec, date_vecsBB; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    Mat2, year_vec, days_vec = FreezingRiskMatrix(TN_vecs, Date_vec, date_vecsBB; threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)

    stepped_year = minimum(year_vec):10:maximum(year_vec)
    interesting_year = year_vec[[any(Mat2[days_vec.>0, year-minimum(year_vec)+1] .>= 0.015) for year in year_vec]]
    interesting_days = days_vec[days_vec.>0]

    fig = Figure(size=(700, 350))
    ax = Axis(fig[1, 1],
        xticks=([stepped_year; interesting_year]),
        xticklabelrotation=65 * 2π / 360,
        xlabel="Year",
        yticks=interesting_days,
        ylabel="Days",
        title="Annual frequency of number of days with TN ≤ -2°C\nafter budburst, for simulated temperatures",
        titlesize=15
    )

    heatplt = heatmap!(ax, year_vec, interesting_days, transpose(Mat2[days_vec.>0, :]))
    Colorbar(fig[:, end+1], heatplt)

    return fig
end


function Plot_Freeze_Risk_sample(TN_vecs, Date_vec, date_vecsBB; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    Mat, year_vec, days_vec = FreezingRiskMatrix(TN_vecs, Date_vec, date_vecsBB; threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)
    Mat_freq = Mat / length(TN_vecs)

    Dist = [DiscreteNonParametric(0:(size(Mat_freq)[1]-1), Mat_freq[:, j]) for j in 1:size(Mat_freq)[2]]

    fig = Figure(size=(1300, 400))
    ax1, plt = lines(fig[1, 1], year_vec, mean.(Dist))
    ax1.xlabel = "Year"
    ax1.ylabel = "Number of days"
    ax1.title = "Annual mean"

    ax2, plt = lines(fig[1, 2], year_vec, std.(Dist))
    ax2.xlabel = "Year"
    ax2.title = "Annual variance"

    ax3, plt = lines(fig[1, 3], year_vec, findlast.(x -> x > 0, eachcol(Mat)) .- 1)
    ax3.xlabel = "Year"
    ax3.title = "Annual Max"

    return fig
end

function Plot_Freeze_Risk_distribution(TN_vecs, Date_vec, date_vecsBB, years; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    Mat, year_vec, days_vec = FreezingRiskMatrix(TN_vecs, Date_vec, date_vecsBB; threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)
    Mat_freq = Mat / length(TN_vecs)

    Dist = [DiscreteNonParametric(0:(size(Mat_freq)[1]-1), Mat_freq[:, j]) for j in 1:size(Mat_freq)[2]]

    fig = Figure()
    ax = Axis(fig[1, 1])
    ylims!(ax, [1e-5, 1])
    ax.yscale = log10
    ax.ylabel = "p"
    ax.xlabel = "Days"

    pltvec = Plot[]
    for year_ in years
        push!(pltvec, lines!(ax, days_vec, (pdf(Dist[findfirst(x -> x == year_, year_vec)], days_vec))))
    end
    Legend(fig[1, 2], pltvec, string.(years))
    return fig
end


# ========= Histograms ========= #

function PlotHistogram(date_vecDB::Vector{Date}, date_vecBB::Vector{Date}, CPO, year; sample_DB=nothing, sample_BB=nothing, station_name="", LineHeight=0.15, stationlegend=false, horline=true, PlotQuantile=false)
    inyear(date_) = Date(year - 1, CPO[1], CPO[2]) + Month(1) .<= date_ .< Date(year, CPO[1], CPO[2]) + Month(1)
    DB, BB = date_vecDB[findfirst(inyear, date_vecDB)], date_vecBB[findfirst(inyear, date_vecBB)]

    fig = stationlegend ? Figure(size=(800, 600)) : Figure(size=(900, 300))

    ScaleDateDB(date_) = ScaleDate(date_, CPO, false)
    ScaleDateBB(date_) = ScaleDate(date_, CPO, true)

    NDSCPO_DB = ScaleDateDB(DB)
    NDSCPO_BB = ScaleDateBB(BB)

    sample_DB_year = reduce(vcat, sample_DB)
    sample_DB_year = sample_DB_year[inyear.(sample_DB_year)]
    sample_BB_year = reduce(vcat, sample_BB)
    sample_BB_year = sample_BB_year[inyear.(sample_BB_year)]

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs_DB = [[DB]; sample_DB_year]
    Conc_date_vecs_BB = [[BB]; sample_BB_year]

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(1:12), fifteen_of_month.(1:12))
    Names_month = interleave2(name_first_of_month.(1:12), name_fifteen_of_month.(1:12)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateDB.(Dates_month) #And their NDSCPO

    NDSCPO_inf = maximum(NDSCPO_month[NDSCPO_month.<=minimum(ScaleDateDB.(Conc_date_vecs_DB))]) #The optimal NDSCPO_month to minimise the true NDSCPO.
    NDSCPO_sup = minimum(NDSCPO_month[NDSCPO_month.>=maximum(ScaleDateDB.(Conc_date_vecs_BB))]) #The optimal NDSCPO_month to maximise the true NDSCPO.

    Names_month = Names_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]
    NDSCPO_month = NDSCPO_month[NDSCPO_sup.>=NDSCPO_month.>=NDSCPO_inf]

    # y_max = ScaleDateBB(Date(0, month(Dates_month[argmax(NDSCPO_month)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    ax = Axis(fig[1, 1:2], xticks=(NDSCPO_month, Names_month)) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = ([NDSCPO_inf, NDSCPO_sup], nothing)
    ax.xlabel = "Date"
    ax.ylabel = "Frequency"
    ax.xticklabelrotation = 45
    ax.xlabelpadding = 5.

    ax.title = "Histograms of predicted EB and BB dates for the year $(year) in $(station_name)"
    ax.titlesize = 17

    pltvec = Plot[]

    SDDB = ScaleDateDB.(sample_DB_year)
    SDBB = ScaleDateBB.(sample_BB_year)

    push!(pltvec, hist!(ax, SDDB, color="#e5ca20", strokewidth=1, strokecolor=:black, normalization=:pdf))
    push!(pltvec, lines!(ax, [ScaleDateDB(DB), ScaleDateDB(DB)], [0., LineHeight], color="#ff6600"))
    push!(pltvec, hist!(ax, SDBB, color="#009bff", strokewidth=1, strokecolor=:black, normalization=:pdf))
    push!(pltvec, lines!(ax, [ScaleDateBB(BB), ScaleDateBB(BB)], [0., LineHeight], color="green"))
    if PlotQuantile
        push!(pltvec, lines!(ax, [quantile(SDDB, 0.25), quantile(SDDB, 0.25)], [0., LineHeight], color="black"))
        push!(pltvec, lines!(ax, [quantile(SDDB, 0.75), quantile(SDDB, 0.75)], [0., LineHeight], color="black"))
        push!(pltvec, lines!(ax, [quantile(SDBB, 0.25), quantile(SDBB, 0.25)], [0., LineHeight], color="black"))
        push!(pltvec, lines!(ax, [quantile(SDBB, 0.75), quantile(SDBB, 0.75)], [0., LineHeight], color="black"))
    end

    horline ? lines!(ax, [NDSCPO_inf, NDSCPO_sup], [-0.0015, -0.0015], color="purple", linewidth=4) : nothing

    #Legend
    if stationlegend
        Legend(fig[2, 1], pltvec[1:2], ["Simulated EB Histogram", "Predicted EB in $(station_name)"], framevisible=false)
        Legend(fig[2, 2], pltvec[3:4], ["Simulated BB Histogram", "Predicted BB in $(station_name)"], framevisible=false)
    else
        Legend(fig[1, 3], pltvec[[1, 3]], ["Simulated EB Histogram", "Simulated BB Histogram"], framevisible=false)
    end

    return fig
end