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
													  "rnaturalearth",
													  "rnaturalearthdata",
                            "RcppParallel"))

# Pipeline ---------------------------------------------------------

list(
  
  ## Input data and source scripts -----  
  
  ### Input paths to raw data -----------
  tar_target(Input_folder,
             file.path("Input"),
             format="file"),
  
  ### Input cpp scripts as files to enable tracking -----  
  tar_target(Caribou_Movement_Script,
             file.path("Scripts","cpp_Functions","Caribou_Movement_v2.cpp"),
             format="file"),
  
	### Pull range layers ------------
	tar_target(wah_range_layers,Pull_Range_Layers(Input_folder,
		gdb_filename="kernel_ann_report.gdb",
		ambler=FALSE)),
	
	### Pull ambler road ---------
	tar_target(ambler_layers,Pull_Range_Layers(Input_folder,
		gdb_filename="AmblerRoad_SupplementalEIS_Project_Options.gdb",
		ambler=TRUE)),
	
	## Set up simulation input ------------
	
	### Get Sample seasonal range polygons -----
	#Input:
	#Output: 
		#range_list- list of simple feature polygons
	tar_target(range_list,Create_Range_Polygons()),
	tar_target(wah_ranges,
		Sample_WAH_Layers(
			wah_range_layers,
			sel_range_names=c("winter_22_23","calving23")
		)),

	### Create sample raster ------
	#Input:
		#len, inc
	#Output:
		#r- SpatRaster with len x len dimensions and inc resolution
	tar_terra_rast(r,Create_Sample_Ras(len=100,
																		 inc=1,
																		 sample_input=TRUE,
																		 NULL)),
	tar_terra_rast(wah_r,Create_Sample_Ras(len=NA,
																			   inc=1000,
																				 sample_input=FALSE,
																				 wah_ranges)),
	
	### Make grid object --------
	#Input: 
		#object = c(len, inc)
			#len is num cells on each side
			#inc is resolution of each cell
		#grid.opt- option for grid setup, character string
	#Output: data frame listing each cell in grid and coordinates of cell centerpoint
	tar_target(grid,Make_Grid(object=c(100,1),
														grid.opt="homogeneous")),
	tar_target(wah_grid,Make_Grid(object=wah_r,
														grid.opt="homogeneous")),
	
	### Create sample road --------
	#divides ranges 1 and 2
	tar_target(road_list,Create_Sample_Road()),

	### Create distance rasters from range polygons -----
	#Input: 
		#range_list
		#r
		#sample_input- boolean, indicate if generating sample input
	#Output:
		#range_dist_sprc- spatraster collection of distance from centroid of each polygon in range list
	tar_terra_sprc(range_dist_sprc,Distance_Ranges(range_list,r,sample_input=TRUE)),
	tar_terra_sprc(wah_range_dist_sprc,Distance_Ranges(
		wah_ranges,
		wah_r,
		sample_input=FALSE,
		contour=50)),

	### Append sample grid with distance values -------
  #Input: 
		#grid
		#range_dist_sprc
		#range_list
		#sample_input: boolean
	#Output: 
		#grid_list- list of objects used for movement algorithm
			#$cells - number of cells in grid
			#$grid
			#$centroids- list of centroids of each cell
	tar_target(grid_list,Append_Grid_Distance(grid,range_dist_sprc,range_list,sample_input=TRUE)),
	tar_target(wah_grid_list,Append_Grid_Distance(wah_grid,wah_range_dist_sprc,wah_ranges,sample_input=FALSE)),

  ### Create dataframe for changing movement by jday ---------
	#Input
		#sample_input- boolean
	#Output
		#mv_jday- data frame, each row is a movement state, each column is a characteristic of each movement state
			#state- name of polygon attracted to
			#sl_shp- shape parameter of step length distribution for movement
			#sl_rat- rate parameter of step length distribution for movement
			#migr- 
			#attract-
			#start- jday start for movement state
			#end- jday end for movement state
  tar_target(mv_jday,Move_Jday(sample_input=TRUE)),
	tar_target(wah_mv_jday,
		Move_Jday(
		sample_input=FALSE,
		sel_range_names=c("winter_22_23","calving23"),
		sl_shp=c(10000,10000),
		sl_rat=c(0.8,0.8),
		start=c(1,100),
		end=c(99,199))),

	## Run simulation -------
	#grid_list- 
	#mv_jday
	#N0- integer, number of caribou to initialize in simulation
	#dist_start- maximum distance from starting polygon centroid to initialize caribou
	#r- raster version of grid on which simulation is run
	#cpp_functions- list of cpp functions to source before simulation is run
	tar_target(output_list,
  Run_Simulation(grid_list,
  							 road_list,
                 mv_jday,
                 N0=100, #Number of caribou in simulation
  						   inc=1,
                 dist_start=100, #Maximum distance from calving area centerpoint to initialize caribou
                 r, 
                 cpp_functions=list(Caribou_Movement_Script),
                 out.opts=c("init_locs","tracking","all_pop") #outputs (see end of this script for list of options)
                 )),
	
	tar_force(wah_output_list,
  Run_Simulation(wah_grid_list,
  							 ambler_layers,
                 wah_mv_jday,
                 N0=100, #Number of caribou in simulation
  							 inc=1000,
                 dist_start=100000, #Maximum distance from first range centerpoint to initialize caribou
                 wah_r, 
                 cpp_functions=list(Caribou_Movement_Script),
                 out.opts=c("init_locs","tracking","all_pop") #outputs (see end of this script for list of options)
                 ),
		force=1<0),
  
  ## Process outputs ----- 
  tar_target(processed_outputs,
             Process_Outputs(output_list,grid_list,r,mv_jday,inc=1)),
	
	tar_target(wah_processed_outputs,
             Process_Outputs(wah_output_list,wah_grid_list,wah_r,wah_mv_jday,inc=1000)),

	## Create visual outputs -------
	
	### Create animation of movement from tracking output -----
	#Create animation of sample run
	tar_target(string_out,Tracking_Viz(processed_outputs$tracking,
																		 filename="sample_gif.gif",
																		 sample_input=TRUE)),
	
	# Create animation of WAH range movements
	tar_target(wah_string_out,
		Tracking_Viz(wah_processed_outputs$tracking,
								 filename="wah_gif.gif",
								 sample_input=FALSE,
								 wah_r,
								 ambler_layers,
								 wah_ranges)),
	
	#Create visual of seasonal ranges
	tar_target(string_ranges,
		PlotRangeLayers(
			wah_range_layers,
			wah_r,
			"Range_Maps",
			ambler_layers$ranges[[1]]
			)
		)
	
	

	)

#out.opts: options for outputs from simulation
  #init_locs: output sf data frame with initial locations of caribou
  #tracking: output moved locations of caribou
  #all_pop: output list of pop matrices for each day of simulation




