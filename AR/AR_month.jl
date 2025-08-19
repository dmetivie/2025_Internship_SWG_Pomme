include("table_reader.jl")
include("utils/Structure.jl")
cd(@__DIR__)

Diagnostic = false
folder_station = "../mystations"
folder_results = "Results" #do not write "/" at the end
min_p = 2
max_p = 2
min_k = 1 #k = Order of the seasonality
max_k = 10

# for rand_init in (true, false)
#     rand_init_file = rand_init ? "/rand_init" : ""
# folder = folder_results * "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * rand_init_file * "/p=$(p_),k=$(k)"
T0 = time()


for file_ in readdir(folder_station)
    for p_ in (min_p:max_p)
        for k in (min_k:max_k)
            folder = folder_results * "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * "/p=$(p_),k=$(k)"

            ##Station
            file = folder_station * "/" * file_

            ##AR model
            p = p_
            method_ = "monthlyLL"                 # "mean", "median", "concat", "sumLL", "monthlyLL"
            periodicity_model = "trigo"           # "trigo", "smooth", "autotrigo", "stepwise_trigo"
            degree_period = k                     # 0 => default value -> "trigo" : 5, "smooth" : 9, "autotrigo" : 50, "stepwise_trigo" : 50
            Trendtype = "LOESS"                   # "LOESS", "polynomial", "null" (for no additive trend)
            trendparam = nothing                  # nothing => default value -> "LOESS" : 0.08, "polynomial" : 1
            σ_periodicity_model = "trigo"         # "trigo", "smooth", "autotrigo", "stepwise_trigo", "null" (for no multiplicative periodicity)
            σ_degree_period = k                   # 0 => default value -> "trigo" : 5, "smooth" : 9, "autotrigo" : 50, "stepwise_trigo" : 50
            σ_Trendtype = "LOESS"                 # "LOESS", "polynomial", "null" (for no multiplicative trend)
            σ_trendparam = nothing                # nothing => default value -> "LOESS" : 0.08, "polynomial" : 1
            Nb_try = 20

            ##Simulations
            n = 1200 #useless if Diagnostic == false


            settings = OrderedDict((("file", file),
                ("p", p),
                ("method_", method_),
                ("periodicity_model", periodicity_model),
                ("degree_period", degree_period),
                ("Trendtype", Trendtype),
                ("trendparam", trendparam),
                ("σ_periodicity_model", σ_periodicity_model),
                ("σ_degree_period", σ_degree_period),
                ("σ_Trendtype", σ_Trendtype),
                ("σ_trendparam", σ_trendparam),
                ("Number of random initialization", Nb_try)))


            series = extract_series(file, plot=false)
            series = truncate_MV(series)
            years = unique(Dates.year.(series.DATE))

            Caracteristics_Series = init_CaracteristicsSeries(series)

            Model = fit_AR(series[:, 2], series.DATE,
                p=p,
                method_=method_,
                periodicity_model=periodicity_model,
                degree_period=degree_period,
                Trendtype=Trendtype,
                trendparam=trendparam,
                σ_periodicity_model=σ_periodicity_model,
                σ_degree_period=σ_degree_period,
                σ_Trendtype=σ_Trendtype,
                σ_trendparam=σ_trendparam,
                Nb_try=Nb_try)

            save_model(Model, folder * "/model.jld2")
            save(folder * "/Caracteristics_Series_Settings.jld2", "cs", Caracteristics_Series) #useful if we want to re-sample

            if Diagnostic
                sample_ = rand(Model, n, series.DATE, return_res=true)
                Sample_diagnostic(sample_, Caracteristics_Series, Model, folder=folder, settings=settings)
            else
                open(folder * "/Figures" * "_$(p_)_$(k)" * ".txt", "a") do io
                    println(io, "Settings :\n")
                    for key in keys(settings)
                        println(io, "$(key) : $(settings[key])")
                    end
                end
            end

            dt = time() - T0
            min_, scds = Int(floor(dt ÷ 60)), Int(floor(dt % 60))

            println("Model done : " * (file_[1:2]) * "/" * (file_[4:(end-4)]) * "/p=$(p_),k=$(k) in $(min_) min, $(scds) s")
        end
    end
end

# end
println("Finished !")