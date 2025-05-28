include("Prev2.jl")

# ======= Apple Phenology ====== #    

"""
    From a series of TG x, his dates in date_vec and the parameters of an apple phenology model, return the dormancy break dates and budbirst dates in two vectors respectively.
"""
function Apple_Phenology_Pred(TG_vec::AbstractVector, #tip : put all arguments into one structure
    date_vec::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    DB_date_vec = Date[]
    BB_vec = Date[]
    state = 0 # 0 for summer, 1 for chilling, 2 for forcing
    sumact = 0.
    for (Tg, date_) in zip(TG_vec, date_vec)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            state = 1
        end
        if state == 1 #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumact += Rc(Tg, chilling_model)
            if sumact > chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
                push!(DB_date_vec, date_)
                state = 2
                sumact = 0.
            end
        end
        if state == 2 #For forcing, it's the same logic, and in the end we get the budburst date.
            sumact += Rf(Tg, forcing_model)
            if sumact > forcing_target
                push!(BB_vec, date_)
                state = 0
                sumact = 0.
            end
        end
    end
    return DB_date_vec, BB_vec
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


# ======= Vine Phenology ====== #    

"""
Transforms T*(h,n) (called Th_raw here) into T(h,n) 
"""
Tcorrector(Th_raw, TOBc, TMBc) = (Th_raw - TOBc) * (TOBc <= Th_raw <= TMBc) + (TMBc - TOBc) * (TMBc < Th_raw)

"""
    From a series of TN Tn_vec, a series of TX Tx_vec, their dates in date_vec and the parameters of an vine phenology model, return the dormancy break dates and budbirst dates in two vectors respectively.
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
    state = 0 # 0 for summer, 1 for chilling, 2 for forcing
    sumact = 0.

    locTcorrector(Th_raw) = Tcorrector(Th_raw, T0Bc, TMBc)

    for (Tn,Tx,date_,Tn1) in zip(Tn_vec[1:(end-1)],Tx_vec[1:(end-1)],date_vec[1:(end-1)],Tn_vec[2:end]) #Tn1 = TN(n+1)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            state = 1
        end
        if state == 1 #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumact += Q10^(-(Tx / 10)) + Q10^(-(Tn / 10))
            if sumact > Cc #When the sum is superior to the chilling target, we switch to the second part which is forcing.
                push!(DB_vec, date_)
                state = 2
                sumact = 0.
            end
        end
        if state == 2 #For forcing, it's the same logic, and in the end we get the budburst date.

            #The vector containing T*(h,n) for h in 1:24
            Th_raw_vec = [Tn .+ (1:12) .* ((Tx - Tn) / 12); Tx .- (1:12) .* ((Tx .- Tn1) / 12)]

            sumact += sum(locTcorrector.(Th_raw_vec)) # = Ac(n)

            if sumact > Ghc
                push!(BB_vec, date_)
                state = 0
                sumact = 0.
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
    so it's not appropriate if we want to return the NDSCPO before the dormancy break, which can happen in December for example. 
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

function Plot_Pheno_Dates(date_vecs, CPO; title=nothing, labelvec=nothing, BB=false)

    #If date_vecs is one series, it's transformed into a 1-length vector containing this series
    if typeof(date_vecs[1]) == Date
        isnothing(labelvec) ? date_vecs = [date_vecs] : (date_vecs, labelvec) = ([date_vecs], [labelvec])
    end

    ScaleDateCPO(date_) = ScaleDate(date_, CPO, BB) #If we consider the budbirst date, we are sure that the CPO happened the year before.

    #We get the number of days since the CPO for each date. (NDSCPO)
    Ref_date_vecs = [ScaleDateCPO.(date_vec) for date_vec in date_vecs]

    #We concatanate the dates and the NDSCPO of each series to have the max and the min NDSCPO
    Conc_date_vecs = reduce(vcat, date_vecs)
    Conc_Ref_date_vecs = reduce(vcat, Ref_date_vecs)

    #The months present in each series.
    CurrentMonths = unique(month.(Conc_date_vecs))

    #The dates of first and fifteen day of each month.
    Dates_month = interleave2(first_of_month.(CurrentMonths), fifteen_of_month.(CurrentMonths))
    Names_month = interleave2(name_first_of_month.(CurrentMonths), name_fifteen_of_month.(CurrentMonths)) #And their string associated for the tickslabel.

    y_min = ScaleDateCPO(Date(0, month(Conc_date_vecs[argmin(Conc_Ref_date_vecs)]))) #y_min : NDSCPO of the first day of the first month.
    y_max = ScaleDateCPO(Date(0, month(Conc_date_vecs[argmax(Conc_Ref_date_vecs)] + Month(1)))) #y_max : NDSCPO of the first day of the month after the last month considered.

    last_month_str = name_first_of_month(month(Conc_date_vecs[argmax(Conc_Ref_date_vecs)] + Month(1))) #And his string associated

    fig = Figure(size=(700, 600))

    ax = Axis(fig[1:2, 1:2], yticks=([ScaleDateCPO.(Dates_month); y_max], [Names_month; last_month_str])) #ytickslabel = NDSCPO of the dates of first and fifteen day of each month and y_max.
    ax.limits = (nothing, [y_min, y_max])
    ax.xlabel = "Year"

    isnothing(title) ? nothing : ax.title = "$(title) dates for each year"

    ax2 = Axis(fig[1:2, 1:2])
    ax2.ylabelpadding = 65.0
    ax2.ylabel = "Date"
    ax2.yticklabelsvisible = false
    ax2.yticksvisible = false
    ax2.ygridvisible = false
    ax2.xticksvisible = false
    ax2.xgridvisible = false
    ax2.xticklabelsvisible = false

    pltvec = Plot[]
    for (date_vec, Ref_date_vec) in zip(date_vecs, Ref_date_vecs)
        push!(pltvec, lines!(ax, year.(date_vec), Ref_date_vec))
    end

    isnothing(labelvec) ? nothing : Legend(fig[3, 1:2], pltvec, labelvec)

    return fig
end