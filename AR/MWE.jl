include("utils/Structure.jl")
cd(@__DIR__)

Φ_month=[[5,2],[-7,1],[1,8],[6,2],[-2,7],[0.5,9],[-3,2],[5,4],[3,1],[-4,3],[3,1],[5,2]] / 10
σ_month=[1.5,2,4.5,7,8,3,4.5,1,7,2.5,3,6]
True_Param = [invert(Φ_month); [σ_month]]
date_vec = Date(0):Date(100)

x=SimulateScenarios([0.,0.1],date_vec, stack(Φ_month,dims=1), σ_month, n=1)

Φ_hat, σ_hat = LL_AR_Estimation_monthly(x[1], date_vec, 2)
Param_hat= [eachcol(Φ_hat); [σ_hat]]

Φ_hat_rand, σ_hat_rand = LL_AR_Estimation_monthly(x[1], date_vec, 2, Nb_try=10)
Param_hat_rand= [eachcol(Φ_hat_rand); [σ_hat_rand]]

param_list = concat2by2mat([True_Param,Param_hat,Param_hat_rand])
Results = map(param->(mean(abs.(param[:,2]-param[:,1])),mean(abs.(param[:,3]-param[:,1]))),param_list)

println("Mean absolute error : Φ1")
println("deterministic init :",Results[1][1])
println("random init :",Results[1][2])
println("Mean absolute error : Φ2")
println("deterministic init :",Results[2][1])
println("random init :",Results[2][2])
println("Mean absolute error : σ")
println("deterministic init :",Results[3][1])
println("random init :",Results[3][2])