include("../table_reader.jl")
include("../Prev2.jl")
include("../PhenoPred.jl")
include("presutils.jl")
include("../../AR/utils/Structure.jl")

series = extract_series("../TG_STAID000737.txt", plot=false)
series = truncate_MV(series)
years = unique(Dates.year.(series.DATE))

x, date_vec = series[:, :TG], series[:, :DATE]

model = fit_MonthlyAR(x, date_vec)


##Principle
date_range_p = findfirst(series.DATE .== Date(2002, 10, 25)):findfirst(series.DATE .== Date(2003, 7, 1))
x_p, date_vec_p = x[date_range_p], date_vec[date_range_p]

include("presutils.jl")
fig = PlotCurveApple(x_p, date_vec_p)
save("Apple_phenology_Lille_2003.png", fig; px_per_unit=2.0)
# fig = PlotCurves(curvesvec, date_vec_p; colors=colors, ylimits=[-4., 45.], smallscale=true)
# save("ts.png", fig; px_per_unit=2.0)

