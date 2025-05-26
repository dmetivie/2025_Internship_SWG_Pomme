include("Prev2.jl")

function Apple_Phenology_Estimation(x::AbstractVector, #tip : put all arguments into one structure
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
    for date_ in date_vec
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            state = 1
        end
        if state == 1 #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumact += Rc(x[findfirst(date_vec .== date_)], chilling_model)
            if sumact > chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
                push!(DB_date_vec, date_)
                state = 2
                sumact = 0.
            end
        end
        if state == 2 #For forcing, it's the same logic, and in the end we get the budburst date.
            sumact += Rf(x[findfirst(date_vec .== date_)], forcing_model)
            if sumact > forcing_target
                push!(BB_vec, date_)
                state = 0
                sumact = 0.
            end
        end
    end
    return DB_date_vec, BB_vec
end


function Apple_Phenology_Estimation(temp::AbstracTemperature;
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    return Apple_Phenology_Estimation(temp.df[:, 2],
        temp.df.DATE,
        CPO=CPO,
        chilling_model=chilling_model,
        chilling_target=chilling_target,
        forcing_model=forcing_model,
        forcing_target=forcing_target)
end

ScaleDate(date_::Date, CPO=(10, 30)) = (dayofyear_Leap(date_) - dayofyear_Leap(Date(0, CPO[1], CPO[2]) - Day(1)) + 366) % 366
ScaleDate(nt2::Real, CPO=(10, 30)) = (nt2 - dayofyear_Leap(Date(0, CPO[1], CPO[2]) - Day(1)) + 366) % 366

Month_vec2 = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

first_of_month(m::Integer) = Date(0, m)
fifteen_of_month(m::Integer) = Date(0, m, 15)

name_first_of_month(m::Integer) = Month_vec2[m] * ",1ˢᵗ"
name_fifteen_of_month(m::Integer) = Month_vec2[m] * ",15ᵗʰ"

function Plot_Pheno_Dates(date_vecs, CPO; title=nothing, labelvec=nothing)

    #If date_vecs is one series, it's transformed into a 1-length vector containing this series
    if typeof(date_vecs[1]) == Date
        isnothing(labelvec) ? date_vecs = [date_vecs] : (date_vecs, labelvec) = ([date_vecs], [labelvec])
    end

    ScaleDateCPO(date_vec) = ScaleDate(date_vec, CPO)
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

    y_min = ScaleDate(Date(0, month(Conc_date_vecs[argmin(Conc_Ref_date_vecs)])), CPO) #y_min : NDSCPO of the first day of the first month
    y_max = ScaleDate(Date(0, month(Conc_date_vecs[argmax(Conc_Ref_date_vecs)] + Month(1))), CPO) #y_max : NDSCPO of the first day of the month after the last month considered

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