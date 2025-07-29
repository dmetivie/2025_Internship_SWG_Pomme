# Performance test for SimulateScenario vs SimulateScenarios vs SimulateScenarios2
# Testing with 12 monthly sigma parameters, AR memory p=3 for each month, dates from 1956 to 2019

include("../AR/utils/Simulation.jl")
using BenchmarkTools
using Dates
using Random
using LinearAlgebra

# Set random seed for reproducibility
Random.seed!(1234)

# Parameters setup
p = 3  # AR memory
n_months = 12

# Create AR parameters for each month (p=3 coefficients per month)
Φ_monthly = Vector{Vector{Float64}}(undef, n_months)
for m in 1:n_months
    # Generate stationary AR(3) coefficients for each month
    # Ensure stationarity by keeping coefficients within reasonable bounds
    Φ_monthly[m] = [0.4 + 0.2 * randn(), 0.2 + 0.1 * randn(), 0.1 + 0.05 * randn()]
end

# Create sigma parameters for each month
σ_monthly = rand(0.5:0.1:2.0, n_months)  # Random sigma between 0.5 and 2.0 for each month

# Create date vector from 1956 to 2019
start_date = Date(1956, 1, 1)
end_date = Date(2019, 12, 31)
date_vec = collect(start_date:Day(1):end_date)

# Initial conditions (p values)
x0 = randn(p)

println("="^70)


# Test SimulateScenario (single scenario)
n = 1000
println("SimulateScenario (n=$n):")
result1 = @btime SimulateScenarios($x0, $date_vec, $Φ_monthly, $σ_monthly, n=n)

println("SimulateScenario2 (n=$n):")
result2 = @btime SimulateScenarios2($x0, $date_vec, $Φ_monthly, $σ_monthly, n=n)

println("SimulateScenario3 (n=$n):")
result3 = @btime SimulateScenarios3($x0, $date_vec, $Φ_monthly, $σ_monthly, n=n)

@profview SimulateScenarios(x0, date_vec, Φ_monthly, σ_monthly, n=1000)
@profview SimulateScenarios2(x0, date_vec, Φ_monthly, σ_monthly, n=1000)



######

# Ici j'expose la manière qui me parait la plus pertinante (en termes Julia et code en général) pour coder l'AR et sa structure.
# L'ajout tendance saisonalité peut se faire après

using ConcreteStructs # package pour écrire les structures sans se prendre la tête avec les types
using Distributions
abstract type AbstractAR end
using Random

@doc raw"""
AR(p) process with finite markov chain
The process follows
```math
    y_t = \mu + \sum_{i=1}^{p} \Phi_i y_{t-i} + \epsilon_t
```
where ``\epsilon_t \sim N (0, \sigma^2)``
##### Arguments
- `Φ` : Persistence parameter in AR(p) process
- `σ::Real` : Standard deviation of random component
- `μ::Real` : Deviation

"""
@concrete struct AR <: AbstractAR
    μ
    Φ # Matrix or vector typically of size (n, p) or (n,) for AR(1)
    σ # 
    # checking the dimensions of the parameters
    function AR(μ, Φ, σ)
        n = length(μ)
        if length(σ) != n
            throw(ArgumentError("Length of μ ($(n)), and σ ($(length(σ))) must be equal"))
        end
        if size(Φ, 1) != n
            throw(ArgumentError("Number of rows in Φ ($(size(Φ, 1))) must match length of μ ($(n))"))
        end
        new{typeof(μ),typeof(Φ),typeof(σ)}(μ, Φ, σ)
    end
end

function Base.rand(rng::AbstractRNG, AR::AR, n2t::AbstractVector{<:Integer}; y_ini=randn(size(AR.Φ, 2)))
    N = length(n2t)
    p = size(AR.Φ, 2)
    y = zeros(eltype(y_ini), N)
    y[1:p] = y_ini
    for n = (p+1):N
        y[n] = AR.μ[n2t[n]] + sum(AR.Φ[n2t[n], i] * y[n-i] for i in 1:p) + rand(rng, Normal(0, AR.σ[n2t[n]]))
    end
    return y
end

Base.rand(AR::AR, n2t::AbstractVector{<:Integer}; y_ini=randn(size(AR.Φ, 2))) = rand(Random.default_rng(), AR, n2t; y_ini=y_ini)

# Example usage
μ = randn(12)  # Example mean for each day of the year
ar = AR(μ, stack(Φ_monthly) |> permutedims, σ_monthly)
n2t = month.(date_vec) # or dayofyear_Leap.(date_vec) for daily model

function simulate_scenario(ar::AR, n2t::AbstractVector{<:Integer}, n::Integer; y_ini=randn(size(ar.Φ, 2)))
    X = [rand(ar, n2t; y_ini=y_ini) for _ in 1:n]
end
@btime simulate_scenario(ar, n2t, n; y_ini=x0)