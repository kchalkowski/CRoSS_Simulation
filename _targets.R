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
lapply(list.files(file.path("Scripts/R_Functions"), full.names = TRUE, recursive = TRUE), source)


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
                            "mapview",
                            "RcppParallel"))

# Pipeline ---------------------------------------------------------

list(
  
  ## Input data paths -----  
  
  ### Input paths to raw data -----------
  tar_target(Input_folder,
             file.path("Input"),
             format="file"),
  
  ## Input cpp scripts as files to enable tracking -----  
  tar_target(Caribou_Movement_Script,
             file.path("Scripts","cpp_Functions","Caribou_Movement.cpp"),
             format="file"),
  
  ## Read data ----- 
  
  ### Read biomass csv -------------
  #tar_target(biomass,ReadBiomass(Input_folder)),
  
  ### Read AK map -----------
  tar_terra_rast(akc,ReadAKNLCD(Input_folder)),
  
  ### Read mock shapefiles -------
  tar_target(range_list,ReadRanges(Input_folder)),
  
  ## Set up landscape data for simulation ----- 
  
  ### Landscape grid setup ---------
  #### Refactor AK map ----------
  tar_terra_rast(akc_refact,Refactor_AK(akc,type="res",res=1000)),
  
  #### Recode AK map ----------
  tar_terra_rast(akc2p,Recode_AK(akc_refact)),
  
  #### Transform AK map ----------
  #original is Alaska Albers with WGS84 datum, want NAD83 datum (EPSG:6393)
  tar_terra_rast(akc2,Transform_AK(akc2p)),
  
  #### Crop AK map to square ----------
  tar_terra_rast(akc3,Crop_Raster(akc2)),
  
  #### Convert recoded AK map into matrix for simulation ---------
  tar_target(grid,Convert_toGrid(akc3)),
  
  ### Seasonal range setup ----------
  
  #### Create distance raster from calving/summer/winter polygons ---------
  tar_terra_sprc(range_dist_sprc,Distance_Ranges(range_list,akc3)),
  
  #### Append grid with distance values for each of the three ranges ---------
  tar_target(grid_list,Append_Grid_Distance(grid,range_dist_sprc,range_list)),
  
  #### Create dataframe for changing movement by jday ---------
  tar_target(mv_jday,Move_Jday()),
  
  ## Run simulation ----- 
  tar_target(output_list,
  Run_Simulation(grid_list,
                 mv_jday,
                 N0=100, #Number of caribou in simulation
                 dist_start=10000, #Maximum distance from calving area centerpoint to initialize caribou
                 akc3, 
                 cpp_functions=list(Caribou_Movement_Script),
                 out.opts=c("init_locs","tracking") #outputs (see end of this script for list of options)
                 )),
  
  ## Process outputs ----- 
  tar_target(processed_outputs,
             Process_Outputs(output_list,grid_list,akc3))#,
)

#out.opts: options for outputs from simulation
  #init_locs: output sf data frame with initial locations of caribou
  #tracking: output moved locations of caribou
