import Pkg
Pkg.activate("AR")

include("../table_reader.jl")
include("../utils/Missing_values.jl")
include("../utils/Structure.jl")
include("presutils.jl")
cd(@__DIR__)

series = extract_series("../../mystations/TX_Montpellier.txt", type_data="TX")
series = truncate_MV(series)
years = unique(Dates.year.(series.DATE))

x, date_vec = series[:, 2], series[:, :DATE]

model = fit_AR(x, date_vec)
##Principle
date_range_p = findfirst(series.DATE .== Date(2003, 1, 1)):findfirst(series.DATE .== Date(2004, 1, 1))
x_p, date_vec_p = x[date_range_p], date_vec[date_range_p]


#Series
include("presutils.jl")
curvesvec = [x_p]

colors = ["black"]
# labelvec = ["Recorded temperatures"]

fig = PlotCurves(curvesvec, date_vec_p; colors=colors, ylimits=[-13., 45.], xtlfreq="month")
save("ts.pdf", fig; px_per_unit=2.0)

#3 gen
include("presutils.jl")
sample_ = rand(model, 3, date_vec_p)
fig = PlotCards(sample_, date_vec_p, ylimits=[-13., 45.])
save("3gen.pdf", fig; px_per_unit=2.0)


#5000 gens
sample_ = rand(model, 5000, date_vec_p)
SamplePerDate = invert(sample_)

bands = [(minimum.(SamplePerDate), maximum.(SamplePerDate)), (quantile.(SamplePerDate, 0.25), quantile.(SamplePerDate, 0.75))]

curvesvec = [x_p]

colors = [("#009bff", 0.2), ("#009bff", 0.5), "black"]
labelvec = ["Min-Max interval\nof generated series", "[0.25 ; 0.75] quantile\ninterval of generated\nseries", "Recorded temperatures"]

include("presutils.jl")
fig = PlotCurves(curvesvec, date_vec_p; bands=bands, labelvec=labelvec, colors=colors, ylimits=[-13., 45.], xtlfreq="month")
save("5000gens.pdf", fig; px_per_unit=2.0)

##Series decomposition
date_range_sd = findfirst(series.DATE .== Date(1961, 1, 1)):findfirst(series.DATE .== Date(2019, 1, 1))
x_sd, date_vec_sd = x[date_range_sd], date_vec[date_range_sd]

#complete series
include("presutils.jl")
colors = ["black"]


date_range_c = findfirst(date_vec_sd .== Date(2002, 1, 1)):findfirst(date_vec_sd .== Date(2005, 1, 1))
x_c, date_vec_c = x_sd[date_range_c], date_vec_sd[date_range_c]


fig = PlotCurves(x_c, date_vec_c; colors=colors, ylimits=[-4., 40.], xtlfreq="year")
save("ts2.pdf", fig; px_per_unit=2.0)


#tendency


# f = RegularizationSmooth(x_sd, date_range_sd, 25)
fig = PlotTrend(model)
save("tendency.pdf", fig; px_per_unit=2.0)

#seasonality 
include("../utils/Structure.jl")
include("presutils.jl")
cd(@__DIR__)

fig = PlotSeasonnality(model)
save("seasonality.pdf", fig; px_per_unit=2.0)

#stationnary part 
y = x_sd - trend - periodicity

fig = PlotCurves([y[date_range_leap]],
    date_vec_sd[date_range_leap];
    colors=["blue"],
    ylimits=[-20., 20.],
    size_=(750 * 0.6, 600 * 0.6),
    noylabel=true,
    xtlfreq="month",
    rotate_xtl=true)
save("stationnary.pdf", fig; px_per_unit=2.0)


##Estimation and simulation

include("../utils/Structure.jl")
include("presutils.jl")
cd(@__DIR__)


fig = Figure(size=(700, 275), fontsize=13)

PlotMonthlyStatsAx(fig[1, 1], model.Φ[:,1], "A₁")
PlotMonthlyStatsAx(fig[1, 2], model.σ, "Σ", unit="°C")

save("Monthly_parameters.pdf", fig; px_per_unit=2.0)



###Comparison of trends : Nantes rcp4.5 vs Nantes rcp8.5

include("presutils.jl")

folder_station = "../../DRIAS"
##Station
file1 = folder_station * "/" * "T_Nantes4.txt"
file2 = folder_station * "/" * "T_Nantes8.txt"

df1 = extract_series_DRIAS(file1)
df2 = extract_series_DRIAS(file2)

include("presutils.jl")
fig = CompareTrends(df1,df2)
save("CompareTrendsDRIASNantes.pdf", fig; px_per_unit=2.0)