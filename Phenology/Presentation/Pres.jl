include("../table_reader.jl")
include("../Prev2.jl")
include("../PhenoPred.jl")
include("presutils.jl")
include("../../AR/utils/Structure.jl")
cd(@__DIR__)

# series = extract_series("../TG_STAID000737.txt", plot=false)
# series = truncate_MV(series)
# years = unique(Dates.year.(series.DATE))

# x, date_vec = series[:, :TG], series[:, :DATE]

# model = fit_AR(x, date_vec)


##Principle
# date_range_p = findfirst(series.DATE .== Date(2002, 10, 25)):findfirst(series.DATE .== Date(2003, 7, 1))
# x_p, date_vec_p = x[date_range_p], date_vec[date_range_p]

# fig = PlotCurveApple(x_p, date_vec_p)
# save("Apple_phenology_Lille_2003.pdf", fig; px_per_unit=2.0)
# fig = PlotCurves(curvesvec, date_vec_p; colors=colors, ylimits=[-4., 45.], smallscale=true)
# save("ts.pdf", fig; px_per_unit=2.0)


commonpath = "../../mystations"

TG_temp = initTG(commonpath * "/TG_Bonn.txt")
TN_temp = initTN(commonpath * "/TN_Bonn.txt")

year_ = 1981

date_range_TN = findfirst(TN_temp.df.DATE .== Date(year_-1, 9, 1)):findfirst(TN_temp.df.DATE .== Date(year_, 7, 1))
x_TN, date_vec = TN_temp.df.TN[date_range_TN], TN_temp.df.DATE[date_range_TN]

x_TG = TG_temp.df.TG[findfirst(TG_temp.df.DATE .== Date(year_-1, 9, 1)):findfirst(TG_temp.df.DATE .== Date(year_, 7, 1))]

include("presutils.jl")

fig = PlotCurveApple(x_TG, date_vec ; TN_vec=x_TN, threshold=-2.)
save("Apple_phenology_Bonn_2024.pdf", fig; px_per_unit=2.0)



####Artificial risk of freezing for generated data####

using Distributions

##Artificial data##
f(t) = pdf(Normal(1, 3), t)
Mat = ones((7, 46))
for date in 1980:2025
    for m in 1:7
        Mat[m, date-1979] = max(rand(Poisson(6exp(0.06(date - 1979)) * f(m))) - 1, 0)
    end
end
Mat

Mat = Mat / sum(Mat)

##Heatmap##
yearvec = 1980:2025

interestingyear = yearvec[[any(Mat[:, year-1979] .>= 0.015) for year in yearvec]]

fig = Figure(size=(700,350))
ax = Axis(fig[1, 1],
    xticks=([1980:10:2025; interestingyear]),
    xticklabelrotation=65 * 2π / 360,
    xlabel = "Year",
    yticks=1:7,
    ylabel = "Days",
    title = "Annual frequency of max number of consecutives days with TN ≤ -2°C\nafter budburst, for simulated temperatures",
    titlesize=15
    )


heatplt = heatmap!(ax, 1980:2025, 1:7, transpose(Mat))
Colorbar(fig[:, end+1], heatplt)
save("Days_frequency.pdf", fig; px_per_unit=2.0)