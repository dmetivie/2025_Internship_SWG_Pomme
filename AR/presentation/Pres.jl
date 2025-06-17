include("../table_reader.jl")
include("../utils/Missing_values.jl")
include("../utils/Structure.jl")
include("presutils.jl")
cd(@__DIR__)

series = extract_series("../TX_STAID000737.txt", plot=false)
series = truncate_MV(series)
years = unique(Dates.year.(series.DATE))

x, date_vec = series[:, :TX], series[:, :DATE]

model = fit_MonthlyAR(x, date_vec)


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
sample_ = rand(model, date_vec_p, 3)
fig = PlotCards(sample_, date_vec_p)
save("3gen.pdf", fig; px_per_unit=2.0)


#5000 gens
sample_ = rand(model, date_vec_p, 5000)
SamplePerDate = invert(sample_)

bands = [(minimum.(SamplePerDate), maximum.(SamplePerDate)), (quantile.(SamplePerDate, 0.25), quantile.(SamplePerDate, 0.75))]

curvesvec = [x_p]

colors = [("#009bff", 0.2), ("#009bff", 0.5), "black"]
labelvec = ["Min-Max interval of generated series", "[0.25 ; 0.75] quantile interval of generated series", "Recorded temperatures"]

fig = PlotCurves(curvesvec, date_vec_p; bands=bands, labelvec=labelvec, colors=colors, ylimits=[-13., 45.], xtlfreq="month")
save("5000gens.pdf", fig; px_per_unit=2.0)

##Series decomposition
date_range_sd = findfirst(series.DATE .== Date(2002, 1, 1)):findfirst(series.DATE .== Date(2005, 1, 1))
x_sd, date_vec_sd = x[date_range_sd], date_vec[date_range_sd]

#complete series
include("presutils.jl")
colors = ["black"]

fig = PlotCurves(x_sd, date_vec_sd; colors=colors, ylimits=[-4., 40.], xtlfreq="year")
save("ts2.pdf", fig; px_per_unit=2.0)


#tendency
X = cat(ones(length(date_vec_sd)), 1:length(date_vec_sd), dims=2)
beta = inv(transpose(X) * X) * transpose(X) * x_sd


fig = PlotCurves([X * beta .- beta[1]], date_vec_sd; colors=colors, ylimits=[-10., 10.], size_=(750 * 0.6, 600 * 0.6), xtlfreq="year")
save("tendency.pdf", fig; px_per_unit=2.0)

#seasonality 
trigo_function = fitted_periodicity_fonc(x_sd - X * beta, date_vec_sd, OrderTrig=5)
periodicity = trigo_function.(date_vec_sd)

date_range_leap = findfirst(date_vec_sd .== Date(2004, 1, 1)):findfirst(date_vec_sd .== Date(2005, 1, 1))

include("presutils.jl")
fig = PlotCurves([periodicity[date_range_leap] .+ beta[1]],
    date_vec_sd[date_range_leap];
    colors=colors,
    ylimits=[-4., 40.],
    size_=(750 * 0.6, 600 * 0.6),
    noylabel=true,
    xtlfreq="month",
    rotate_xtl=true)
# fig
save("seasonality.pdf", fig; px_per_unit=2.0)

#stationnary part 
y = x_sd - X * beta - periodicity

fig = PlotCurves([y[date_range_leap]],
    date_vec_sd[date_range_leap];
    colors=colors,
    ylimits=[-20., 20.],
    size_=(750 * 0.6, 600 * 0.6),
    noylabel=true,
    xtlfreq="month",
    rotate_xtl=true)
save("stationnary.pdf", fig; px_per_unit=2.0)


##Estimation and simulation

include("presutils.jl")
fig = PlotMonthlyRealStats(series, "standard deviation")
save("monthly_std.pdf", fig; px_per_unit=2.0)