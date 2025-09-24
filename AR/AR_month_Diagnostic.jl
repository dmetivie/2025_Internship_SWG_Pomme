import Pkg
Pkg.activate(@__DIR__)

include("utils/Structure.jl")
cd(@__DIR__)

folder_results = "Results" #do not write "/" at the end
folder_diagnostic = "Best_Results"

types_data = repeat(["TN", "TG", "TX"], inner=3)
stations = repeat(["Montpellier", "Nantes", "Bonn"], 3)
p = [6, 3, 5, 7, 3, 3, 7, 3, 4]
k = [2, 2, 2, 3, 2, 1, 4, 2, 2]
n = 1000

# for type_data in types_data
#     for station in stations
#         for p_ in p
#             for k_ in k
# folder = folder_results * "/" * type_data * "/" * station * "/p=$(p_),k=$(k_)"

# Model = load_model(folder * "/model.jld2")
# sample_ = rand(Model, n, Model.date_vec, return_res=true)

# Caracteristics_Series = load(folder * "/Caracteristics_Series_Settings.jld2")["cs"]

# Sample_diagnostic(sample_, Caracteristics_Series, Model, folder=folder)

# open(folder * "/Figures" * "_$(p_)_$(k_)" * ".txt", "a") do io
#     println(io, "Number of simulations for the last diagnostic : $(n)")
# end

# println("Diagnostic done : $(folder)")
#             end
#         end
#     end
# end

for (type_data, station, p_, k_) in zip(types_data, stations, p, k)
    folder = folder_results * "/" * type_data * "/" * station * "/p=$(p_),k=$(k_)"
    folder_diag = folder_diagnostic * "/" * type_data * "/" * station * "/p=$(p_),k=$(k_)"

    Model = load_model(folder * "/model.jld2")
    sample_ = rand(Model, n, Model.date_vec, return_res=true)

    Caracteristics_Series = load(folder * "/Caracteristics_Series_Settings.jld2")["cs"]

    Sample_diagnostic(sample_, Caracteristics_Series, Model, folder=folder_diag, size=(1100, 1250))

    open(folder * "/Figures" * "_$(p_)_$(k_)" * ".txt", "a") do io
        println(io, "Number of simulations for the last diagnostic : $(n)")
    end

    println("Diagnostic done : $(folder)")
end