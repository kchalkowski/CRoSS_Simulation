
# Load packages -----
req_packages=c("tidyr","purrr","stringr","dplyr","sf","amt","raster",
               "terra","lubridate","ggplot2","gganimate","mapview","rnaturalearth",
							 "rnaturalearthdata","RcppParallel")	

lapply(req_packages, library, character.only = TRUE)

# Load objects -------
range_list=tar_read(wah_ranges)
road_list=tar_read(ambler_layers)
rdcoords=road_list$coords

# Source cpp scripts ------
Caribou_Movement_Script=tar_read(Caribou_Movement_Script)
Rcpp::sourceCpp(Caribou_Movement_Script)

# Run user-facing functions -----
spatial_input.u=Format_Spatial_Data(wah_ranges,road_list$coords,inc=1000)

mv_jday.u=Set_Spatial_Movement(n_range=2,
										 sl_shp=c(10000,10000),
										 sl_rat=c(0.8,0.8),
										 start=c(1,100),
										 end=c(99,365),
										 sample_input=FALSE,
										 sel_range_names=names(wah_ranges))

sim_output.u=
	Range_Simulate(spatial_input,
							 spatial_input$rdcoords,
							 mv_jday.u,
							 jday_max=365,
							 N0=100,
							 inc=1000,
							 dist_start=100000,
							 out.opts=c("tracking"))

trackdf.u=Vizualize_Tracks(sim_output.u$tracking,
											  path="./Output/track_viz.gif",
												spatial_input.u)
