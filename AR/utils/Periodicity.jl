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

AIC(n, p, SRS) = 2p + n * (log(2π * SRS / n) + 1)


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


"""
    fitted_smooth_periodicity_fonc(x::AbstractVector, date_vec::AbstractVector, orderdiff::Integer=9)

Return a function which is the smooth regularization of the mean year of x, with the timeline date_vec. 
"""
function fitted_smooth_periodicity_fonc(x::AbstractVector, date_vec::AbstractVector; OrderDiff::Integer=9)
    f = RegularizationSmooth(mean.(GatherYearScenario(x, date_vec)), 1:366, OrderDiff)
    return date -> f(dayofyear_Leap(date))
end

"""
    trigo_version(j, t, ω=2π / 365.2422)

Return the jᵗʰ term of the trigonometric decomposition  of t (fitted_periodicity_fonc_stepwise)
"""
trigo_version(j, t, ω=2π / 365.2422) = (j == 1) + iseven(j) * cos(ω * j * t / 2) + isodd(j) * (j > 1) * sin(ω * (j - 1) * t / 2)

"""
    fitted_periodicity_fonc_stepwise(x::AbstractVector, date_vec::AbstractVector; MaxOrder::Integer=1, return_parameters::Bool=false, verbose::Bool=false)

Return a trigonometric function the approximates the series x. Each component of the trigonometric decompositon (cos(ω h t) , sin(ω h t), with h the harmonic order) is chosen with the stepwise method to optimize AIC.
If return_parameters=true, return a tuple with f and the parameters estimated. Be careful : the function returned takes the same arguments as dayofyear_Leap() (Either Date of Integer and Date, see above).
"""
function fitted_periodicity_fonc_stepwise(x::AbstractVector, date_vec::AbstractVector; MaxOrder::Integer=50, return_parameters::Bool=false, verbose::Bool=false)
    N = length(x)
    n2t = dayofyear_Leap.(date_vec)
    ω = 2π / 365.2422
    cos_nj = [cos.(ω * j * n2t) for j = 1:MaxOrder]
    sin_nj = [sin.(ω * j * n2t) for j = 1:MaxOrder]
    Design = stack([[ones(N)]; interleave2(cos_nj, sin_nj)])
    I = [1] #Choice of features
    SubDesign=Design[:,I]
    beta = inv(transpose(SubDesign) * SubDesign) * transpose(SubDesign) * x
    best_AIC = AIC(N,1,sum((SubDesign * beta .- x) .^ 2)) 
    verbose ? println(best_AIC, I) : nothing
    for _ in 1:1000
        AIC_Candidates = Dict{Integer,AbstractFloat}()
        for j in setdiff(1:(2*MaxOrder+1),I) #Searching between models with a new feature
            SubDesign=Design[:,[I ; j]]
            beta = inv(transpose(SubDesign) * SubDesign) * transpose(SubDesign) * x
            AIC_Candidates[j] = AIC(N,length(I)+1,sum((SubDesign * beta .- x) .^ 2))
        end  
        for j in I #Searching between models with a removed feature
            SubDesign=Design[:,setdiff(I,[j])]
            beta = inv(transpose(SubDesign) * SubDesign) * transpose(SubDesign) * x
            AIC_Candidates[j] = AIC(N,length(I)-1,sum((SubDesign * beta .- x) .^ 2))
        end  
        J = argmin(AIC_Candidates)
        if best_AIC < AIC_Candidates[J]
            break
        else
            best_AIC = AIC_Candidates[J]
            I = J ∈ I ? setdiff(I,[J]) : [I ; J]
            verbose ? println(best_AIC, sort(I)) : nothing
        end
    end
    FinalDesign = Design[:,I]
    beta = inv(transpose(FinalDesign) * FinalDesign) * transpose(FinalDesign) * x
    function func(args...)
        t = dayofyear_Leap(args...)
        trigo_decompo = [trigo_version(j, t) for j in I]
        return dot(beta, trigo_decompo)
    end
    return return_parameters ? (func, beta) : func
end

