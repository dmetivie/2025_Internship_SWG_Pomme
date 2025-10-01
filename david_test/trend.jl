cd(@__DIR__)
import Pkg;
Pkg.activate(".");
using DataFrames, CSV, DataFramesMeta, Dates, StatsBase
using Distributions
using CairoMakie
using GLMakie

using Colors
mycolors = RGB{Float64}[RGB(0.0, 0.6056031704619725, 0.9786801190138923), RGB(0.24222393333911896, 0.6432750821113586, 0.304448664188385), RGB(0.7644400000572205, 0.4441118538379669, 0.8242975473403931), RGB(0.8888735440600661, 0.435649148506399, 0.2781230452972766), RGB(0.6755439043045044, 0.5556622743606567, 0.09423444420099258), RGB(0.0, 0.6657590270042419, 0.6809969544410706), RGB(0.9307674765586853, 0.3674771189689636, 0.5757699012756348), RGB(0.776981770992279, 0.5097429752349854, 0.14642538130283356), RGB(5.29969987894674e-8, 0.6642677187919617, 0.5529508590698242), RGB(0.558464765548706, 0.59348464012146, 0.11748137325048447), RGB(0.0, 0.6608786582946777, 0.7981787919998169), RGB(0.609670877456665, 0.49918484687805176, 0.9117812514305115), RGB(0.38000133633613586, 0.5510532855987549, 0.9665056467056274), RGB(0.9421815872192383, 0.3751642107963562, 0.4518167972564697), RGB(0.8684020638465881, 0.39598923921585083, 0.7135148048400879), RGB(0.4231467843055725, 0.6224954128265381, 0.19877080619335175)];

GLMakie.activate!()

df_full = CSV.read("../AR/TX_STAID000031.txt", DataFrame, normalizenames=true, skipto=22, header=21, ignoreemptyrows=true, dateformat="yyyymmdd", types=Dict(:DATE => Date))
df = @chain df_full begin
    @subset(:Q_TX .!= 9)
    @transform(:TX = :TX / 10)
    @subset(2003 .> year.(:DATE) .≥ 1950)
    @select(:DATE, :TX, :STAID, :SOUID)
end

T_df = @chain df begin
    @transform(:YEAR = year.(:DATE), :MONTH = month.(:DATE))
    @by([:YEAR, :MONTH], :M_T = mean(:TX), :S_T = std(:TX))
end
T_m_df = groupby(T_df, :MONTH)

unique_years = unique(year.(df.DATE))
begin
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly average of daily maximum temperatures")
    lines!(ax, T_df.YEAR .+ (T_df.MONTH .- 0.5) / 12, T_df.M_T)
    fig
end

