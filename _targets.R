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
														"gganimate",
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
             file.path("Scripts","cpp_Functions","Caribou_Movement_v2.cpp"),
             format="file"),
  
	## Sample input setup ------------
		#len is num cells on each side
		#inc is resolution
	tar_target(grid,Make_Grid(object=c(100,1),
														grid.opt="homogeneous")),
	
	#### Create sample raster with same dimensions as sample grid
	tar_terra_rast(r,Create_Sample_Ras(100,1)),
	
	#### Get list of sample seasonal range polygons from sample grid
	tar_target(range_list,Create_Range_Polygons()),
	
	#### Create distance raster collection from sample calving/summer/winter polygons
	tar_terra_sprc(range_dist_sprc,Distance_Ranges(range_list,r,sample_input=TRUE)),
	
	#### Append sample grid with distance values for each of the three sample ranges
  tar_target(grid_list,Append_Grid_Distance(grid,range_dist_sprc,range_list,sample_input=TRUE)),
	
  #### Create dataframe for changing movement by jday ---------
	#made edits to make all migratory movement for testing/simplification
  tar_target(mv_jday,Move_Jday(sample_input=TRUE)),
	
	## Run simulation -------
	tar_target(output_list,
  Run_Simulation(grid_list,
                 mv_jday,
                 N0=100, #Number of caribou in simulation
                 dist_start=100, #Maximum distance from calving area centerpoint to initialize caribou
                 r, 
                 cpp_functions=list(Caribou_Movement_Script),
                 out.opts=c("init_locs","tracking","all_pop") #outputs (see end of this script for list of options)
                 )),
  
  ## Process outputs ----- 
  tar_target(processed_outputs,
             Process_Outputs(output_list,grid_list,r,mv_jday)),

	## Create animation of movement from tracking output-----
	tar_target(string_out,Tracking_Viz(processed_outputs$tracking))
	
	)


#out.opts: options for outputs from simulation
  #init_locs: output sf data frame with initial locations of caribou
  #tracking: output moved locations of caribou
  #all_pop: output list of pop matrices for each day of simulation
