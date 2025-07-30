include("utils.jl")

@tryusing "Dates", "Distributions", "LinearAlgebra", "Random"
using Random

##### SIMULATION #####
"""
    simulation(x::AbstractVector,Φ::AbstractVector,σ::Number,n::Integer)

Return a simulation of n steps of an AR(p) model with parameters Φ, standard deviation of noise σ and initial condition x. 
The p initial conditions steps are not included in the output.
"""
function simulation(x::AbstractVector, Φ::AbstractVector, σ::Number, n::Integer)
    y, p = copy(x), length(x)
    return simulation!(x, Φ, σ, n, y, p)
end
function simulation!(x::AbstractVector, Φ::AbstractVector, σ, n, y, p)
    for _ in 1:n
        append!(y, dot(y[end:-1:end-p+1], Φ) + σ * randn())
    end
    return y[p+1:end]
end
simulation(x::Number, Φ::Number, σ, n) = simulation([x], [Φ], σ, n)
simulation(x::Number, Φ::AbstractVector, σ, n) = simulation([x], Φ, σ, n)
simulation(x::AbstractVector, Φ::Number, σ, n) = simulation(x, [Φ], σ, n)

"""
    sample_simulation(x::AbstractVector,Φ::AbstractVector,σ::Number,periodicity::AbstractVector,n_year::Integer=1)

Return a sample of n_year*size_multiplicator annual simulations of weather, according to the AR(p) model. periodicity is the periodicity component we want to consider.
"""
function sample_simulation(x::AbstractVector, Φ::AbstractVector, σ::Number, periodicity::AbstractVector, n_year::Integer=1)
    Output = [[x; simulation(x, Φ, σ, 365 - length(x))]]
    p = length(x)
    if n_year > 1
        for _ in 2:n_year
            append!(Output, [simulation(Output[end][(end-p+1):end], Φ, σ, 365)])
        end
    end
    return [year_ .+ periodicity[1:365] for year_ in Output]
end


"""
    SimulateMonth(x0,day_one,Φ_month,σ_month,n_month)

Return a simulation of a month-conditional AR(p) model (one AR(p) model for each month), for n_month starting from x0[1]. 
day_one is the date of x0[end]
Unless day_one is the last day of his month, the current month of day_one is included in n_month. 
Be careful : the output includes x0, even if it's a vector.  
"""
function SimulateMonth(x0::AbstractVector, day_one::Date, Φ_month::AbstractVector, σ_month::AbstractVector, n_month::Integer)
    p = length(x0)
    current_month = Date(year(day_one), month(day_one))
    if current_month + Month(1) - Day(1) - day_one != Day(0) #If it is not the last day of the month
        n = length(day_one:(current_month+Month(1)-Day(1)))
        x = [x0; simulation(x0, Φ_month[month(day_one)], σ_month[month(day_one)], n - 1)] #-1 because I don't want to include the day_one x in this generated series       
    else
        n = length(day_one:(current_month+Month(2)-Day(1)))
        x = [x0; simulation(x0, Φ_month[((month(day_one)%12)+1)], σ_month[((month(day_one)%12)+1)], n - 1)]
        current_month += Month(1)
    end
    if n_month > 1
        for _ in 2:n_month
            current_month += Month(1)
            n = length(current_month:current_month+Month(1)-Day(1))
            append!(x, simulation(x[(end-p+1):end], Φ_month[month(current_month)], σ_month[month(current_month)], n))
        end
    end
    return x
end
SimulateMonth(x0::Number, day_one::Date, Φ_month::AbstractVector, σ_month::AbstractVector, n_month::Integer) = SimulateMonth([x0], day_one, Φ_month, σ_month, n_month)

"""
    SimulateYears(x0::Number,day_one::Date,Φ_month::AbstractVector,σ_month::AbstractVector,n_years::Integer)
    
Return a n_years-sample of yearly simulations of a month-conditional AR(p) model (one AR(p) model for each month).
The first simulation starts from x0[1], and the initial condition for the following years are the p last days of the previous year.
day_one must be the date of x0[end]
Each year generated has the same amount of days and correspond to one vector inside the output.
It's recommanded to choose the p-th day of a year (yearX,1,p) as day_one.  
"""
function SimulateYears(x0::AbstractVector, day_one::Date, Φ_month::AbstractVector, σ_month::AbstractVector, n_years::Integer)
    p = length(x0)
    L = [SimulateMonth(x0, day_one, Φ_month, σ_month, 12)]
    if n_years > 1
        for _ in 2:n_years
            append!(L, [SimulateMonth(L[end][(end-p+1):end], Date(year(day_one), month(day_one)) - Day(1), Φ_month, σ_month, 12)[p+1:end]]) #The p first elements belong to the previous year.
        end
    end
    return L