begin
    fig = Figure(size=(1000, 800))
    ax = Axis(fig[1, 1][1, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly average of daily maximum temperatures")
    for d in T_m_df
        lines!(ax, d.YEAR, d.M_T, label=monthabbr(d.MONTH[1]))
    end
    ax_std = Axis(fig[2, 1][1, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly std of daily maximum temperatures")
    for d in T_m_df
        lines!(ax_std, d.YEAR, d.S_T, label=monthabbr(d.MONTH[1]))
    end
    Legend(fig[1, 1][2, 1], ax, orientation=:horizontal)
    Legend(fig[2, 1][2, 1], ax_std, orientation=:horizontal)
    DataInspector(fig)
    fig
end

using ConcreteStructs
using ComponentArrays

const_then_linear(x, θ) = x ≤ θ.t ? θ.c : θ.c + θ.a * (x - θ.t)
const_then_linear0(x, θ) = x ≤ θ.t ? zero(x) : θ.a * (x - θ.t)
const_then_linear0(x, a, t) = x ≤ t ? zero(x) : a * (x - t)

μₜ(t, θ::AbstractArray) = polynomial_trigo(t, θ[:]) # not constrained
αₜ(t, θ::AbstractArray) = 1 / (1 + exp(-polynomial_trigo(t, θ[:]))) # [0,1] parameter
σₜ(t, θ::AbstractArray) = exp(polynomial_trigo(t, θ[:])) # >0 parameter
ρₜ(t, θ::AbstractArray) = 2 / (1 + exp(-polynomial_trigo(t, θ[:]))) - 1 # [-1,1]
dayofyear_Leap(d) = @. dayofyear(d) + ((!isleapyear(d)) & (month(d) > 2))

"""
    Merge vectors with alternate elements
    For example
    ```julia
    x = [x₁, x₂]
    y = [y₁, y₂]
    interleave2(x, y) = [x₁, y₁, x₂, y₂]
    ```
"""
interleave2(args...) = collect(Iterators.flatten(zip(args...)))

"""
    polynomial_trigo(t, β)
"""
function polynomial_trigo(t, β)
    d = (length(β) - 1) ÷ 2
    # everything is shifted from 1 from usual notation due to array starting at 1
    return β[1] + sum(β[2*l] * cos(2π * l * t) + β[2*l+1] * sin(2π * l * t) for l = 1:d; init=zero(t))
end

T = 366 # period
make_φ(n, t, θ, p) = ρₜ(t / T, θ)
make_μ(n, t, θ, p) = μₜ(t / T, θ.θS) + const_then_linear0(n, μₜ(t / T, θ.θCa), p.θCt)
make_σ(n, t, θ, p) = σₜ(t / T, θ.θS) * abs((1 + const_then_linear0(n, μₜ(t / T, θ.θCa), p.θCt)))

make_μ0(n, t, θ, p) = μₜ(t / T, θ.θS)
make_σ0(n, t, θ, p) = σₜ(t / T, θ.θS)

@concrete struct AR
    φ
    μ
    σ
end
logpdf_AR(AR, y, n, t) = logpdf(Normal(AR.μ(n, t) + sum(AR.φ[i](n, t) * y[n-i] for i in eachindex(AR.φ)), AR.σ(n, t)), y[n])
# - (y[n] - sum(AR.φ[i](n, t) * y[n-i] for i in eachindex(AR.φ)) - AR.μ(n, t))^2 / (2 * AR.σ(n, t)^2) + log(AR.σ(n, t))

function loglik_AR(ARs, y, n2t)
    memory = length(ARs.φ)
    return sum(logpdf_AR(ARs, y, n, n2t[n]) for n in (memory+1):length(y))
end

function optim_ll(θ, p)
    φs = [(n, t) -> make_φ(n, t, θ.φ[i], p) for i in eachindex(θ.φ)]
    μ(n, t) = make_μ(n, t, θ.μ, p)
    σ(n, t) = make_σ(n, t, θ.σ, p)
    ARs = AR(φs, μ, σ)
    return -loglik_AR(ARs, p.y, n2t)
end

function optim_ll0(θ, p)
    φs = [(n, t) -> make_φ(n, t, θ.φ[i], p) for i in eachindex(θ.φ)]
    μ(n, t) = make_μ0(n, t, θ.μ, p)
    σ(n, t) = make_σ0(n, t, θ.σ, p)
    ARs = AR(φs, μ, σ)
    return -loglik_AR(ARs, p.y, n2t)
end

n2t = dayofyear_Leap.(df.DATE)
y = df.TX

using Optimization, ForwardDiff
using OptimizationOptimJL


# using StochasticWeatherGenerators, SmoothPeriodicStatsModels
# @time "Fit TX" ar1sTX = fit_AR1(df, :TX, 1)

# fit_μ(u, p) = sum(abs2, μₜ(t / T, u) - ar1sTX.μ[t] for t in 1:T)
# u0 = [3, 0., 0.0]
# optf_fit0 = OptimizationFunction(fit_μ, AutoForwardDiff())
# prob_fit0 = OptimizationProblem(optf_fit0, u0)
# @time "optimization 0" θ_μ0 = solve(prob_fit0, BFGS())


# fit_φ(u, p) = sum(abs2, ρₜ(t / T, u) - ar1sTX.ρ[t] for t in 1:T)
# u0 = [3, 0., 0.0]
# optf_fit0 = OptimizationFunction(fit_φ, AutoForwardDiff())
# prob_fit0 = OptimizationProblem(optf_fit0, u0)
# @time "optimization 0" θ_φ0 = solve(prob_fit0, BFGS())

# fit_σ(u, p) = sum(abs2, σₜ(t / T, u) - ar1sTX.σ[t] for t in 1:T)
# u0 = [0, 0., 0.0]
# optf_fit0 = OptimizationFunction(fit_σ, AutoForwardDiff())
# prob_fit0 = OptimizationProblem(optf_fit0, u0)
# @time "optimization 0" θ_σ0 = solve(prob_fit0, BFGS())


GLMakie.activate!()

CairoMakie.activate!()

θ0 = ComponentArray(φ=[[1.7, 0.002, -0.180]], μ=ComponentArray(θS=[5, -2.39, 0.06]), σ=ComponentArray(θS=[0.78, 0.05, 0.06]))
optf0 = OptimizationFunction(optim_ll0, AutoForwardDiff())
prob0 = OptimizationProblem(optf0, θ0, ComponentArray(y=y))
@time "optimization 0" sol0 = solve(prob0, OptimizationOptimJL.BFGS())

global_warming_start = Date(1969, 1, 1)
n_C = findfirst(df.DATE .== global_warming_start)
p = ComponentArray(y=y, θCt=n_C)

θ = ComponentArray(φ=[[1.7, 0.002, -0.180]], μ=ComponentArray(θS=[5, -2.39, 0.06], θCa=[0.0, 0.0, 0.0]), σ=ComponentArray(θS=[0.78, 0.05, 0.06], θCa=[0.0, 0.0, 0.0]))
optf = OptimizationFunction(optim_ll, AutoForwardDiff())
prob = OptimizationProblem(optf, θ, p)

@time "optimization" sol = solve(prob, BFGS())
println(global_warming_start, " objective: ", sol.objective)

@time "optimization NM" sol_NM = solve(prob, NelderMead())


begin
    fig = Figure()
    ax_μ = Makie.Axis(fig[1, 1])
    # lines!(ax_μ, 1:T, ar1sTX.μ, label = "Fitted μ AR(1)")
    # lines!(ax_μ, [μₜ(t/T, θ_μ0) for t in 1:T])
    lines!(ax_μ, 1:T, [μₜ(t / T, sol0.u.μ.θS) for t in 1:T], color=:blue, label="Fitted μ0")
    lines!(ax_μ, 1:T, [μₜ(t / T, sol.u.μ.θS) for t in 1:T], color=:orange, label="Fitted μ")

    ax_φ = Makie.Axis(fig[2, 1])
    # lines!(ax_φ, 1:T, ar1sTX.ρ, label = "Fitted φ AR(1)")
    # lines!(ax_φ, [ρₜ(t/T, θ_φ0) for t in 1:T])
    lines!(ax_φ, 1:T, [ρₜ(t / T, sol0.u.φ[1]) for t in 1:T], color=:blue, label="Fitted φ0")
    lines!(ax_φ, 1:T, [ρₜ(t / T, sol.u.φ[1]) for t in 1:T], color=:orange, label="Fitted φ")

    ax_σ = Makie.Axis(fig[3, 1])
    # lines!(ax_σ, 1:T, ar1sTX.σ, label = "Fitted σ AR(1)")
    # lines!(ax_σ, [σₜ(t/T, θ_σ0) for t in 1:T])
    lines!(ax_σ, 1:T, [σₜ(t / T, sol0.u.σ.θS) for t in 1:T], color=:blue, label="Fitted σ0")
    lines!(ax_σ, 1:T, [σₜ(t / T, sol.u.σ.θS) for t in 1:T], color=:orange, label="Fitted σ")

    ax_trend = Makie.Axis(fig[4, 1])
    lines!(ax_trend, df.DATE, [const_then_linear0(n, μₜ(n2t[n] / T, sol.u.μ.θCa), p.θCt) for n in eachindex(y)], label="μ trend", color=:orange)
    lines!(ax_trend, df.DATE, [1 + const_then_linear0(n, μₜ(n2t[n] / T, sol.u.σ.θCa), p.θCt) for n in eachindex(y)], label="σ trend + 1", color=:orange)

    Legend(fig[1, 2], ax_μ)
    Legend(fig[2, 2], ax_φ)
    Legend(fig[3, 2], ax_σ)
    Legend(fig[4, 2], ax_trend)
    fig
end

φs = [(n, t) -> make_φ(n, t, sol.u.φ[i], p) for i in eachindex(θ.φ)]
μ(n, t) = make_μ(n, t, sol.u.μ, p)
σ(n, t) = make_σ(n, t, sol.u.σ, p)
ARs = AR(φs, μ, σ)

function Base.rand(rng, ARs, n2t; y0)
    y = zeros(length(n2t))
    memory = length(ARs.φ)
    y[1:memory] .= y0
    for n in (memory+1):length(y)
        y[n] = rand(rng, Normal(μ(n, n2t[n]) + sum(ARs.φ[i](n, n2t[n]) * y[n-i] for i in eachindex(ARs.φ)), σ(n, n2t[n])))
    end
    return y
end

using Random
Base.rand(ARs, n2t; y0) = rand(Random.GLOBAL_RNG, ARs, n2t; y0=y0)

N = 100
y_s = zeros(length(y), N)
for i in 1:N
    y_s[:, i] .= rand(ARs, n2t; y0=df.TX[1:1])
end

T_df_simus = map(1:N) do i
    @chain DataFrame(DATE=df.DATE, TX=y_s[:, i]) begin
        @transform(:YEAR = year.(:DATE), :MONTH = month.(:DATE))
        @by([:YEAR, :MONTH], :M_T = mean(:TX), :S_T = std(:TX))
        groupby(:MONTH)
    end
end

swg_M = [[T_df_simus[s][i].M_T[yy] for s in 1:N] for i in 1:12, yy in eachindex(unique_years)]
swg_STD = [[T_df_simus[s][i].S_T[yy] for s in 1:N] for i in 1:12, yy in eachindex(unique_years)]

begin
    fig = Figure(size=(1200, 800))
    ax = Makie.Axis(fig[1, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly average of daily maximum temperatures")
    for m in 1:12
        qqs = [quantile(swg_M[m, yy], [0, 0.25, 0.5, 0.75, 1]) for yy in eachindex(unique_years)]
        band!(ax, unique_years, [qqs[yy][1] for yy in eachindex(unique_years)], [qqs[yy][5] for yy in eachindex(unique_years)], color=mycolors[m], alpha=0.2, label=string(monthabbr(m), " q_5"))
        lines!(ax, unique_years, [qqs[yy][3] for yy in eachindex(unique_years)], alpha=1, color=mycolors[m], linestyle=:dash, label=string(monthabbr(m), " q_25_75"))
        d = T_m_df[m]
        lines!(ax, d.YEAR, d.M_T, label=monthabbr(d.MONTH[1]), color=mycolors[d.MONTH[1]], linewidth=1.5)
    end
    ax_std = Makie.Axis(fig[3, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly std of daily maximum temperatures")
    for m in 1:12
        qqs = [quantile(swg_STD[m, yy], [0, 0.25, 0.5, 0.75, 1]) for yy in eachindex(unique_years)]
        band!(ax_std, unique_years, [qqs[yy][1] for yy in eachindex(unique_years)], [qqs[yy][5] for yy in eachindex(unique_years)], color=mycolors[m], alpha=0.2, label=string(monthabbr(m), " q_5"))
        lines!(ax_std, unique_years, [qqs[yy][3] for yy in eachindex(unique_years)], alpha=1, color=mycolors[m], linestyle=:dash, label=string(monthabbr(m), " q_25_75"))
        d = T_m_df[m]
        lines!(ax_std, d.YEAR, d.S_T, label=monthabbr(d.MONTH[1]), color=mycolors[d.MONTH[1]], linewidth=1.5)
    end
    linkxaxes!(ax, ax_std)
    Legend(fig[2, 1], ax, orientation=:horizontal, nbanks=3, tellwidth=true)
    Legend(fig[4, 1], ax_std, orientation=:horizontal, nbanks=3, tellwidth=true)
    DataInspector(fig)
    fig
end


## yearly

T_df_Y = @chain df begin
    @transform(:YEAR = year.(:DATE))
    @by([:YEAR], :M_T = mean(:TX), :S_T = std(:TX))
end

T_df_simus_Y = map(1:N) do i
    @chain DataFrame(DATE=df.DATE, TX=y_s[:, i]) begin
        @transform(:YEAR = year.(:DATE))
        @by([:YEAR], :M_T = mean(:TX), :S_T = std(:TX))
    end
end

swgY_M = [[T_df_simus_Y[s].M_T[yy] for s in 1:N] for yy in eachindex(unique_years)]
swgY_STD = [[T_df_simus_Y[s].S_T[yy] for s in 1:N] for yy in eachindex(unique_years)]

begin
    fig = Figure(size = (600, 600))
    ax = Makie.Axis(fig[1, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly average of daily maximum temperatures")

    qqs = [quantile(swgY_M[yy], [0, 0.25, 0.5, 0.75, 1]) for yy in eachindex(unique_years)]
    band!(ax, unique_years, [qqs[yy][2] for yy in eachindex(unique_years)], [qqs[yy][4] for yy in eachindex(unique_years)], color=mycolors[1], alpha=0.2, label=string("q_5"))
    lines!(ax, unique_years, [qqs[yy][3] for yy in eachindex(unique_years)], alpha=1, color=mycolors[1], linestyle=:dash, label=string("q_25_75"))

    lines!(ax, T_df_Y.YEAR, T_df_Y.M_T, label="Obs", color=mycolors[1], linewidth=1.5)

    ax_std = Makie.Axis(fig[2, 1], xlabel="Year", ylabel="Temperature (°C)", title="Monthly std of daily maximum temperatures")

    qqs = [quantile(swgY_STD[yy], [0, 0.25, 0.5, 0.75, 1]) for yy in eachindex(unique_years)]
    band!(ax_std, unique_years, [qqs[yy][2] for yy in eachindex(unique_years)], [qqs[yy][4] for yy in eachindex(unique_years)], color=mycolors[2], alpha=0.2, label=string("q_5"))
    lines!(ax_std, unique_years, [qqs[yy][3] for yy in eachindex(unique_years)], alpha=1, color=mycolors[2], linestyle=:dash, label=string("q_25_75"))


    lines!(ax_std, T_df_Y.YEAR, T_df_Y.S_T, label="Obs", color=mycolors[2], linewidth=1.5)

    Legend(fig[1, 2], ax, nbank=2, tellwidth=true)
    Legend(fig[2, 2], ax_std, nbank=2, tellwidth=true)
    DataInspector(fig)
    fig
end