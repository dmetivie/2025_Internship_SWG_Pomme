using DataFrames, CSV, Downloads, Dates
using CairoMakie

function savefigcrop(plt::CairoMakie.Figure, save_name)
    CairoMakie.save(string(save_name, ".pdf"), plt)
    run(`pdfcrop $(string(save_name,".pdf"))`) # Petit délire pour croper proprement la figure pas forcément necessaire ici?? Ca demande peut être d'installer pdfcrop
    mv(string(save_name, "-crop", ".pdf"), string(save_name, ".pdf"), force=true)
end

station_path = string.("https://forgemia.inra.fr/david.metivier/weather_data_mistea/-/raw/main/INRAE_stations/INRAE_STATION_", [49215002, 80557001, 40272002, 63345002], ".csv") .|> download
begin
    data_stations_full = collect_data_INRAE.(station_path; show_warning=[:RR, :TX], impute_missing=[:RR, :TX])
    for df in data_stations_full
        @transform!(df, :RO = onefy.(:RR))
    end
end

df2003 = @subset(data_stations_full[1], year.(:DATE) .== 2003)

freal = CairoMakie.with_theme(CairoMakie.theme_latexfonts(), fontsize = 18) do
    freal = CairoMakie.Figure()
    axreal = CairoMakie.Axis(freal[1,1], xticks=xticks_year(0), xlabelrotation=30, xlabelsize=12, ylabel=L"$T$ (°C)")
    CairoMakie.lines!(axreal, datetime2unix.(df2003.DATE .|> DateTime), df2003.TX; linewidth=2, color=1, colormap=:tab10, colorrange=(1, 10), label = "Observation 2003")
    CairoMakie.ylims!(axreal, -3, 40)
    CairoMakie.axislegend(axreal)
    freal
end
save_path = "."
savefigcrop(freal, "TX_2003_real_49.pdf", save_path);

idx_simu(y) = findall(year.(date_range) .== y)

_xticks_year(i) = datetime2unix.(DateTime.(2003 + i, 1:12, 1))
_xticklabels = monthabbr.(1:12)
xticks_year(i) = _xticks_year(i), _xticklabels

f = CairoMakie.with_theme(CairoMakie.theme_latexfonts(), fontsize = 16) do
    f = CairoMakie.Figure(size=(600, 500))
    iend = 3
    axs = [CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), 300 - 135 * (i - 1), 495 - (i - 1) * 135), backgroundcolor=(:white, 1), ylabel=L"$T$ (°C)") for i in 1:iend-1]
    i = iend
    axend = CairoMakie.Axis(f, bbox=CairoMakie.BBox(0 + 50 * (i), 400 + 50 * (i), 300 - 135 * (i - 1), 495 - (i - 1) * 135), xticks=xticks_year(0), xlabelrotation=30, xlabelsize=12, ylabel=L"$T$ (°C)")

    CairoMakie.linkxaxes!(axs..., axend)
    CairoMakie.linkyaxes!(axs..., axend)
    for (i, ax) in enumerate(axs)
        CairoMakie.lines!(ax, datetime2unix.(df2003.DATE .|> DateTime), txs[1, idx_simu(2003), i]; linewidth=2, color=i + 1, colormap=:tab10, colorrange=(1, 10))
        CairoMakie.hidexdecorations!(ax)
        CairoMakie.translate!(ax.blockscene, 0, 0, 200 - 200 * (iend - i))
    end
    setproperty!.((axs..., axend), :backgroundcolor, ((:white, 0.6),))
    CairoMakie.translate!(axend.blockscene, 0, 0, 200)
    CairoMakie.lines!(axend, datetime2unix.(df2003.DATE .|> DateTime), txs[1, idx_simu(2003), iend]; linewidth=2, color=iend + 1, colormap=:tab10, colorrange=(1, 10))
    CairoMakie.hidexdecorations!(axend, ticklabels=false)
    f
end

savefigcrop(f, "TX_simus_AR1_49.pdf", save_path);