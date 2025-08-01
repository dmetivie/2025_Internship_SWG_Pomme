include("utils/Structure.jl")
cd((@__DIR__))

folder_station = "../mystations"
folder_results = "Results" #do not write "/" at the end
min_p = 2
max_p = 7
min_k = 4 #k = Order of the seasonality
max_k = 10

# for rand_init in (true, false)
#     rand_init_file = rand_init ? "/rand_init" : ""
# folder = folder_results * "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * rand_init_file * "/p=$(p_),k=$(k)"
DF = DataFrame(Station=String[],
    TypeData=String[],
    p=Integer[],
    k=Integer[],
    AIC_complete=AbstractFloat[],
    BIC_complete=AbstractFloat[],
    AIC_Res=AbstractFloat[],
    BIC_Res=AbstractFloat[],
    AIC_Seas=AbstractFloat[],
    BIC_Seas=AbstractFloat[],
    AIC_σSeas=AbstractFloat[],
    BIC_σSeas=AbstractFloat[])

for file_ in readdir(folder_station)
    for p in (min_p:max_p)
        for k in (min_k:max_k)
            folder = folder_results * "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * "/p=$(p),k=$(k)"

            Model = load_model(folder * "/model.jld2")

            N = length(Model.z)
            # k = Model.period_order
            # σk = Model.σ_period_order
            z = Model.z
            SRS = sum((Model.σ_trend .* Model.σ_period[dayofyear_Leap.(Model.date_vec)] .* z) .^ 2)
            σSRS = sum(((z .^ 2 .- 1) .* Model.σ_period[dayofyear_Leap.(Model.date_vec)] .^ 2) .^ 2)

            AIC_seas_ = AIC_seas(N, 2k+1, SRS)
            BIC_seas_ = BIC_seas(N, 2k+1, SRS)
            AIC_σseas_ = AIC_seas(N, 2k+1, σSRS)
            BIC_σseas_ = BIC_seas(N, 2k+1, σSRS)

            n2m = month.(Model.date_vec)
            nb_params = length(Model.Φ) + length(Model.σ)

            Opp_LL = Opp_Log_Monthly_Likelihood_AR(Model, z, n2m, p, N)
            AIC_Res = 2 * Opp_LL + 2nb_params
            BIC_Res = 2 * Opp_LL + nb_params * log(N-p)

            Opp_LL_complete = Opp_Log_Monthly_Likelihood_AR_nspart(Model, z, n2m, p, N)
            AIC_complete = 2 * Opp_LL_complete + 2(nb_params + 2 * (2k+1))
            BIC_complete = 2 * Opp_LL_complete + (nb_params + 2 * (2k+1)) * log(N)

            push!(DF, (file_[4:(end-4)], file_[1:2], p, k, AIC_complete, BIC_complete, AIC_Res, BIC_Res, AIC_seas_, BIC_seas_, AIC_σseas_, BIC_σseas_))

            open(folder * "/Figures" * "_$(p)_$(k)" * ".txt", "a") do io

                println(io, "AIC_BIC :\n \n")
                println(io, "AIC of model : $(AIC_Res)")
                println(io, "BIC of model : $(BIC_Res)\n")
                println(io, "AIC of AR model on residuals : $(AIC_Res)")
                println(io, "BIC of AR model on residuals : $(BIC_Res)\n")
                println(io, "AIC of regression to estimate additive seasonality : $(AIC_seas_)")
                println(io, "BIC of regression to estimate additive seasonality : $(BIC_seas_)\n")
                println(io, "AIC of regression to estimate mutliplicative seasonality : $(AIC_σseas_)")
                println(io, "BIC of regression to estimate mutliplicative seasonality : $(BIC_σseas_)")
            end
        end
    end
end
save("AIC_BIC_Table.jld2", "DF", DF)
# end

println(DF)

Station = "Montpellier"
TypeData = "TN"
p = 4
k = 5

Sub_df = @chain DF begin
    @rsubset :Station == Station
    @rsubset :TypeData == TypeData
    @rsubset :k == k
end

println(Sub_df)