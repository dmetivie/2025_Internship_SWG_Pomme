include("Prev2.jl")

function Phenology_Estimation(x::AbstractVector,
                            date_vec::AbstractVector{Date}; 
                            JED::Tuple{<:Integer, <:Integer} = (10,1),
                            chilling_model::AbstractAction = TriangularAction(1.1, 20.), 
                            chilling_target::AbstractFloat = 56.0, 
                            forcing_model::AbstractAction = ExponentialAction(9.0), 
                            forcing_target::AbstractFloat = 83.58)
    Switch_date_vec = Date[]
    JLD_vec = Date[]
    state = 0 # 0 for summer, 1 for chilling, 2 for forcing
    sumact = 0.
    for date_ in date_vec
        if (month(date_), day(date_)) == JED
            state = 1
        end
        if state == 1
            sumact += Rc(x[findfirst(date_vec .== date_)], chilling_model)
            if sumact > chilling_target
                push!(Switch_date_vec, date_)
                state = 2
                sumact = 0.
            end
        end
        if state == 2
            sumact += Rf(x[findfirst(date_vec .== date_)], forcing_model)
            if sumact > forcing_target
                push!(JLD_vec, date_)
                state = 0
                sumact = 0.
            end
        end
    end
    return Switch_date_vec, JLD_vec
end


function Phenology_Estimation(temp::AbstracTemperature; 
                                JED::Tuple{<:Integer, <:Integer} = (10,1),
                                chilling_model::AbstractAction = TriangularAction(1.1, 20.), 
                                chilling_target::AbstractFloat = 56.0, 
                                forcing_model::AbstractAction = ExponentialAction(9.0), 
                                forcing_target::AbstractFloat = 83.58)
    return Phenology_Estimation(temp.df[:,2],
                                temp.df.DATE,
                                JED=JED,
                                chilling_model=chilling_model,
                                chilling_target=chilling_target,
                                forcing_model=forcing_model,
                                forcing_target=forcing_target)
end




ScaleDate(date_::Date, JED=(10, 1)) = (dayofyear_Leap(date_) - dayofyear_Leap(Date(0, JED[1], JED[2]) - Day(1)) + 366) .% 366
ScaleDate(nt2::Real, JED=(10, 1)) = (nt2 - dayofyear_Leap(Date(0, JED[1], JED[2]) - Day(1)) + 366) .% 366

function Plot_Pheno_Dates(date_vec, title)

    Ref_date_vec = ScaleDate.(date_vec)

    MiddleMonthIndex = (cumsum(DaysPerMonth(0)) .+ cumsum([0; DaysPerMonth(0)])[1:12]) ./ 2
    CurrentMonths = unique(month.(date_vec))

    y_min = ScaleDate(Date(0, month(date_vec[argmin(Ref_date_vec)])))
    y_max = ScaleDate(Date(0, month(date_vec[argmax(Ref_date_vec)] + Month(1))) - Day(1))

    fig = Figure()
    
    ax2 = Axis(fig[1:2, 1:2], yticks=(ScaleDate.(MiddleMonthIndex[CurrentMonths]), Month_vec[CurrentMonths]))
    ax2.limits = (nothing, [y_min, y_max])
    ax2.yticksvisible = false
    ax2.ygridvisible = false
    ax2.xticksvisible = false
    ax2.xgridvisible = false
    ax2.xticklabelsvisible= false

    ax = Axis(fig[1:2, 1:2])
    ax.yticks = [ScaleDate.(cumsum([0; DaysPerMonth(0)])[CurrentMonths] .+ 1); y_max]
    ax.yticklabelsvisible = false
    ax.limits = (nothing, [y_min, y_max])
    ax.xlabel = "Year"
    ax.ylabel = "Date"
    ax.title = "$(title) dates for each year"

    plt = lines!(ax, year.(date_vec), Ref_date_vec)

    return fig
end