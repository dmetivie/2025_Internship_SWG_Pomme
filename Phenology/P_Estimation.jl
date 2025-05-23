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