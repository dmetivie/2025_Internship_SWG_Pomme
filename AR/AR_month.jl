include("table_reader.jl")
include("utils/Missing_values.jl")
include("utils/Structure.jl")
include("utils/Plotting.jl")
cd((@__DIR__))

folder_station = "../mystations"
folder_results = "Results" #do not write "/" at the end
max_p=1
min_k=1 #k = Order of the seasonality
max_k=2

for file_ in readdir(folder_station)
    for p_ in (1:max_p)
        for k in (min_k:max_k)
            folder = folder_results* "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * "/p=$(p_),k=$(k)"

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

            ##Simulations
            n = 3


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
                ("n", n)))


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
                σ_trendparam=σ_trendparam)

            sample_ = rand(Model, n, series.DATE)

            Sample_diagnostic(sample_, Caracteristics_Series, Model, folder=folder, settings=settings)
            save_model(Model,folder * "/model.jld2")
        end
    end
end