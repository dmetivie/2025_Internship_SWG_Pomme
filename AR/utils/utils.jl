macro tryusing(package::String)
    try
        eval(:(using $(Meta.parse(package))))
    catch
        eval(:(
            import Pkg;
            Pkg.add($package);
            using $(Meta.parse(package))))
    end
end
macro tryusing(package::Expr)
    for s in package.args
        try
            eval(:(using $(Meta.parse(s))))
        catch
            eval(:(
                import Pkg;
                Pkg.add($s);
                using $(Meta.parse(s))))
        end
    end
end

@tryusing "Dates", "Polynomials", "DataFrames", "DataFramesMeta"

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
function GatherYearScenario(Scenario::AbstractVector, Date_vec::AbstractVector)
    Days_list = [AbstractFloat[] for _ in 1:366]
    for (i, temp) in enumerate(Scenario)
        push!(Days_list[dayofyear_Leap(Date_vec[i])], temp)
    end
    return Days_list
end

"""
    GatherYearScenarios(Scenarios::AbstractVector,Date_vec::AbstractVector)

Create a vector where each sub-vector corresponds to a day of the year. 
Each temperature of each scenario is put in his corresponding sub-vector according to his day of the year.
For example, Output[1] = [temperature of the 1st january of the first year of the first scenario, 
temperature of the 1st january of the second year of the first scenario,
...,
temperature of the 1st january of the last year of the last scenario]
"""
GatherYearScenarios(Scenarios, Date_vec) = concat2by2(GatherYearScenario.(Scenarios, repeat([Date_vec], length(Scenarios))))

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