end
SimulateYears(x0::Number, day_one::Date, Φ_month::AbstractVector, σ_month::AbstractVector, n_month::Integer) = SimulateYears([x0], day_one, Φ_month, σ_month, n_month)


#### Simulating scenarios ####


"""
    SimulateScenario(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0)

Simulate a temperature scenario during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
# function SimulateScenario(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0, rng=Random.default_rng(); index_nspart=nothing)
#     L, p = copy(x0), length(x0)
#     for date_ in Date_vec[p+1:end]
#         length(Φ) == 12 ? append!(L, dot(L[end:-1:end-p+1], Φ[month(date_)]) + σ[month(date_)] * randn(rng)) : append!(L, dot(L[end:-1:end-p+1], Φ) + σ * randn(rng))
#     end
#     return L .+ (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? nspart : nspart[index_nspart]))
# end
# SimulateScenario(x0::AbstractFloat, Date_vec::AbstractVector, Φ, σ, nspart=0, rng=Random.default_rng(); index_nspart=nothing) = SimulateScenario([x0], Date_vec, Φ, σ, nspart, rng, index_nspart=index_nspart)







function SimulateScenario!(L, p, Date_vec, Φ, σ::AbstractFloat, rng)
    for date_ in Date_vec[p+1:end]
        append!(L, dot(L[end:-1:end-p+1], Φ) + σ * randn(rng))
    end
    return L
end
function SimulateScenario!(L, p, Date_vec, Φ, σ::AbstractVector, rng)
    for date_ in Date_vec[p+1:end]
        append!(L, dot(L[end:-1:end-p+1], Φ[month(date_)]) + σ[month(date_)] * randn(rng))
    end
    return L
end

function SimulateScenario2!(x, p, Date_vec, Φ, σ::AbstractVector, rng)
    L = zeros(eltype(x), length(Date_vec)) # Initialize 
    L[1:p] .= x
    for (i, date_) in enumerate(Date_vec[p+1:end])
        L[i+p] = dot(L[end:-1:end-p+1], Φ[month(date_)]) + σ[month(date_)] * randn(rng)
    end
    return L
end

function SimulateScenario3!(x, p, Date_vec, Φ, σ::AbstractVector, rng)
    L = zeros(eltype(x), length(Date_vec)) # Initialize 
    L[1:p] .= x
    @views for (i, date_) in enumerate(Date_vec[p+1:end])
        L[i+p] = dot(L[end:-1:end-p+1], Φ[month(date_)]) + σ[month(date_)] * randn(rng)
    end
    return L
end

function SimulateScenario4!(L, p, n2t, Φ, σ::AbstractVector, rng)
    for (i, m) in enumerate(n2t[p+1:end])
        L[i+p] = sum(Φ[m][j] * L[i+p-j] for j in 1:p) + rand(rng,Normal(0,σ[m]))
    end
    return L
end

function SimulateScenario(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0, σ_nspart=1; rng=Random.default_rng(), index_nspart=nothing)
    L = SimulateScenario!(copy(x0), length(x0), Date_vec, Φ, σ, rng)
    nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? nspart : nspart[index_nspart]))
    σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart]))
    return L .* σ_nspart_ .+ nspart_
end


SimulateScenario(x0::AbstractFloat, Date_vec::AbstractVector, Φ, σ, nspart=0, σ_nspart=1, rng=Random.default_rng(); index_nspart=nothing) = SimulateScenario([x0], Date_vec, Φ, σ, nspart, σ_nspart, rng, index_nspart=index_nspart)


"""
    SimulateScenarios(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0 ; n::Integer=1)

Simulate n temperature scenarios during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
function SimulateScenarios(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractVector{T}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, correction="null") where T<:AbstractFloat
    if n == 1
        return SimulateScenario(x0, Date_vec, Φ, σ, nspart, σ_nspart, rng=rng, index_nspart=index_nspart)
    else
        L = [SimulateScenario!(copy(x0), length(x0), Date_vec, Φ, σ, rng) for _ in 1:n]
        nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? nspart : nspart[index_nspart]))
        σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart]))
        return map(sim -> sim .* σ_nspart_ .+ nspart_, L)
    end
end
SimulateScenarios(x0::AbstractFloat, Date_vec::AbstractVector, Φ, σ, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing) = SimulateScenarios([x0], Date_vec, Φ, σ, nspart, σ_nspart, rng, n=n, index_nspart=index_nspart)

