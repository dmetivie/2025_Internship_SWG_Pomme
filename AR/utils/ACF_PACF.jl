include("utils.jl")

@tryusing "CairoMakie","Statistics","StatsBase"

Month_vec = ["January", "February", "March", "April", "May", "Jun", "July", "August", "September", "October", "November", "December"]

##### ACF/PACF #####
"""
    ACF_PACF(x::AbstractVector, return_data::Bool=false)

Return the graphs of the ACF and the PACF of the series x. 
If return_data = true, the function return a tuple with the ACF, the PACF and the figure object which contains the graphs.
"""
function ACF_PACF(x::AbstractVector, return_data::Bool=false)
    fig = Figure(size=(700, 800))
    autocor_ = autocor(x, 0:15)
    ax1, plt1 = barplot(fig[1, 1], 0:15, autocor_)
    ax1.title = "ACF"
    ax1.xticks = 0:15
    ax1.xgridvisible = false
    ax1.yticks = round.(range(minimum(autocor_), maximum(autocor_), 10), digits=2)
    pacf_ = pacf(x, 1:15)
    ax2, plt2 = barplot(fig[2, 1], 1:15, pacf_)
    ax2.title = "PACF"
    ax2.xticks = 1:15
    ax2.xgridvisible = false
    ax2.yticks = round.(range(minimum(pacf_), maximum(pacf_), 10), digits=2)
    return return_data ? (autocor_, pacf_, fig) : fig
end

"""
    MonthlyACF(Monthly_temp::Vector, return_data::Bool=false)

Return the graphs of the monthly average ACF of each series inside Monthly_temp.
Monthly_temp must be a 3 level-nested vector such as an output of MonthlySeparateX.
If return_data = true, the function return a tuple with the ACF of each months inside Monthly_temp and the figure object.
"""
function MonthlyACF(Monthly_temp::AbstractVector, return_data::Bool=false)
    fig = Figure(size=(800, 600))
    supertitle = Label(fig[1, 1:4], "Monthly average ACF", fontsize=20)
    ax_vec = Axis[]
    min_y = 0
    if return_data
        autocor_data = AbstractVector[]
    end
    for i in 1:12
        autocor_vec = [autocor(Monthly_temp[i][j], 0:10) for j in eachindex(Monthly_temp[i])] #One element per year
        m_autocor = mean(autocor_vec)
        ax, plot = barplot(fig[((i-1)÷4)+2, (i-1)%4+1], 0:10, m_autocor)
        ax.title = Month_vec[i]
        min_y = min(minimum(m_autocor), min_y)
        ax_vec = [ax_vec; [ax]]
        if return_data
            append!(autocor_data, [autocor_vec])
        end
    end
    for ax in ax_vec
        ax.limits = (nothing, [min_y - 0.05, 1.05])
        ax.xgridvisible = false
        ax.xticks = 0:10
    end
    return return_data ? (autocor_data, fig) : fig
end

"""
    MonthlyPACF(Monthly_temp, return_data::Bool=false)
    
Return the graphs of the monthly average PACF of each series inside Monthly_temp.
Monthly_temp must be a 3 level-nested vector such as an output of MonthlySeparateX.
If return_data = true, the function return a tuple with the PACF of each months inside Monthly_temp and the figure object.
"""
function MonthlyPACF(Monthly_temp, return_data=false)
    fig = Figure(size=(800, 600))
    supertitle = Label(fig[1, 1:4], "Monthly average PACF", fontsize=20)
    ax_vec = Axis[]
    max_y, min_y = 0, 0
    if return_data
        pacf_data = AbstractVector[]
    end
    for i in 1:12
        pacf_vec = [pacf(Monthly_temp[i][j], 1:10) for j in eachindex(Monthly_temp[i])] #One element per year
        m_pacf = mean(pacf_vec)
        ax, plot = barplot(fig[((i-1)÷4)+2, (i-1)%4+1], 1:10, m_pacf)
        ax.title = Month_vec[i]
        max_y = max(maximum(m_pacf), max_y)
        min_y = min(minimum(m_pacf), min_y)
        ax_vec = [ax_vec; [ax]]
        if return_data
            append!(pacf_data, [pacf_vec])
        end
    end
    for ax in ax_vec
        ax.limits = (nothing, [min_y - 0.05, max_y + 0.05])
        ax.xgridvisible = false
        ax.xticks = 1:10
    end
    return return_data ? (pacf_data, fig) : fig
end