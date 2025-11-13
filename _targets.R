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
  
  ## Input data paths -----  
  
  ### Input paths to raw data -----------
  tar_target(Input_folder,
             file.path("Input"),
             format="file")#,
  
  ## Read data ----- 
  
  ### Read biomass csv -------------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  ### Read AK map -----------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  ## Set up landscape data for simulation ----- 
  
  ### Landscape grid setup ---------
  
  #### Refactor AK map ----------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  #### Recode AK map ----------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  #### Convert recoded AK map into matrix for simulation ---------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  ### Seasonal range setup ----------
  
  #### Create mock polygons to use as summer/winter ranges -------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  #### Create distance raster from summer/winter ranges ---------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  #### Convert distance raster to matrix for simulation ---------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  ### Convert distance raster to matrix for simulation ---------
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  ## Run simulation ----- 
  #tar_target(dat,ReadGeolocations(c(NPS_folder,USGS_folder)))#,
  
  
  
)

