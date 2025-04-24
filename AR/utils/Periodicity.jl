try
    using Dates, LinearAlgebra, DataInterpolations, RegularizationTools
catch ;
    import Pkg
    Pkg.add("Dates")
    Pkg.add("LinearAlgebra")
    Pkg.add("DataInterpolations")
    Pkg.add("RegularizationTools")
    using Dates, LinearAlgebra, DataInterpolations, RegularizationTools
end

"""
    n2t(Date_::Date)

Return the index t ∈ [1:366] of the day in input.
"""
n2t(Date_::Date)=findfirst(t->t==Date_-Year(year(Date_)),Date(0):(Date(1)-Day(1))) 
#It brings back the day in the year 0 which is bissextile, and then it returns the corresponding index.


"""
    n2t(n::Int,Day_one::Date)

Return the index t ∈ [1:366] of the index n, where n represents the total number of days starting from Day_one.
"""
n2t(n::Int,Day_one::Date)=n2t(Day_one + Day(n-1))

"""
    fitted_periodicity(x::Vector,return_parameters::Bool=false)

Return a trigonometric function f of period 365.25 of equation f(t) = μ + a*cos(2π*t/365.25) + b*sin((2π*t/365.25) fitted on x. 
If return_parameters=true, return a tuple with f and [μ,a,b].
"""
function fitted_periodicity(x::Vector,return_parameters::Bool=false)
    N=length(x)
    t_vec=collect(1:N)
    Design=reduce(hcat,[ones(N),cos.((2π*t_vec)/365.2422),sin.((2π*t_vec)/365.2422)]) 
    beta=inv(transpose(Design)*Design)*transpose(Design)*x
    f(t)=dot(beta,[1,cos((2π*t)/365.2422),sin((2π*t)/365.2422)])
    return return_parameters ? (f,beta) : f
end

