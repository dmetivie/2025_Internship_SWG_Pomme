include("Periodicity.jl")

"""
    Mulinsert!(x_vec::AbstractVector,y_vec_index::AbstractVector{Integer},y_vec::AbstractVector)

Inserts the values in y_vec in x_vec at their respective indexes indicated in y_vec_index.
"""
function Mulinsert!(x_vec::AbstractVector, y_vec_index::AbstractVector, y_vec::AbstractVector)
    for (y_index, y) in zip(y_vec_index, y_vec)
        insert!(x_vec, y_index, y)
    end
    return x_vec
end

"""
    Mulfind(t_vec::AbstractVector,Y::AbstractVector)

Find the indexes of the values in t_vec in the vector Y.
"""
function Mulfind(t_vec::AbstractVector, Y::AbstractVector)
    f(t) = findfirst(x -> x == t, Y)
    return f.(t_vec)
end
#Mulfind(t_vec::AbstractVector,Y::AbstractVector)=Mulfind(t_vec,collect(Y))

"""
    ImputeMissingValues!(x_vec::AbstractVector,date_vec::AbstractVector,median_::Bool=false)

Computes the average (or median) value of each day of the year (for example the first element is the average value of the all 1st January)
and then imputes the missing days with them. The series x_vec must be undrifted.
"""
function ImputeMissingValues!(x_vec::AbstractVector, date_vec::AbstractVector, median_::Bool=false)
    Days_list = [AbstractFloat[] for _ in 1:366]
    for (i, temp) in enumerate(x_vec)
        push!(Days_list[dayofyear_Leap(i, date_vec[1])], temp)
    end
    typical_year = median_ ? median.(Days_list) : mean.(Days_list)
    Missing_days = [date_ for date_ in date_vec[1]:date_vec[end] if date_ ∉ date_vec]
    Missing_days_index = Mulfind(Missing_days, date_vec[1]:date_vec[end])
    #Missing_days_index::AbstractVector{Int}
    Output = (Mulinsert!(x_vec, Missing_days_index, typical_year[dayofyear_Leap.(Missing_days)]),
        Mulinsert!(date_vec, Missing_days_index, Missing_days))
    println("$(length(Missing_days)) days imputated into the series")
    return Output
end
