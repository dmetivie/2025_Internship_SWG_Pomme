include("utils.jl")

using Dates, Distributions, LinearAlgebra, Random


#### Simulating scenarios ####


##With constant parameters

function SimulateScenario!(L, p, Φ, σ::AbstractFloat, rng)
    for i in 1:(length(L)-p)
        L[i+p] = sum(Φ[j] * L[i+p-j] for j in 1:p) + rand(rng, Normal(0, σ))
    end
    return L
end

"""
    SimulateScenarios(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0 ; n::Integer=1)

Simulate n temperature scenarios during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
function SimulateScenarios(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractFloat, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, correction="null", return_res=false)
    p = length(x0)
    L0 = zeros(eltype(x0), length(Date_vec))
    L0[1:p] = x0
    L = [SimulateScenario!(copy(L0), p, Φ, σ, rng) for _ in 1:n]
    return return_res ? (map(sim -> sim .* σ_nspart .+ nspart, L), L) : map(sim -> sim .* σ_nspart .+ nspart, L)
end




##With Monthly parameters

function SimulateScenario!(L, p, n2m, Φ, σ::AbstractVector, rng)
    for (i, m) in enumerate(n2m[p+1:end])
        L[i+p] = sum(Φ[m, j] * L[i+p-j] for j in 1:p) + rand(rng, Normal(0, σ[m]))
    end
    return L
end

"""
    SimulateScenarios(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0 ; n::Integer=1)

Simulate n temperature scenarios during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
function SimulateScenarios(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractVector{T}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, correction="null", return_res=false) where T<:AbstractFloat
    p = length(x0)
    L0 = zeros(eltype(x0), length(Date_vec))
    L0[1:p] = x0
    n2m = month.(Date_vec)
    L = [SimulateScenario!(copy(L0), p, n2m, Φ, σ, rng) for _ in 1:n]
    return return_res ? (map(sim -> sim .* σ_nspart .+ nspart, L), L) : map(sim -> sim .* σ_nspart .+ nspart, L)
end





#### Simulating paired scenarios ####

collectpdx0(x0::AbstractMatrix) = size(x0)
collectpdx0(x0::AbstractVector) = 1, length(x0)

"""
    From (x,y) return y-dist if x>y-dist
"""
clip_(couple::AbstractVector, dist=1) = min(couple[1], couple[2] - dist)

clip_(x::AbstractMatrix, dist=1) = [mapslices(clip_, x, dims=2) x[:, 2]]

function TransformTN_TX!(x, σ_nspart_, nspart_, σTX)
    if σTX
        return hcat(nspart_[:, 1] .+ σ_nspart_[:, 1] .* x[:, 1], x[:, 1] + nspart_[:, 2] - nspart_[:, 1] + x[:, 2] .* (σ_nspart_[:, 2] .^ 2 - σ_nspart_[:, 1] .^ 2) .^ 0.5)
    else
        return hcat(x[:, 2] + nspart_[:, 1] - nspart_[:, 2] + x[:, 1] .* (σ_nspart_[:, 1] .^ 2 - σ_nspart_[:, 2] .^ 2) .^ 0.5, nspart_[:, 2] .+ σ_nspart_[:, 2] .* x[:, 2])
    end
end
function TransformTN_TX(x, σ_nspart_, nspart_, id_σTX, id_σTN, Output)
    Output[id_σTX] = TransformTN_TX!(x[id_σTX], σ_nspart_[id_σTX], nspart_[id_σTX], true)
    Output[id_σTN] = TransformTN_TX!(x[id_σTN], σ_nspart_[id_σTN], nspart_[id_σTN], false)
    return Output
end


function SimulatePairedScenario!(L, p, n2m, Φ, Σ, d, rng)
    for (i, m) in enumerate(n2m[p+1:end])
        L[i+p, :] = sum(Φ[m][j] * L[i+p-j, :] for j in 1:p) .+ Σ[m] * randn(rng, d)
    end
    return L
