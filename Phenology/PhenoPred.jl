include("Prev2.jl")

# ======= Apple Phenology ====== #    

"""
    From a series of TG x, his dates in date_vec and the parameters of an apple phenology model, return the Endodormancy break dates and Budburst dates in two vectors respectively.
"""
function Apple_Phenology_Pred(TG_vec::AbstractVector, #tip : put all arguments into one structure
    date_vec::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    DB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.
    for (Tg, date_) in zip(TG_vec, date_vec)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            chilling = true
            sumchilling = 0.
        end
        if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumchilling += Rc(Tg, chilling_model)
            if sumchilling > chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
                push!(DB_vec, date_)
                chilling = false
                forcing = true
                sumforcing = 0.
            end
        end
        if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
            sumforcing += Rf(Tg, forcing_model)
            if sumforcing > forcing_target
                push!(BB_vec, date_)
                forcing = false
            end
        end
    end
    return DB_vec, BB_vec
end


function Apple_Phenology_Pred(temp::AbstracTemperature;
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    return Apple_Phenology_Pred(temp.df[:, 2],
        temp.df.DATE,
        CPO=CPO,
        chilling_model=chilling_model,
        chilling_target=chilling_target,
        forcing_model=forcing_model,
        forcing_target=forcing_target)
end

function Apple_Phenology_Pred(file_TG::String;
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    return Apple_Phenology_Pred(initTG(file_TG),
        CPO=CPO,
        chilling_model=chilling_model,
        chilling_target=chilling_target,
        forcing_model=forcing_model,
        forcing_target=forcing_target)
end


# ======= Vine Phenology ====== #    

"""
Transforms T*(h,n) (called Th_raw here) into T(h,n) 
"""
Tcorrector(Th_raw, TOBc, TMBc) = (Th_raw - TOBc) * (TOBc <= Th_raw <= TMBc) + (TMBc - TOBc) * (TMBc < Th_raw)

"""
    From a series of TN Tn_vec, a series of TX Tx_vec, their dates in date_vec and the parameters of an vine phenology model, return the Endodormancy break dates and Budburst dates in two vectors respectively.
"""
function Vine_Phenology_Pred(Tn_vec::AbstractVector, #tip : put all arguments into one structure
    Tx_vec::AbstractVector,
    date_vec::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.)

    DB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.

    locTcorrector(Th_raw) = Tcorrector(Th_raw, T0Bc, TMBc)

    for (Tn, Tx, date_, Tn1) in zip(Tn_vec[1:(end-1)], Tx_vec[1:(end-1)], date_vec[1:(end-1)], Tn_vec[2:end]) #Tn1 = TN(n+1)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            chilling = true
            sumchilling = 0.
        end
        if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumchilling += Q10^(-(Tx / 10)) + Q10^(-(Tn / 10))
            if sumchilling > Cc #When the sum is superior to the chilling target, we switch to the second part which is forcing.
                push!(DB_vec, date_)
                chilling = false
                forcing = true
                sumforcing = 0.
            end
        end
        if forcing #For forcing, it's the same logic, and in the end we get the budburst date.

            #The vector containing T*(h,n) for h in 1:24
            Th_raw_vec = [Tn .+ (1:12) .* ((Tx - Tn) / 12); Tx .- (1:12) .* ((Tx - Tn1) / 12)]

            sumforcing += sum(locTcorrector.(Th_raw_vec)) # = Ac(n)

            if sumforcing > Ghc
                push!(BB_vec, date_)
                forcing = false
            end
        end
    end
    return DB_vec, BB_vec
end

function Vine_Phenology_Pred(
    file_TN::String,
    file_TX::String;
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.)

    TNdf = truncate_MV(extract_series(file_TN))
    TXdf = truncate_MV(extract_series(file_TX))
    if TNdf.DATE != TXdf.DATE #If the timelines are differents, we take the common timeline of the two series.
        date_vec = max(TNdf.DATE[1], TXdf.DATE[1]):min(TNdf.DATE[end], TXdf.DATE[end])
        TN_vec = TNdf.TN[findfirst(TNdf.DATE .== date_vec[1]):findfirst(TNdf.DATE .== date_vec[end])]
        TX_vec = TXdf.TX[findfirst(TXdf.DATE .== date_vec[1]):findfirst(TXdf.DATE .== date_vec[end])]
        return Vine_Phenology_Pred(TN_vec, TX_vec, date_vec, CPO=CPO, Q10=Q10, Cc=Cc, T0Bc=T0Bc, TMBc=TMBc, Ghc=Ghc)
    else
        return Vine_Phenology_Pred(TNdf.TN, TXdf.TX, TNdf.DATE, CPO=CPO, Q10=Q10, Cc=Cc, T0Bc=T0Bc, TMBc=TMBc, Ghc=Ghc)
    end
end


function Vine_Phenology_Pred(M::VinePhenoModel)

    DB_vec = Date[]
    BB_vec = Date[]
    state = 0 # 0 for summer, 1 for chilling, 2 for forcing
    sumact = 0.

    locTcorrector(Th_raw) = Tcorrector(Th_raw, M.T0Bc, M.TMBc)

    for i in 1:(length(M.DATE)-1)
        if (month(M.DATE[i]), day(M.DATE[i])) == M.CPO #If it's the start of the chilling 
            state = 1
        end
        if state == 1 #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumact += M.Q10^(-(M.TX_vec[i] / 10)) + M.Q10^(-(M.TN_vec[i] / 10))
            if sumact > M.Cc #When the sum is superior to the chilling target, we switch to the second part which is forcing.
                push!(DB_vec, M.DATE[i])
                state = 2
                sumact = 0.
            end
        end
        if state == 2 #For forcing, it's the same logic, and in the end we get the budburst date.

            #The vector containing T*(h,n) for h in 1:24
            Th_raw_vec = [M.TN_vec[i] .+ (1:12) .* ((M.TX_vec[i] - M.TN_vec[i]) / 12); M.TX_vec[i] .- (1:12) .* ((M.TX_vec[i] .- M.TN_vec[i+1]) / 12)]

            sumact += sum(locTcorrector.(Th_raw_vec)) # = Ac(n)

            if sumact > M.Ghc
                push!(BB_vec, M.DATE[i])
                state = 0
                sumact = 0.
            end
        end
    end
    return DB_vec, BB_vec
end



# ======= Plot ====== #    

"""
    Return the number of days since the CPO (chilling period onset). 
    If previous_year=true, we consider that the CPO happened the year before whatever the situation,
    so it's not appropriate if we want to return the NDSCPO before the Endodormancy break, which can happen in December for example. 
"""
function ScaleDate(date_::Date, CPO=(8, 1), previous_year=false)
    value_ = date_ - Date(year(date_) - (previous_year ? 1 : 0), CPO[1], CPO[2]) #The number days to go to the date_ from the CPO
    return value_ > Day(0) ? Dates.value(value_) : Dates.value(date_ - Date(year(date_) - 1, CPO[1], CPO[2])) #If this number < 0 (the CPO happened after date_, we automatically consider the CPO of the year before.)
end

Month_vec2 = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

first_of_month(m::Integer) = Date(0, m)
fifteen_of_month(m::Integer) = Date(0, m, 15)

name_first_of_month(m::Integer) = Month_vec2[m] * ",1ˢᵗ"
name_fifteen_of_month(m::Integer) = Month_vec2[m] * ",15ᵗʰ"



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





function Plot_Pheno_Dates_DB_BB(date_vecDB, date_vecBB, CPO; sample_DB=nothing, sample_BB=nothing, station_name="")

    fig = Figure(size=(900, 400))

    ScaleDateDB(date_) = ScaleDate(date_, CPO, false)
    ScaleDateBB(date_) = ScaleDate(date_, CPO, true)

    NDSCPO_DB = ScaleDateDB.(date_vecDB)
    NDSCPO_BB = ScaleDateBB.(date_vecBB)

    #We concatanate the dates of each series to have the max and the min NDSCPO
    Conc_date_vecs_DB = isnothing(sample_DB) ? reduce(vcat, date_vecDB) : [reduce(vcat, date_vecDB); reduce(vcat, sample_DB)]
    Conc_date_vecs_BB = isnothing(sample_BB) ? reduce(vcat, date_vecBB) : [reduce(vcat, date_vecBB); reduce(vcat, sample_BB)]

    #The months presents in each series.
    # CurrentMonths = unique([month.(Conc_date_vecs_DB) ; month.(Conc_date_vecs_BB)])
    # 12 ∈ CurrentMonths && 1 ∉ CurrentMonths ? push!(1,CurrentMonths) : nothing


    # Maxmonth = month(Conc_date_vecs_BB[argmax(ScaleDateBB.(Conc_date_vecs_BB))] + Month(1)) #The month after the month of the highest NDSCPO
    # push!(CurrentMonths,Maxmonth)

    # CurrentMonths = unique([CurrentMonths ; ])

    #The dates of the first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(1:12), fifteen_of_month.(1:12))
    Names_month = interleave2(name_first_of_month.(1:12), name_fifteen_of_month.(1:12)) #Their string associated for the tickslabel.
    NDSCPO_month = ScaleDateDB.(Dates_month) #And their NDSCPO

    NDSCPO_inf=maximum(NDSCPO_month[NDSCPO_month .<= minimum(ScaleDateDB.(Conc_date_vecs_DB))]) #The optimal NDSCPO_month to minimise the true NDSCPO.
    NDSCPO_sup=minimum(NDSCPO_month[NDSCPO_month .>= maximum(ScaleDateDB.(Conc_date_vecs_BB))]) #The optimal NDSCPO_month to maximise the true NDSCPO.

    Dates_month = Dates_month[NDSCPO_sup .>= NDSCPO_month .>=  NDSCPO_inf]
    Names_month = Names_month[NDSCPO_sup .>= NDSCPO_month .>=  NDSCPO_inf]
    NDSCPO_month = NDSCPO_month[NDSCPO_sup .>= NDSCPO_month .>=  NDSCPO_inf]

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
