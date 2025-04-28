try
    using Dates, Polynomials
catch
    import Pkg
    Pkg.add("Dates")
    Pkg.add("Polynomials")
    using Dates, Polynomials
end

"""
    Iyear(date::AbstractVector{Date},year::Integer)
Return a mask to select only the period of the year(s) in argument.
"""
Iyear(date::AbstractVector{Date}, year::Integer) = Date(year) .<= date .< Date(year + 1)
Iyear(date::AbstractVector{Date}, years::AbstractVector) = Date(years[1]) .<= date .< Date(years[end] + 1)

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
Deprecated for now
"""
function Undrift!(y::AbstractVector)
    N = length(y)
    X = cat(ones(N), 1:N, dims=2)
    beta = inv(transpose(X) * X) * transpose(X) * y
    y .= y - beta[2] * collect(1:N)
    return nothing
end

