include("utils.jl")

using Dates


##### SEPARATION #####
"""
    MonthlySeparateDates(Date_vec::AbstractVector{Date})

Reshape the vector of dates Date_vec into a vector of vectors of vectors Monthly_date. 
For Monthly_date[i][j][k], i ∈ 1:12 represents the month, j the year and k the day.
"""
function MonthlySeparateDates(Date_vec::AbstractVector{Date})
    Monthly_date = [AbstractVector[] for _ in 1:12]
    for i in 1:12
        for year in unique(year.(Date_vec))
            if any(Date(year, i) .<= Date_vec .< (Date(year, i) + Month(1)))
                append!(Monthly_date[i], [Date_vec[Date(year, i).<=Date_vec.<Date(year, i)+Month(1)]])
            end
        end
    end
    return Monthly_date
end

"""
    MonthlySeparateX(x::AbstractVector,Date_vec::AbstractVector{Date})
    
Reshape the vector of values x into a vector of vectors of vectors Monthly_temp. 
For Monthly_temp[i][j][k], i ∈ 1:12 represents the month, j the year and k the day, according to the calendar Date_vec.
"""
function MonthlySeparateX(x::AbstractVector, Date_vec::AbstractVector{Date})
    Monthly_temp = [AbstractVector[] for _ in 1:12]
    for i in 1:12
        for year in unique(year.(Date_vec))
            if any(Date(year, i) .<= Date_vec .< (Date(year, i) + Month(1)))
                append!(Monthly_temp[i], [x[Date(year, i).<=Date_vec.<(Date(year, i)+Month(1))]])
            end
        end
    end
    return Monthly_temp
end



