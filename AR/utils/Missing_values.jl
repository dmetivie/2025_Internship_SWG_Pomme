include("Periodicity.jl")

"""
    Mulinsert!(x_vec::Vector,y_vec_index::Vector{Int},y_vec::Vector)

Inserts the values in y_vec in x_vec at their respective indexes indicated in y_vec_index.
"""
function Mulinsert!(x_vec::Vector,y_vec_index::Vector{Int},y_vec::Vector)
    for (y_index,y) in zip(y_vec_index,y_vec)
        insert!(x_vec,y_index,y)
    end
    return x_vec
end

"""
    Mulfind(t_vec::Vector,Y::Vector)

Find the indexes of the values in t_vec in the vector Y.
"""
function Mulfind(t_vec::Vector,Y::Vector)
    f(t)=findfirst(x->x==t,Y)
    return f.(t_vec)
end
Mulfind(t_vec::Vector,Y::StepRange)=Mulfind(t_vec,collect(Y))

"""
    ImputeMissingValues!(x_vec::Vector,date_vec::Vector,median_::Bool=false)

Computes the average (or median) value of each day of the year (for example the first element is the average value of the all 1st January)
and then imputes the missing days with them. The series x_vec must be undrifted.
"""
function ImputeMissingValues!(x_vec::Vector,date_vec::Vector,median_::Bool=false)
    Days_list=[[] for _ in 1:366]
    for (i,temp) in enumerate(x_vec)
        push!(Days_list[n2t(i,date_vec[1])],temp)
    end
    typical_year=median_ ? median.(Days_list) : mean.(Days_list)
    Missing_days=[date_ for date_ in date_vec[1]:date_vec[end] if date_ ∉ date_vec]
    Missing_days_index=Mulfind(Missing_days,date_vec[1]:date_vec[end])
    Output=(Mulinsert!(x_vec,Missing_days_index,typical_year[n2t.(Missing_days)]),
            Mulinsert!(date_vec,Missing_days_index,Missing_days))
    println("$(length(Missing_days)) days imputated into the series")
    return Output
end
ImputeMissingValues!(x_vec::Vector,date_vec::StepRange,median_::Bool=false)=ImputeMissingValues!(x_vec,collect(date_vec),median_)