"""
    SimulateScenarios2(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0 ; n::Integer=1)

Simulate n temperature scenarios during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
function SimulateScenarios2(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractVector{T}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, correction="null") where T<:AbstractFloat
    L = [SimulateScenario2!(copy(x0), length(x0), Date_vec, Φ, σ, rng) for _ in 1:n]
    nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? nspart : nspart[index_nspart]))
    σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart]))
    return map(sim -> sim .* σ_nspart_ .+ nspart_, L)
end

"""
    SimulateScenarios2(x0::AbstractVector, Date_vec::AbstractVector, Φ, σ, nspart=0 ; n::Integer=1)

Simulate n temperature scenarios during the Date_vec timeline following an AR model with parameters Φ and σ and non stationnary part (trend + periodicity) nspart.
"""
function SimulateScenarios3(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractVector{T}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, correction="null") where T<:AbstractFloat
    L = [SimulateScenario3!(copy(x0), length(x0), Date_vec, Φ, σ, rng) for _ in 1:n]
    nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? nspart : nspart[index_nspart]))
    σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec)] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart]))
    return map(sim -> sim .* σ_nspart_ .+ nspart_, L)
end


function SimulateScenarios4(x0::AbstractArray, Date_vec::AbstractVector, Φ, σ::AbstractVector{T}, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, correction="null", return_res=false) where T<:AbstractFloat
    p = length(x0)
    L0 = zeros(eltype(x0),length(Date_vec))
    L0[1:p] = x0
    n2t = month.(Date_vec)
    L = [SimulateScenario4!(copy(L0), p, n2t, Φ, σ, rng) for _ in 1:n]
    return return_res ? (map(sim -> sim .* σ_nspart .+ nspart, L), L) : map(sim -> sim .* σ_nspart .+ nspart, L)
end
# SimulateScenarios4(x0::AbstractFloat, Date_vec::AbstractVector, Φ, σ, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing, return_res=false) = SimulateScenarios([x0], Date_vec, Φ, σ, nspart, σ_nspart, rng, n=n, index_nspart=index_nspart, return_res=return_res)



SimulateScenarios(x0::AbstractFloat, Date_vec::AbstractVector, Φ, σ, nspart=0, σ_nspart=1; rng=Random.default_rng(), n=1, index_nspart=nothing) = SimulateScenarios([x0], Date_vec, Φ, σ, nspart, σ_nspart, rng, n=n, index_nspart=index_nspart)

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

function SimulatePairedScenario!(M, p, Date_vec, Φ, Σ, d, rng)
    for date_ in Date_vec[p+1:end]
        M = vcat(M, reshape(sum(Φ[month(date_)][j] * M[end+1-j, :] for j in 1:p) .+ Σ[month(date_)] * randn(rng, d), (1, d)))
    end
    return M
end

function SimulateScenarios(x0::AbstractArray, Date_vec::AbstractVector, Φ, Σ::AbstractVector{Matrix{T}}, nspart=0, σ_nspart=1, rng=Random.default_rng(); n=1, index_nspart=nothing, correction="null") where T<:AbstractFloat
    M = copy(x0)
    p, d = collectpdx0(x0)
    p == 1 ? M = reshape(M, (1, d)) : nothing
    L = [SimulatePairedScenario!(M, p, Date_vec, Φ, Σ, d, rng) for _ in 1:n]
    nspart_ = (length(nspart) == 366 ? nspart[dayofyear_Leap.(Date_vec), :] : (isnothing(index_nspart) ? nspart : nspart[index_nspart, :]))
    σ_nspart_ = (length(σ_nspart) == 366 ? σ_nspart[dayofyear_Leap.(Date_vec), :] : (isnothing(index_nspart) ? σ_nspart : σ_nspart[index_nspart, :]))
    if correction == "null"
        return n == 1 ? L[1] .* σ_nspart_ .+ nspart_ : map(sim -> sim .* σ_nspart_ .+ nspart_, L)
    elseif correction == "clip"
        return n == 1 ? clip_(L[1] .* σ_nspart_ .+ nspart_) : clip_.(map(sim -> sim .* σ_nspart_ .+ nspart_, L))
    elseif correction == "conditional"
        Output = ones(length)
        id_σTX = σ_nspart_[:, 1] <= σ_nspart_[:, 2]
        id_σTN = σ_nspart_[:, 1] > σ_nspart_[:, 2]
        if n == 1
            return TransformTN_TX(L[1], σ_nspart_, nspart_, id_σTX, id_σTN, Output)
        else
            return map(x -> TransformTN_TX(x, σ_nspart_, nspart_, id_σTX, id_σTN, Output), L)
        end
    end
end
#works 

# SimulateScenarios(x0, Date_vec::AbstractVector, Φ, σ, nspart=0, rng=Random.default_rng(); n::Integer=1, index_nspart=nothing) = [SimulateScenario(x0, Date_vec, Φ, σ, nspart, rng, index_nspart=index_nspart) for _ in 1:n]




"""
    concat2by2(L)

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