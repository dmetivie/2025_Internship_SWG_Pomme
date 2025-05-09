include("utils.jl")

@tryusing "Dates", "LinearAlgebra", "DataInterpolations", "RegularizationTools", "GLM"

"""
    fitted_periodicity_fonc(x::AbstractVector,return_parameters::Bool=false)

Return a trigonometric function f of period 365.25 of equation f(t) = μ + a*cos(2π*t/365.25) + b*sin((2π*t/365.25) fitted on x. 
If return_parameters=true, return a tuple with f and [μ,a,b]. Be careful : the function returned takes the same arguments as dayofyear_Leap() (Either Date of Integer and Date, see above).
"""
function fitted_periodicity_fonc(x::AbstractVector, date_vec::AbstractVector; OrderTrig::Integer=1, return_parameters::Bool=false)
    N = length(x)
    n2t = dayofyear_Leap.(date_vec)
    ω = 2π / 365.2422
    cos_nj = [cos.(ω * j * n2t) for j = 1:OrderTrig]
    sin_nj = [sin.(ω * j * n2t) for j = 1:OrderTrig]
    Design = stack([[ones(N)]; interleave2(cos_nj, sin_nj)])
    beta = inv(transpose(Design) * Design) * transpose(Design) * x
    function func(args...)
        t = dayofyear_Leap(args...)
        IL = interleave2([cos(ω * j * t) for j = 1:OrderTrig], [sin(ω * j * t) for j = 1:OrderTrig])
        return dot(beta, [1; IL])
    end
    return return_parameters ? (func, beta) : func
end


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
