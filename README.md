# 2025_Internship_SWG_Pomme

INRAE-MISTEA Internships by Arnaud Gonin (24 march -- September 2025)

@dmetivie - David Métivier INRAE MISTEA

## The problem

Couple SWG with agro models + climate change.

## What has been done

- A lot of literature on Stochastic Weather Generators

- A lot of agro model

## What will be done

A one site

- SWG for temperature
+ Then temperature min/max
+ Then precipitation/Solar radiation

### Data

On est en discussion avec des partenaires pour avoir des données météo dans les pays partenaires (Suède, France)

- [ECA&D data](https://www.ecad.eu/dailydata/predefinedseries.php). Open source europeean data for rain (RR), temperature min (TN), max (TX)

- [CLIMATIK](https://agroclim.inrae.fr/climatik/ClimatikGwt.html#) (INRAE data base)

- [DataGov MétéoFrance](https://www.data.gouv.fr/fr/datasets/fiche-climatologique-des-stations-de-meteo-france/). Voir fonction `collect_data_MeteoFrance` in my [package](https://dmetivie.github.io/StochasticWeatherGenerators.jl/dev/examples/tuto_add_station_variable/#Data-extraction-and-settings).

### Report

You have a report to write a report and prepare an oral presentation
Keep that in mind and try to takes notes during the whole internship and not at the last minute.

## Tooling

You can have a look on [the presentation](https://github.com/dmetivie/MyJuliaIntroDocs.jl/tree/master/first_day) I used on the first day.

- Programming language
  - Julia
- "IDE"
  - For dev, scripts, package (?) -> VSCode (except if you have other preference).
  - Notebooks to summarize and present advancement/results
- Cluster: Hopefully we will have some slot to run GPU simulations on the cluster.
- For data manipulations my go to is DataFrames.jl combined with DataFramesMeta.jl. [Here](https://david.metivier.pages.mia.inra.fr/website/julia_weather/) is a simple example I made
- Zotero for Bibliography. I heard of shared bibliography using Zotero, this might be an idea.

I like the [PhD ressource website](https://phd-resources.github.io/) by Guillaume Dalle (heavy Julia user). He gives a lot of cool tips, software etc for students (not only PhD).

## Collaborators

- Bénédicte Fontez <benedicte.fontez@supagro.fr> (à MISTEA)

- Anne Pellegrino <anne.pellegrino@supagro.fr> (LEPSE juste à côté)

- Isabelle Farrera <isabelle.farrera@supagro.fr> (AGAP) juste à côté

- Jean Jacques kELNER <jean-jacques.kelner@supagro.fr> (AGAP) -> retraite
## You

What do you expect? (Skills, Research)

Your formation

## Where to start


Lire bibilo. 
Implémenter des modèles simples pour se faire la main. Jouer avec les données d'une station.

### Bibliography

Voir [section dédié ici](biblio\README.md)

### Packages

- J'ai commencé (mais très brouillon) [StochasticWeatherGenerators.jl](https://dmetivie.github.io/StochasticWeatherGenerators.jl/dev/#StochasticWeatherGenerators.jl).

- Pas d'autres exemple en Julia (que je connaisse)

- En général même en R/Python assez peu de répo avec code