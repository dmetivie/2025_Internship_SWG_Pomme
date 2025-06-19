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

# model = fit_MonthlyAR(x, date_vec)


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

date_range_TN = findfirst(TN_temp.df.DATE .== Date(2023, 9, 1)):findfirst(TN_temp.df.DATE .== Date(2024, 7, 1))
x_TN, date_vec = TN_temp.df.TN[date_range_TN], TN_temp.df.DATE[date_range_TN]

x_TG = TG_temp.df.TG[findfirst(TG_temp.df.DATE .== Date(2023, 9, 1)):findfirst(TG_temp.df.DATE .== Date(2024, 7, 1))]

include("presutils.jl")

fig = PlotCurveApple(x_TG, date_vec ; TN_vec=x_TN, threshold=-2.)
save("Apple_phenology_Bonn_2024.pdf", fig; px_per_unit=2.0)
