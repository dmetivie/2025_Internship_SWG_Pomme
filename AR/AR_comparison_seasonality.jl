using Markdown#hide
md"""
# Load Data
"""

using DataFrames, CSV, Downloads, Dates
using DataFramesMeta, StatsBase
using StatsPlots
url = "https://raw.githubusercontent.com/dmetivie/StochasticWeatherGenerator.jl/master/weather_files/TX_STAID000031.txt"
http_response = Downloads.download(url) # download file from a GitHub repo
df_full = CSV.read(http_response, DataFrame; comment="#", normalizenames=true, dateformat="yyyymmdd", types=Dict(:DATE => Date))
df = @chain df_full begin 
    @subset(:Q_TX .!= 9)
    @transform(:diff = [diff(:DATE);Day(1)])
    @aside beg = _.DATE[findlast(_.diff .> Day(1))]
    @subset(:DATE .> beg)
    @transform(:TX = 0.1*:TX)
end

md"""
# Model AR(1) season
"""
T = 366
M = 1000
degree_trigo = 5
md"""
## Seasonal parametrics parameters

```julia
using Pkg
pkg"registry add https://github.com/dmetivie/LocalRegistry"
```
"""
using SmoothPeriodicStatsModels, StochasticWeatherGenerators

@time "Fit TX" ar1sTX = fit_AR1(df, :TX, degree_trigo)

begin 
    plot(1:T, ar1sTX.σ, label = "σ")
    xticks!(vcat(dayofyear_Leap.(Date.(2000, 1:12)), 366), vcat(string.(monthabbr.(1:12)), ""), xlims=(0, 367), xtickfontsize=14, ytickfontsize=14)
end
begin
    plot(1:T, ar1sTX.μ, label="μ")
    xticks!(vcat(dayofyear_Leap.(Date.(2000, 1:12)), 366), vcat(string.(monthabbr.(1:12)), ""), xlims=(0, 367), xtickfontsize=14, ytickfontsize=14)    
end
begin
    plot(1:T, ar1sTX.ρ, label="φ")
    xticks!(vcat(dayofyear_Leap.(Date.(2000, 1:12)), 366), vcat(string.(monthabbr.(1:12)), ""), xlims=(0, 367), xtickfontsize=14, ytickfontsize=14) 
end


n2t = dayofyear_Leap.(df.DATE)
idx_m = [findall(month.(df.DATE) .== m) for m in 1:12]
@time ts_smooth = [rand(ar1sTX, n2t; y₁ = df.TX[1]) for i in 1:M]

mean_ts = [[mean(ts[idx_m[m]]) for m in 1:12] for ts in ts_smooth] |> stack
std_ts = [[std(ts[idx_m[m]]) for m in 1:12] for ts in ts_smooth] |> stack

md"""
#
"""

md"""
# Plot
"""

df_month = @chain df begin
    @transform(:MONTH = month.(:DATE)) # add month column
    @by(:MONTH, :MONTHLY_MEAN = mean(:TX), :MONTHLY_STD = std(:TX)) # grouby MONTH + takes the mean/std in each category 
end

#-
begin
    @df df_month scatter(monthabbr.(1:12), :MONTHLY_MEAN, label = "Mean Temperature")
    ylabel!("T(°C)")
    errorline!(monthabbr.(1:12), mean_ts, centertype=:median, errortype=:percentile, percentiles=[0, 100], groupcolor=:gray, label = "Simu q0,100")
    errorline!(monthabbr.(1:12), mean_ts, centertype=:median, errortype=:percentile, percentiles=[25, 75], groupcolor=:red, label = "Simu q25,75")
end
#-
begin
    @df df_month scatter(monthabbr.(1:12), :MONTHLY_STD, label = "STD Temperature")
    ylabel!("T(°C)")
    errorline!(monthabbr.(1:12), std_ts, centertype=:median, errortype=:percentile, percentiles=[0, 100], groupcolor=:gray, label = "Simu q0,100")
    errorline!(monthabbr.(1:12), std_ts, centertype=:median, errortype=:percentile, percentiles=[25, 75], groupcolor=:red, label = "Simu q25,75")
    ylims!(2.25,4)
end