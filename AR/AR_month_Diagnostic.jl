include("utils/Structure.jl")
cd(@__DIR__)

folder_results = "Results" #do not write "/" at the end

types_data = ["TG"]
stations = ["Montpellier"]
p = 2
k = 1:2
n = 1000

for type_data in types_data
    for station in stations
        for p_ in p
            for k_ in k
                folder = folder_results * "/" * type_data * "/" * station * "/p=$(p_),k=$(k_)"

                Model = load_model(folder * "/model.jld2")
                sample_ = rand(Model, n, Model.date_vec, return_res=true)

                Caracteristics_Series = load(folder * "/Caracteristics_Series_Settings.jld2")["cs"]

                Sample_diagnostic(sample_, Caracteristics_Series, Model, folder=folder)

                open(folder * "/Figures" * "_$(p_)_$(k_)" * ".txt", "a") do io
                    println(io, "Number of simulations for the last diagnostic : $(n)")
                end

                println("Diagnostic done : $(folder)")
            end
        end
    end
end