end


#For the resample correction
function SimulatePairedScenario!(L, p, n2m, Φ, Σ, d, σ_nspart_, nspart_, rng) 
    for (i, m) in enumerate(n2m[p+1:end])
        L[i+p, :] = sum(Φ[m][j] * L[i+p-j, :] for j in 1:p) .+ Σ[m] * randn(rng, d)
        while @views L[i+p, 1] * σ_nspart_[i+p, 1] + nspart_[i+p, 1] > L[i+p, 2] * σ_nspart_[i+p, 2] + nspart_[i+p, 2] #While it is not good it tries again
            L[i+p, :] = sum(Φ[m][j] * L[i+p-j, :] for j in 1:p) .+ Σ[m] * randn(rng, d)
        end
    end
    return L
end


function SimulateScenarios(x0::AbstractArray, Date_vec::AbstractVector, Φ, Σ::AbstractVector{Matrix{T}}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, correction="null", return_res=false) where T<:AbstractFloat
    p, d = collectpdx0(x0)
    M0 = copy(x0)
    p == 1 ? M0 = reshape(M0, (1, d)) : nothing
    L0 = zeros(eltype(x0), (length(Date_vec), d))
    L0[1:p, :] = M0
    n2m = month.(Date_vec)

    nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec), :] : (isnothing(index_nspart) ? nspart : nspart[index_nspart, :]))
    σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec), :] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart, :]))

    L = correction == "resample" ? [SimulatePairedScenario!(copy(L0), p, n2m, Φ, Σ, d, σ_nspart_, nspart_, rng) for _ in 1:n] : [SimulatePairedScenario!(copy(L0), p, n2m, Φ, Σ, d, rng) for _ in 1:n]

    if correction == "clip"
        return return_res ? (clip_.(map(sim -> sim .* σ_nspart_ .+ nspart_, L)), L) : clip_.(map(sim -> sim .* σ_nspart_ .+ nspart_, L))
    elseif correction == "conditional"
        Output = ones(length)
        id_σTX = σ_nspart_[:, 1] <= σ_nspart_[:, 2]
        id_σTN = σ_nspart_[:, 1] > σ_nspart_[:, 2]
        if return_res
            return map(x -> TransformTN_TX(x, σ_nspart_, nspart_, id_σTX, id_σTN, Output), L), L
        else
            return map(x -> TransformTN_TX(x, σ_nspart_, nspart_, id_σTX, id_σTN, Output), L)
        end
    else
        return return_res ? (map(sim -> sim .* σ_nspart_ .+ nspart_, L), L) : map(sim -> sim .* σ_nspart_ .+ nspart_, L)
    end
end

# SimulateScenarios(x0, Date_vec::AbstractVector, Φ, σ, nspart=0, rng=Random.default_rng(); n::Integer=1, index_nspart=nothing) = [SimulateScenario(x0, Date_vec, Φ, σ, nspart, rng, index_nspart=index_nspart) for _ in 1:n]




"""
    concat2by2(L)

(DEPRECATED)
Return the vector of the index-wise concatanations of the nested sub-sub-vectors in L.
The sub-vectors (not necessarily sub-sub-vectors) in L must have the same size. 
For example : 
 ```julia
    x = [[a₁, a₂],[a₃]]
    y = [[b₁], [b₂, b₃]]
    z = [[c₁], [c₂]]
    concat2by2([x,y,z]) = [[a₁, a₂, b₁, c₁], [a₃, b₂, b₃, c₂]]
```
"""
concat2by2(L1::AbstractVector, L2::AbstractVector) = [[u; v] for (u, v) in zip(L1, L2)]
concat2by2(L::AbstractVector) = reduce(concat2by2, L)

#Except this one
concat2by2mat(L1::AbstractVector, L2::AbstractVector) = [[u v] for (u, v) in zip(L1, L2)]
concat2by2mat(L::AbstractVector) = reduce(concat2by2mat, L)