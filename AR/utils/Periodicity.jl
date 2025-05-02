include("utils.jl")

@tryusing "Dates", "LinearAlgebra", "DataInterpolations", "RegularizationTools"

"""
    n2t(Date_::Date)

Return the index t ∈ [1:366] of the day in input.
"""
n2t(Date_::Date) = findfirst(t -> t == Date_ - Year(year(Date_)), Date(0):(Date(1)-Day(1)))
#It brings back the day in the year 0 which is bissextile, and then it returns the corresponding index.


"""
    n2t(n::Int,Day_one::Date)

Return the index t ∈ [1:366] of the index n, where n represents the total number of days starting from Day_one.
"""
n2t(n::Integer, Day_one::Date) = n2t(Day_one + Day(n - 1))

"""
    fitted_periodicity_fonc(x::AbstractVector,return_parameters::Bool=false)

Return a trigonometric function f of period 365.25 of equation f(t) = μ + a*cos(2π*t/365.25) + b*sin((2π*t/365.25) fitted on x. 
If return_parameters=true, return a tuple with f and [μ,a,b].
"""
function fitted_periodicity_fonc(x::AbstractVector, return_parameters::Bool=false)
    N = length(x)
    t_vec = collect(1:N)
    Design = reduce(hcat, [ones(N), cos.((2π * t_vec) / 365.2422), sin.((2π * t_vec) / 365.2422)])
    beta = inv(transpose(Design) * Design) * transpose(Design) * x
    f(t) = dot(beta, [1, cos((2π * t) / 365.2422), sin((2π * t) / 365.2422)])
    return return_parameters ? (f, beta) : f
end

# f = 2π / T
# cos_nj = [cos(f * j * t) for t = 1:T, j = 1:d]
# sin_nj = [sin(f * j * t) for t = 1:T, j = 1:d]
# trig = [[1; interleave2(cos_nj[t, :], sin_nj[t, :])] for t = 1:T]
# """
#     Merge vectors with alternate elements
#     For example
#     ```julia
#     x = [x₁, x₂]
#     y = [y₁, y₂]
#     interleave2(x, y) = [x₁, y₁, x₂, y₂]
#     ```
# """
# interleave2(args...) = collect(Iterators.flatten(zip(args...)))

# dayofyear_Leap(d) = @. dayofyear(d) + ((!isleapyear(d)) & (month(d) > 2))
