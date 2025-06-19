#Packages
try
    using CSV, DataFrames, Dates, CairoMakie, Statistics, DataFramesMeta
catch
    import Pkg
    Pkg.add("CSV")
    Pkg.add("DataFrames")
    Pkg.add("Dates")
    Pkg.add("CairoMakie")
    Pkg.add("Statistics")
    Pkg.add("DataFramesMeta")
    using CSV, DataFrames, Dates, CairoMakie, Statistics, DataFramesMeta
end
cd(@__DIR__)


function ma_odd(x, p)
    #Filter the vector x with the simple mobile average method, for an odd period p.

    out, m = ones(size(x)) * mean(x), (p - 1) ÷ 2
    return ma_odd!(x, out, m)
end

function ma_odd!(x, out, m)
    out[m+1:end-m] = sum([x[m+1+i:end-m+i] for i in -m:m]) / (2m + 1)
    return out
end

function extract_series(file::String; year=nothing, plot=false, type_data=nothing)
    #Extract the temperature time series from the file. You can precise the year with the argument year.
    #If plot=True, return a tuple with the time series and the figure object, respectively.

    table = CSV.read(file, DataFrame, normalizenames=true, skipto=22, header=21, ignoreemptyrows=true)
    isnothing(type_data) ? type_data = file[end-17:end-16] : nothing
    # num_station = match(r"([1-9]\d*)", file).match
    df = table[table[!, "Q_"*type_data].==0, ["DATE", type_data]]
    df.DATE = Date.(string.(df.DATE), dateformat"yyyymmdd")
    df[!, type_data] /= 10
    type_map = Dict("TX" => "maximum", "TN" => "minimum", "TG" => "average")
    if year != nothing
        df = df[Date(year).<=df.DATE.<Date(year + 1), :]
        if plot
            fig, ax = lines(df.DATE, df[!, type_data])
            ax.title = "Daily $(type_map[type_data]) temperatures" #from the station n°$(num_station)"
            ax.xlabel = "Date"
            ax.ylabel = "Temperature (°C)"
            return df, fig
        else
            return df
        end
    elseif plot
        fig = Figure()
        ax, plot1 = lines(fig[1:2, 1:2], df.DATE, df[!, type_data])
        plot2 = lines!(ax, df.DATE, ma_odd(df[!, type_data], 365))
        ax.title = "Daily $(type_map[type_data]) temperatures from the station n°$(num_station)"
        ax.xlabel = "Date"
        ax.ylabel = "Temperature (°C)"
        Legend(fig[3, 1:2], [plot1, plot2], ["Recorded temperatures", "Temperatures filtered with simple mobile average"])
        return df, fig
    else
        return df
    end
end



function truncate_MV(df_full, temperature_type)
    df, f = copy(df_full), true
    while f
        if any(diff(df.DATE[end-1000:end]) .> Day(1)) #If the last MV is close to the end the series...
            df = @chain df begin
                @transform(:diff = [diff(:DATE); Day(1)])
                @aside beg = _.DATE[findlast(_.diff .> Day(1))]
                @subset(:DATE .<= beg) #in a first time we keep what is before it
                # @transform(:TX = 0.1 * :TX)
            end
        elseif any(diff(df.DATE) .> Day(1)) #Else we keep what is after.
            df = @chain df begin
                @transform(:diff = [diff(:DATE); Day(1)])
                @aside beg = _.DATE[findlast(_.diff .> Day(1))]
                @subset(:DATE .> beg)
                # @transform(:TX = 0.1 * :TX)
            end
            f = false #to stop the loop
        else
            f = false
        end
    end
    if Date(year(df.DATE[1]), month(df.DATE[1])) + Month(1) - df.DATE[1] < Day(20) #If there are not enough days in the first month I remove it.
        df = df[df.DATE.>=(Date(year(df.DATE[1]), month(df.DATE[1]))+Month(1)), :]
    end
    if df.DATE[end] - Date(year(df.DATE[end]), month(df.DATE[end])) < Day(19) #The same thing for the last month.
        df = df[df.DATE.<Date(year(df.DATE[end]), month(df.DATE[end])), :]
    end
    return df
end
truncate_MV(df_full) = truncate_MV(df_full, nothing) #To avoid error with old call of this function, where temperature_type was necessary 