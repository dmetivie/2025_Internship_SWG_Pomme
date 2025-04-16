try
    using Dates, Polynomials
catch ;
    import Pkg
    Pkg.add("Dates")
    Pkg.add("Polynomials")
    using Dates, Polynomials
end

"""
    Iyear(date::Vector{Date},year::Int)
Return a mask to select only the period of the year in argument.
"""
Iyear(date::Vector{Date},year::Int) = Date(year).<=date.<Date(year + 1)

"""
    RootAR(Φ::Vector)
Return the roots of the polynomial associated to the AR model given by Φ.
"""
RootAR(Φ::Vector)=roots(Polynomial([-1;Φ]))

Month_vec=["January", "February", "March", "April", "May", "Jun", "July", "August", "September", "October", "November", "December"]

"""
    invert(L::Vector)
Transpose a vector of vectors L (like the function zip in python)
"""
invert(L::Vector)=[[L[i][j] for i in eachindex(L)] for j in eachindex(L[1])]

"""
    DaysPerMonth(year::Int)
Return the number of days per month of the input year.
"""
DaysPerMonth(year::Int)=length.([Date(year,i):(Date(year,i)+Month(1)-Day(1)) for i in 1:12])

"""
    MAPE(x_hat::Float64,x::Float64)
Return the mean absolute percentage error between estimated x_hat and the true x value. 
"""
MAPE(x_hat::Float64,x::Float64)=100*abs((x_hat-x) / x)
MAPE(x_hat::Vector,x::Vector)=100*mean(abs.((x_hat-x) ./ x))