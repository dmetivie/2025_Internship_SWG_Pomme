# Performance test for SimulateScenario vs SimulateScenarios vs SimulateScenarios2
# Testing with 12 monthly sigma parameters, AR memory p=3 for each month, dates from 1956 to 2019
include("../AR/table_reader.jl")
include("../AR/utils/structure.jl")
include("../AR/utils/Plotting.jl")
using BenchmarkTools
cd(@__DIR__)


# Set random seed for reproducibility
Random.seed!(1234)


#multivariate AR(2)
Model = load_model("Multi_AR_model_test.jld2")

# Initial conditions (p values)
x0=Model.y₁
date_vec=Model.date_vec
Φ_monthly = Model.Φ 
σ_monthly = Model.σ

println("="^70)


# Test SimulateScenario (single scenario)
n = 10
println("SimulateScenario (n=$n):")
result1 = @btime SimulateScenarios0($x0, $date_vec, $Φ_monthly, $σ_monthly, n=n) #The new version used

println("SimulateScenario2 (n=$n):")
result2 = @btime SimulateScenarios($x0, $date_vec, $Φ_monthly, $σ_monthly, n=n)


# @profview SimulateScenarios(x0, date_vec, Φ_monthly, σ_monthly, n=1000)
# @profview SimulateScenarios2(x0, date_vec, Φ_monthly, σ_monthly, n=1000)

#To check if the two functions return the same result
Random.seed!(1234)
result1 = SimulateScenarios0(x0, date_vec, Φ_monthly, σ_monthly,n=n)
Random.seed!(1234)
result2 = SimulateScenarios(x0, date_vec, Φ_monthly, σ_monthly,n=n)

all(result1 .== result2)