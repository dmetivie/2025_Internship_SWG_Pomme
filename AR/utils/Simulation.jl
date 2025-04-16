try
    using Distributions, Dates, LinearAlgebra
catch ;
    import Pkg
    Pkg.add("Distributions")
    Pkg.add("Dates")
    Pkg.add("LinearAlgebra")
    using Distributions, Dates, LinearAlgebra
end

##### SIMULATION #####
"""
    simulation(x::Vector,Φ::Vector,σ::Number,n::Int)

Return a simulation of n steps of an AR(p) model with parameters Φ, standard deviation of noise σ and initial condition x.
"""
function simulation(x::Vector,Φ::Vector,σ::Number,n::Int)
    y,p=copy(x),length(x)
    return simulation!(x,Φ,σ,n,y,p)
end
function simulation!(x::Vector,Φ::Vector,σ,n,y,p)
    for _ in 1:n
        append!(y, dot(y[end:-1:end-p+1],Φ) + σ * randn())
    end
    return y[p+1:end]
end
simulation(x::Number,Φ::Number,σ,n) = simulation([x],[Φ],σ,n)

"""
    sample_simulation(x::Vector,Φ::Vector,σ::Number,n_year::Int,periodicity::Vector)

Return a sample of n_year*size_multiplicator annual simulations of weather, according to the AR(p) model. periodicity is the periodicity component we want to consider.
"""
function sample_simulation(x::Vector,Φ::Vector,σ::Number,periodicity::Vector,n_year::Int=1,size_multiplicator::Int=1)
    Output=[]
    p=length(x)
    for _ in 1:size_multiplicator
        simulated=simulation(x,Φ,σ,365*(n_year+1)-p) + periodicity[(1+p):365*(n_year+1)]
        append!(Output,[simulated[(365i+1-p):365*(i+1)-p] for i in 1:n_year]) #We do not put the first period
    end
    return Output
end
sample_simulation(x::Number,Φ::Number,σ::Number,periodicity::Vector,n_year::Int=1,size_multiplicator::Int=1)=sample_simulation(x[1],Φ[1],σ,n_year,periodicity,n_year,size_multiplicator)

"""
    SimulateMonth(x0,day_one,Φ_month,σ_month,n_month)

Return a simulation of a month-conditional AR(p) model (one AR(p) model for each month), for n_month starting from day_one with x0[end].
Unless day_one is the last day of his month, the current month of day_one is included in n_month.  
"""
function SimulateMonth(x0::Number,day_one::Date,Φ_month::Vector,σ_month::Vector,n_month::Int)
    current_month = Date(year(day_one),month(day_one))
    if current_month + Month(1) - Day(1) - day_one != Day(0) #If it is not the last day of the month
        n=length(day_one:(current_month + Month(1) - Day(1))) 
        x=[x0 ; simulation(x0,Φ_month[month(day_one)],σ_month[month(day_one)],n-1)]       
    else
        n=length(day_one:(current_month + Month(2) - Day(1)))
        x=[x0 ; simulation(x0,Φ_month[((month(day_one) % 12) +1)],σ_month[((month(day_one) % 12) +1)],n-1)]
        current_month += Month(1)
    end
    if n_month > 1 
        for _ in 2:n_month
            current_month += Month(1)
            n=length(current_month:current_month + Month(1) - Day(1))
            append!(x, simulation(x[end],Φ_month[month(current_month)],σ_month[month(current_month)],n))
        end
    end
    return x
end
function SimulateMonth(x0::Vector,day_one::Date,Φ_month::Vector,σ_month::Vector,n_month::Int)
    p=length(x0)
    current_month = Date(year(day_one),month(day_one))
    if current_month + Month(1) - Day(1) - day_one != Day(0) #If it is not the last day of the month
        n=length(day_one:(current_month + Month(1) - Day(1))) 
        x=[x0 ; simulation(x0,Φ_month[month(day_one)],σ_month[month(day_one)],n-1)]       
    else
        n=length(day_one:(current_month + Month(2) - Day(1)))
        x=[x0 ; simulation(x0,Φ_month[((month(day_one) % 12) +1)],σ_month[((month(day_one) % 12) +1)],n-1)]
        current_month += Month(1)
    end
    if n_month > 1 
        for _ in 2:n_month
            current_month += Month(1)
            n=length(current_month:current_month + Month(1) - Day(1))
            append!(x, simulation(x[(end-p+1):end],Φ_month[month(current_month)],σ_month[month(current_month)],n))
        end
    end
    try
        return x[p:end]
    catch
        return x
    end
end


"""
    SimulateYears(x0::Number,day_one::Date,Φ_month::Vector,σ_month::Vector,n_years::Int)
    
Return a simulation of a month-conditional AR(p) model (one AR(p) model for each month), for n_years starting from day_one with x0[end].
Each year generated has the same amount of days and correspond to one vector inside the output.
It's recommanded to choose the first of a year (yearX,1,1) in day_one.  
"""
function SimulateYears(x0::Number,day_one::Date,Φ_month::Vector,σ_month::Vector,n_years::Int)
    L=[SimulateMonth(x0,day_one,Φ_month,σ_month,12)]
    if n_years > 1 
        for _ in 2:n_years
            append!(L,[SimulateMonth(L[end][end],Date(year(day_one),month(day_one))-Day(1),Φ_month,σ_month,12)[2:end]])
        end
    end
    return L
end
function SimulateYears(x0::Vector,day_one::Date,Φ_month::Vector,σ_month::Vector,n_years::Int)
    p=length(x0)
    L=[SimulateMonth(x0,day_one,Φ_month,σ_month,12)]
    if n_years > 1 
        for _ in 2:n_years
            append!(L,[SimulateMonth(L[end][(end-p+1):end],Date(year(day_one),month(day_one))-Day(1),Φ_month,σ_month,12)[2:end]])
        end
    end
    return L
end