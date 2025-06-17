include("Prev2.jl")

# ======= Apple Phenology ====== #    

"""
    From a series of TG x, his dates in date_vec and the parameters of an apple phenology model, return the Endodormancy break dates and Budburst dates in two vectors respectively.
"""
function Apple_Phenology_Pred(TG_vec::AbstractVector, #tip : put all arguments into one structure
    date_vec::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    DB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.
    for (Tg, date_) in zip(TG_vec, date_vec)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            chilling = true
            sumchilling = 0.
        end
        if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumchilling += Rc(Tg, chilling_model)
            if sumchilling > chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
                push!(DB_vec, date_)
                chilling = false
                forcing = true
                sumforcing = 0.
            end
        end
        if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
            sumforcing += Rf(Tg, forcing_model)
            if sumforcing > forcing_target
                push!(BB_vec, date_)
                forcing = false
            end
        end
    end
    return DB_vec, BB_vec
end


function Apple_Phenology_Pred(temp::AbstracTemperature;
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    return Apple_Phenology_Pred(temp.df[:, 2],
        temp.df.DATE,
        CPO=CPO,
        chilling_model=chilling_model,
        chilling_target=chilling_target,
        forcing_model=forcing_model,
        forcing_target=forcing_target)
end

function Apple_Phenology_Pred(file_TG::String;
    CPO::Tuple{<:Integer,<:Integer}=(10, 30),
    chilling_model::AbstractAction=TriangularAction(1.1, 20.),
    chilling_target::AbstractFloat=56.0,
    forcing_model::AbstractAction=ExponentialAction(9.0),
    forcing_target::AbstractFloat=83.58)
    return Apple_Phenology_Pred(initTG(file_TG),
        CPO=CPO,
        chilling_model=chilling_model,
        chilling_target=chilling_target,
        forcing_model=forcing_model,
        forcing_target=forcing_target)
end


# ======= Vine Phenology ====== #    

"""
Transforms T*(h,n) (called Th_raw here) into T(h,n) 
"""
Tcorrector(Th_raw, TOBc, TMBc) = (Th_raw - TOBc) * (TOBc <= Th_raw <= TMBc) + (TMBc - TOBc) * (TMBc < Th_raw)

"""
    From a series of TN Tn_vec, a series of TX Tx_vec, their dates in date_vec and the parameters of an vine phenology model, return the Endodormancy break dates and Budburst dates in two vectors respectively.
"""
function Vine_Phenology_Pred(Tn_vec::AbstractVector, #tip : put all arguments into one structure
    Tx_vec::AbstractVector,
    date_vec::AbstractVector{Date};
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.)

    DB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.

    locTcorrector(Th_raw) = Tcorrector(Th_raw, T0Bc, TMBc)

    for (Tn, Tx, date_, Tn1) in zip(Tn_vec[1:(end-1)], Tx_vec[1:(end-1)], date_vec[1:(end-1)], Tn_vec[2:end]) #Tn1 = TN(n+1)
        if (month(date_), day(date_)) == CPO #If it's the start of the chilling 
            chilling = true
            sumchilling = 0.
        end
        if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumchilling += Q10^(-(Tx / 10)) + Q10^(-(Tn / 10))
            if sumchilling > Cc #When the sum is superior to the chilling target, we switch to the second part which is forcing.
                push!(DB_vec, date_)
                chilling = false
                forcing = true
                sumforcing = 0.
            end
        end
        if forcing #For forcing, it's the same logic, and in the end we get the budburst date.

            #The vector containing T*(h,n) for h in 1:24
            Th_raw_vec = [Tn .+ (1:12) .* ((Tx - Tn) / 12); Tx .- (1:12) .* ((Tx - Tn1) / 12)]

            sumforcing += sum(locTcorrector.(Th_raw_vec)) # = Ac(n)

            if sumforcing > Ghc
                push!(BB_vec, date_)
                forcing = false
            end
        end
    end
    return DB_vec, BB_vec
end

function Vine_Phenology_Pred(
    file_TN::String,
    file_TX::String;
    CPO::Tuple{<:Integer,<:Integer}=(8, 1),
    Q10::AbstractFloat=2.17,
    Cc::AbstractFloat=119.0,
    T0Bc::AbstractFloat=8.19,
    TMBc::AbstractFloat=25.,
    Ghc::AbstractFloat=13236.)

    TNdf = truncate_MV(extract_series(file_TN))
    TXdf = truncate_MV(extract_series(file_TX))
    if TNdf.DATE != TXdf.DATE #If the timelines are differents, we take the common timeline of the two series.
        date_vec = max(TNdf.DATE[1], TXdf.DATE[1]):min(TNdf.DATE[end], TXdf.DATE[end])
        TN_vec = TNdf.TN[findfirst(TNdf.DATE .== date_vec[1]):findfirst(TNdf.DATE .== date_vec[end])]
        TX_vec = TXdf.TX[findfirst(TXdf.DATE .== date_vec[1]):findfirst(TXdf.DATE .== date_vec[end])]
        return Vine_Phenology_Pred(TN_vec, TX_vec, date_vec, CPO=CPO, Q10=Q10, Cc=Cc, T0Bc=T0Bc, TMBc=TMBc, Ghc=Ghc)
    else
        return Vine_Phenology_Pred(TNdf.TN, TXdf.TX, TNdf.DATE, CPO=CPO, Q10=Q10, Cc=Cc, T0Bc=T0Bc, TMBc=TMBc, Ghc=Ghc)
    end
end


function Vine_Phenology_Pred(M::VinePhenoModel)

    DB_vec = Date[]
    BB_vec = Date[]
    state = 0 # 0 for summer, 1 for chilling, 2 for forcing
    sumact = 0.

    locTcorrector(Th_raw) = Tcorrector(Th_raw, M.T0Bc, M.TMBc)

    for i in 1:(length(M.DATE)-1)
        if (month(M.DATE[i]), day(M.DATE[i])) == M.CPO #If it's the start of the chilling 
            state = 1
        end
        if state == 1 #During chilling, each day we sum the chilling action function applied to the daily temperature.
            sumact += M.Q10^(-(M.TX_vec[i] / 10)) + M.Q10^(-(M.TN_vec[i] / 10))
            if sumact > M.Cc #When the sum is superior to the chilling target, we switch to the second part which is forcing.
                push!(DB_vec, M.DATE[i])
                state = 2
                sumact = 0.
            end
        end
        if state == 2 #For forcing, it's the same logic, and in the end we get the budburst date.

            #The vector containing T*(h,n) for h in 1:24
            Th_raw_vec = [M.TN_vec[i] .+ (1:12) .* ((M.TX_vec[i] - M.TN_vec[i]) / 12); M.TX_vec[i] .- (1:12) .* ((M.TX_vec[i] .- M.TN_vec[i+1]) / 12)]

            sumact += sum(locTcorrector.(Th_raw_vec)) # = Ac(n)

            if sumact > M.Ghc
                push!(BB_vec, M.DATE[i])
                state = 0
                sumact = 0.
            end
        end
    end
    return DB_vec, BB_vec
end
