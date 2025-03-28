#! To run this code, put the 3 zip files ECA_blend_tx.zip, ECA_blend_tn.zip and ECA_blend_tg in the current directory.
#For now it's a bit slow but further improvements may be considered in the future.

# load pakages (need to be installed with `Pkg.add` before)

try 
    using CSV, Printf, DataFrames
catch ; 
    import Pkg
    Pkg.add("CSV")
    Pkg.add("Printf")
    Pkg.add("DataFrames")
    using CSV, Printf, DataFrames
end

cd(@__DIR__)

for obs in ["tx","tn","tg"] # change for tx, tm, tg, rr, pp, etc.
    try run(`cmd /C "mkdir ECA_blend_$(obs)"`) catch; end
    OBS = uppercase(obs)

    #! remove `wsl` command for bash (Linux or Mac) terminal. 
    #! wsl must be installed on Windows (or find another way to unzip selected files in `.zip`). I don't know for MAC I guess it is the same as Linux.

    # extract the station file from the zip
    
    #run(`wsl unzip ECA_blend_$(obs)/ECA_blend_$(obs).zip stations.txt`)
    run(`cmd /C "cd ECA_blend_$(obs) && tar -xvf ../ECA_blend_$(obs).zip stations.txt"`)

    # read the station.txt file and convert it as a DataFrame
    station_all = CSV.read("ECA_blend_$(obs)/stations.txt", DataFrame, normalizenames=true,skipto=19, header=18, ignoreemptyrows=true)

    # remove white space at the right of the name which is caused by imperfect CVS importation
    station_all.STANAME = rstrip.(station_all.STANAME)
    station_all.CN = rstrip.(station_all.CN)

    # In the station find all STAID (ID of each station) the one located in FR or BE or LU
    STAID_FR = station_all.STAID[findall(.|(station_all.CN .== "FR", station_all.CN .== "BE", station_all.CN .== "LU"))]

    # names of files to extract
    files_to_extract_STAID_FR = [string(OBS, "_", @sprintf("STAID%06.d.txt", i)) for i in STAID_FR]
    # extract the all weather files selected
    for file in files_to_extract_STAID_FR
        run(`cmd /C "cd ECA_blend_$(obs) && tar -xvf ../ECA_blend_$(obs).zip $file"`)
    end
end
