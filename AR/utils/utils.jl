using Dates, Polynomials, DataFrames, DataFramesMeta

"""
    Iyear(date::AbstractVector{Date},year::Integer)
Return a mask to select only the period of the year(s) in argument.
"""
Iyear(date::AbstractVector{Date}, year::Integer) = Date(year) .<= date .< Date(year + 1)
Iyear(date::AbstractVector{Date}, years::AbstractVector{<:Integer}) = Date(years[1]) .<= date .< Date(years[end] + 1)

"""
    RootAR(Φ::AbstractVector)
Return the roots of the polynomial associated to the AR model given by Φ.
"""
RootAR(Φ::AbstractVector) = roots(Polynomial([-1; Φ]))

Month_vec = ["January", "February", "March", "April", "May", "Jun", "July", "August", "September", "October", "November", "December"]
Month_vec2 = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
Month_vec_low = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

"""
    invert(L::AbstractVector)
Transpose a vector of vectors L (like the function zip in python)
"""
invert(L::AbstractVector) = [[L[i][j] for i in eachindex(L)] for j in eachindex(L[1])]

"""
    DaysPerMonth(year::Integer)
Return the number of days per month of the input year.
"""
DaysPerMonth(year::Integer) = length.([Date(year, i):(Date(year, i)+Month(1)-Day(1)) for i in 1:12])

"""
    MAPE(x_hat::AbstractFloat,x::AbstractFloat)
Return the Mean Absolute Percentage Error between estimated x_hat and the true x value. 
"""
MAPE(x_hat::AbstractFloat, x::AbstractFloat) = 100 * abs((x_hat - x) / x)
MAPE(x_hat::AbstractVector, x::AbstractVector) = 100 * mean(abs.((x_hat - x) ./ x))

"""
    dayofyear_Leap(Date_::Date)

Return the index t ∈ [1:366] of the day in input. (Credits : David Métivier (dmetivie))
"""
dayofyear_Leap(d::Date) = @. dayofyear(d) + ((!isleapyear(d)) & (month(d) > 2))

"""
    dayofyear_Leap(n::Int,Day_one::Date)

Return the index t ∈ [1:366] of the index n, where n represents the total number of days starting from Day_one.
"""
dayofyear_Leap(n::Integer, Day_one::Date) = dayofyear_Leap(Day_one + Day(n - 1))

"""
    GatherYearScenario(Scenario::AbstractVector,Date_vec::AbstractVector)

Create a vector where each sub-vector corresponds to a day of the year. 
Each temperature of the scenario is put in his corresponding sub-vector according to his day of the year.
For example, Output[1] = [temperature of the 1st january of the first year, temperature of the 1st january of the second year, etc...]
"""
GatherYearScenario(Scenario::AbstractVector, n2t::AbstractVector{T}) where T <: Integer = [Scenario[n2t .== i] for i in 1:366]
GatherYearScenario(Scenario::AbstractVector, Date_vec::AbstractVector{Date}) = GatherYearScenario(Scenario, dayofyear_Leap.(Date_vec))


"""
    GatherYearScenarios(Scenarios::AbstractVector,Date_vec::AbstractVector)

Create a vector where each sub-vector corresponds to a day of the year. 
Each temperature of each scenario is put in his corresponding sub-vector according to his day of the year.
For example, Output[1] = [temperature of the 1st january of the first year of the first scenario, 
temperature of the 1st january of the second year of the first scenario,
...,
temperature of the 1st january of the last year of the last scenario]
"""
GatherYearScenarios(Scenarios, Date_vec) = GatherYearScenario(vcat(Scenarios...), repeat(Date_vec, length(Scenarios)))

"""
Deprecated for now
"""
function Undrift!(y::AbstractVector)
    N = length(y)
    X = cat(ones(N), 1:N, dims=2)
    beta = inv(transpose(X) * X) * transpose(X) * y
    y .= y - beta[2] * collect(1:N)
    return nothing
end

mulmean(X)=mean.(X)
mulmedian(X)=median.(X)


"""
    Merge vectors with alternate elements (Credits : David Métivier (dmetivie))
    For example
    ```julia
    x = [x₁, x₂]
    y = [y₁, y₂]
    interleave2(x, y) = [x₁, y₁, x₂, y₂]
    ```
"""
interleave2(args...) = collect(Iterators.flatten(zip(args...)))
# d = 4
# T = 8
# f = 2π / T
# cos_nj = [cos(f * j * t) for t = (π/4)*0:T, j = 1:d]
# sin_nj = [sin(f * j * t) for t = (π/4)*0:T, j = 1:d]
# trig = reduce(hcat, [[1; interleave2(cos_nj[t, :], sin_nj[t, :])] for t = 1:(T+1)])


unzip(a) = map(x -> getfield.(a, x), fieldnames(eltype(a)))
## Source : https://stackoverflow.com/questions/36367482/unzip-an-array-of-tuples-in-julia

GetAllAttributes(object) = map(field -> getfield(object, field), fieldnames(typeof(object)))
## Source : https://discourse.julialang.org/t/get-the-name-and-the-value-of-every-field-for-an-object/87052/2


function Common_indexes(series_vec::AbstractVector{DataFrame})
    Date_vecs = [series.DATE for series in series_vec]
    if all(y->y==Date_vecs[1],Date_vecs)
        Temps_vecs = [series[:,2] for series in series_vec]
        return Date_vecs[1], stack(Temps_vecs)
    else #If the timelines are differents, we take the common timeline of the two series.
        date_vec = maximum(Date_vec[1] for Date_vec in Date_vecs):minimum(Date_vec[end] for Date_vec in Date_vecs)
        x = stack(series[:,2][findfirst(series.DATE .== date_vec[1]):findfirst(series.DATE .== date_vec[end])] for series in series_vec)
        return date_vec, x
    end
end

Common_indexes(files::String...) = Common_indexes(truncate_MV.(extract_series.(files)))
Common_indexes(files::AbstractVector{String}) = Common_indexes(truncate_MV.(extract_series.(files)))

