#Packages
try 
    using CSV, DataFrames, Dates, CairoMakie, Statistics
catch ; 
    import Pkg
    Pkg.add("CSV")
    Pkg.add("DataFrames")
    Pkg.add("Dates")
    Pkg.add("CairoMakie")
    Pkg.add("Statistics")
    using CSV, DataFrames, Dates, CairoMakie, Statistics
end
cd(@__DIR__)


function ma_odd(x,p)
    #Filter the vector x with the simple mobile average method, for an odd period p.

    out,m=ones(size(x))*mean(x),(p-1) ÷ 2   
    return ma_odd!(x,out,m)
end

function ma_odd!(x,out,m)
    out[m+1:end-m]=sum([x[m+1+i:end-m+i] for i in -m:m])/(2m+1) 
    return out
end

function extract_series(file::String; year=nothing, plot=false)
    #Extract the temperature time series from the file. You can precise the year with the argument year.
    #If plot=True, return a tuple with the time series and the figure object, respectively.

    table=CSV.read(file, DataFrame, normalizenames=true,skipto=22, header=21, ignoreemptyrows=true)
    type_data=file[1:2]
    num_station=match(r"([1-9]\d*)",file).match
    df=table[table[!,"Q_"*type_data].==0,["DATE",type_data]]
    df.DATE=Date.(string.(df.DATE),dateformat"yyyymmdd")
    df[!,type_data]/=10
    type_map=Dict("TX"=>"maximum","TN"=>"minimum","TG"=>"average")
    if year != nothing
        df=df[Date(year).<= df.DATE .< Date(year+1),:]
        if plot 
            fig, ax = lines(df.DATE, df[!,type_data])
            ax.title="Daily $(type_map[type_data]) temperatures from the station n°$(num_station)"
            ax.xlabel="Date"
            ax.ylabel="Temperature (°C)"
            return df, fig
        else
            return df
        end
    elseif plot 
        fig=Figure()
        ax, plot1=lines(fig[1:2, 1:2], df.DATE, df[!,type_data])
        plot2=lines!(ax,df.DATE,ma_odd(df[!,type_data],365))
        ax.title="Daily $(type_map[type_data]) temperatures from the station n°$(num_station)"
        ax.xlabel="Date"
        ax.ylabel="Temperature (°C)"
        Legend(fig[3, 1:2],[plot1,plot2],["Recorded temperatures","Temperatures filtered with simple mobile average"])
        return df, fig
    else
        return df
    end
end