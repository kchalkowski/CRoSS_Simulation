# _targets.R


# Targets setup --------------------
setwd(this.path::this.dir())

#load libraries for targets script
#install.packages("geotargets", repos = c("https://njtierney.r-universe.dev", "https://cran.r-project.org"))
library(targets)
library(tarchetypes)
library(geotargets)

# This hardcodes the absolute path in _targets.yaml, so to make this more
# portable, we rewrite it every time this pipeline is run (and we don't track
# _targets.yaml with git)
tar_config_set(
  store = file.path(this.path::this.dir(),("_targets")),
  script = file.path(this.path::this.dir(),("_targets.R"))
)

#Source functions in pipeline
lapply(list.files(file.path("Scripts"), full.names = TRUE, recursive = TRUE), source)

#set options
options(clustermq.scheduler="multicore")

#Load packages
tar_option_set(packages = c("tidyr",
                            "purrr",
                            "stringr",
                            "dplyr",
                            "sf",
                            "amt",
                            "raster",
                            "terra",
                            "lubridate",
                            "ggplot2",
                            "mapview"))

# Pipeline ---------------------------------------------------------

list(
  
  ## Input data -----  
  
  ### Input paths to raw data -----------
  tar_target(NPS_folder,
             file.path("Input"),
             format="file")#,
  
  ### Read all csv data into list -----------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  
)

