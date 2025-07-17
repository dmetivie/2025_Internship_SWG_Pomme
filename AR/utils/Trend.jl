include("utils.jl")

@tryusing "Dates", "LinearAlgebra", "DataInterpolations", "RegularizationTools", "GLM"

try 
    using Loess
catch
    import Pkg;
    Pkg.add(url = "https://github.com/JuliaStats/Loess.jl");
    using Loess
end

function PolyTrendFunc(x, order, index=eachindex(x); return_parameters=false)
    Design = [index .^ i for i in 0:order] |> stack
    beta = inv(transpose(Design) * Design) * transpose(Design) * x
    f(t) = dot(beta, [t^i for i in 0:order])
    return return_parameters ? (f, beta) : f
end


# ========== LOESS ========== #

kernel(u) = (1 - abs(u)^3)^3
Design(t_vec, p) = [(t_vec) .^ i for i in 0:p] |> stack
LOESS_I!(X, Y, W, poly) = dot(((transpose(X) * W * X) \ (transpose(X) * W * Y)), poly)

function MyLOESS(Y, h, X::AbstractArray)
    N = length(Y)
    q = h < 1 ? Int(floor(N * h)) : h
    X_beg, Y_beg = X[1:q, :], Y[1:q]
    X_end, Y_end = X[(N-q):N, :], Y[(N-q):N]
    if isodd(q)
        Begin_interval = 1:((q-1)÷2)
        Middle_weight_index = ((-(q - 1)÷2):((q-1)÷2)) / q
        Middle_interval = ((q-1)÷2+1):(N-(q-1)÷2-1)
        End_interval = (N-(q-1)÷2):N
        trend = [map(i -> LOESS_I!(
                    X_beg,
                    Y_beg,
                    diagm(kernel.(((1:q) .- i) / q)),
                    X[i, :]),
                Begin_interval)
            map(i -> LOESS_I!(
                    X[(i-(q-1)÷2):(i+(q-1)÷2), :],
                    Y[(i-(q-1)÷2):(i+(q-1)÷2)],
                    diagm(kernel.(Middle_weight_index)),
                    X[i, :]),
                Middle_interval)
            map(i -> LOESS_I!(
                    X_end,
                    Y_end,
                    diagm(kernel.((((N-q):N) .- i) / q)),
                    X[i, :]),
                End_interval)]
    else
        Begin_interval = 1:(q÷2)
        Middle_weight_index = ((-q÷2):(q÷2-1)) / q
        Middle_interval = (q÷2+1):(N-q÷2)
        End_interval = (N-q÷2+1):N
        trend = [map(i -> LOESS_I!(
                    X_beg,
                    Y_beg,
                    diagm(kernel.(((1:q) .- i) / q)),
                    X[i, :]),
                Begin_interval)
            map(i -> LOESS_I!(
                    X[(i-q÷2):(i+q÷2-1), :],
                    Y[(i-q÷2):(i+q÷2-1)],
                    diagm(kernel.(Middle_weight_index)),
                    X[i, :]),
                Middle_interval)
            map(i -> LOESS_I!(
                    X_end,
                    Y_end,
                    diagm(kernel.((((N-q):N) .- i) / q)),
                    X[i, :]),
                End_interval)]
    end
    return trend
end

MyLOESS(Y, h, p::Integer) = MyLOESS(Y, h, Design(eachindex(Y), p))

LOESS(x, span=0.4, degree=1) = predict(loess(eachindex(x), x, span=span > 1 ? span / length(x) : span, degree=degree), eachindex(x))


#!!Savoir interpreter span