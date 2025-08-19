include("utils/Structure.jl")
cd((@__DIR__))

folder_station = "../mystations"
folder_results = "Results" #do not write "/" at the end
# min_p = 1
# max_p = 7
# min_k = 4 #k = Order of the seasonality
# max_k = 10

# for rand_init in (true, false)
#     rand_init_file = rand_init ? "/rand_init" : ""
# folder = folder_results * "/" * (file_[1:2]) * "/" * (file_[4:(end-4)]) * rand_init_file * "/p=$(p_),k=$(k)"

collectp(Model::MonthlyAR) = length(Model.y₁)
collectp(Model::Multi_MonthlyAR) = collectpdx0(Model.y₁)[1]

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

for type_data in ["TG", "TN", "TX"]
    for station in readdir(folder_results * "/" * type_data)
        for couple_param in readdir(folder_results * "/" * type_data * "/" * station)
            folder = folder_results * "/" * type_data * "/" * station * "/" * couple_param

            Model = load_model(folder * "/model.jld2")

            N = length(Model.z)
            k = Model.period_order
            p = collectp(Model)
            # σk = Model.σ_period_order
            z = Model.z
            SRS = sum((Model.σ_trend .* Model.σ_period[dayofyear_Leap.(Model.date_vec)] .* z) .^ 2)
            σSRS = sum(((z .^ 2 .- 1) .* Model.σ_period[dayofyear_Leap.(Model.date_vec)] .^ 2) .^ 2)

            AIC_seas_ = AIC_seas(N, 2k + 1, SRS)
            BIC_seas_ = BIC_seas(N, 2k + 1, SRS)
            AIC_σseas_ = AIC_seas(N, 2k + 1, σSRS)
            BIC_σseas_ = BIC_seas(N, 2k + 1, σSRS)

            n2m = month.(Model.date_vec)
            nb_params = length(Model.Φ) + length(Model.σ)

            Opp_LL = Opp_Log_Monthly_Likelihood_AR(Model, z, n2m, p, N)
            AIC_Res = 2 * Opp_LL + 2nb_params
            BIC_Res = 2 * Opp_LL + nb_params * log(N - p)

            Opp_LL_complete = Opp_Log_Monthly_Likelihood_AR_nspart(Model, z, n2m, p, N)
            AIC_complete = 2 * Opp_LL_complete + 2(nb_params + 2 * (2k + 1))
            BIC_complete = 2 * Opp_LL_complete + (nb_params + 2 * (2k + 1)) * log(N)

            push!(DF, (station, type_data, p, k, AIC_complete, BIC_complete, AIC_Res, BIC_Res, AIC_seas_, BIC_seas_, AIC_σseas_, BIC_σseas_))

            # open(folder * "/Figures" * "_$(p)_$(k)" * ".txt", "a") do io

            #     println(io, "AIC_BIC :\n \n")
            #     println(io, "AIC of model : $(AIC_Res)")
            #     println(io, "BIC of model : $(BIC_Res)\n")
            #     println(io, "AIC of AR model on residuals : $(AIC_Res)")
            #     println(io, "BIC of AR model on residuals : $(BIC_Res)\n")
            #     println(io, "AIC of regression to estimate additive seasonality : $(AIC_seas_)")
            #     println(io, "BIC of regression to estimate additive seasonality : $(BIC_seas_)\n")
            #     println(io, "AIC of regression to estimate mutliplicative seasonality : $(AIC_σseas_)")
            #     println(io, "BIC of regression to estimate mutliplicative seasonality : $(BIC_σseas_)")
            # end
        end
    end
end
save("AIC_BIC_Table.jld2", "DF", DF)
# end

# DF = load("AIC_BIC_Table.jld2", "DF")

# println(DF)

Station = "Montpellier"
TypeData = "TX"
p = 4
k = 5

Sub_df = @chain DF begin
    @rsubset :Station == Station
    @rsubset :TypeData == TypeData
    # @rsubset :p == p
end

# println(Sub_df)

println("AIC_complete")
Sub_df_AIC_comp = sort(Sub_df, :AIC_complete)
display(Sub_df_AIC_comp)

println("BIC_complete")
Sub_df_BIC_comp = sort(Sub_df, :BIC_complete)
display(Sub_df_BIC_comp)

println("AIC_Res")
Sub_df_AIC_Res = sort(Sub_df, :AIC_Res)
display(Sub_df_AIC_Res)

println("BIC_Res")
Sub_df_BIC_Res = sort(Sub_df, :BIC_Res)
display(Sub_df_BIC_Res)

println("AIC_Seas")
Sub_df_AIC_Seas = sort(Sub_df, :AIC_Seas)
display(Sub_df_AIC_Seas)

println("BIC_Seas")
Sub_df_BIC_Seas = sort(Sub_df, :BIC_Seas)
display(Sub_df_BIC_Seas)
    
println("AIC_σSeas")
Sub_df_AIC_σSeas = sort(Sub_df, :AIC_σSeas)
display(Sub_df_AIC_σSeas)

println("BIC_σSeas")
Sub_df_BIC_σSeas = sort(Sub_df, :BIC_σSeas)