#Steps to get package set up
	#Refine functions below for user input
	#Make new functions needed
	#Put user functions together in a script, separate folder R_Package
	#Compile into R package

#Functions to refine for user input, generalized
	#DONEDistance Ranges - separate proc of wah_ranges from making dist ranges
	#Tracking viz.. currently is specific to Alaska

#New functions
#RunSimulation function, make version for R package without sourcing cpp function inside (req for targets pipeline)

#Sample data to set up as Rdata:
	#two sample wah ranges
	#ambler road coords

#Steps for user:
	#1-Format input data
		#in: shapefiles
		#out:
			#list of shapefiles, grid objects, raster, distance rasters
	#2-Set movement parameters
		#input shape and rate step lengths, jday for shift
		#output- mv_jday
	#3-Run simulation
		#input: formatted spatial data, mv_jday, out.opts
		#output: processed outputs
	#4-Visualize outputs

#input- list of sf objects, polygon or multipolyogn
Format_Spatial_Data<-function(range_list,
														  rdcoords,
															inc){
	
	#Create base raster
	r=Create_Sample_Ras(len=NA,
										inc=inc,
										sample_input=FALSE,
										range_list)
	
	#Create grid
	grid=Make_Grid(object=r,
					 grid.opt="homogeneous")
	
	#Create distance raster sprc
	#This needs to be generalized for user input data
	#wah_ranges need be processed in separate step beforehand
		#include processed wah_ranges as example data
	dist_r_sprc=
		Distance_Ranges(
		range_list,
		r,
		sample_input=FALSE,
		contour=50)
	
	#Format road data (get coordinates)
	#This needs to be generalized for user input data
	#New function: input linestring/multiine string
		#Pull out start and end coordinates
	#rdcoords<-Format_Road_Coords(road)
	
	#Create grid list with appended distances
	grid_list=Append_Grid_Distance(grid,
											 dist_r_sprc,
											 range_list,
											 sample_input=FALSE)
	
	spatial_input=list("range_list"=range_list,
									   "dist_r_sprc"=dist_r_sprc,
										 "grid_list"=grid_list,
										 "r"=r,
										 "rdcoords"=rdcoords
										 )
	
	return(spatial_input)
}

Set_Spatial_Movement<-function(
		n_range,
		sl_shp,
		sl_rat,
		start,
		end,
		sample_input=FALSE,
		sel_range_names=NULL
		){

if(is.null(sel_range_names)){
	sel_range_names=paste0("range",1:n_range)
}
	
mv_jday=
	Move_Jday(
		sample_input=sample_input,
		sel_range_names=sel_range_names,
		sl_shp=sl_shp,
		sl_rat=sl_rat,
		start=start,
		end=end)

return(mv_jday)

}



Range_Simulate<-function(
		spatial_input,
		rdcoords,
		mv_jday,
		jday_max,
		N0,
		inc,
		dist_start,
		out.opts=c("tracking")
	){
	
	#Pull objects from spatial input list
	grid_list=spatial_input$grid_list
	rdcoords=spatial_input$rdcoords
	r=spatial_input$r
	

#Need set this up to source cpp function outside
#Need set up to just take road coords input
sim_output=Run_Simulation_Rep(grid_list,
  							 rdcoords,
                 mv_jday,
                 N0=N0, #Number of caribou in simulation
								 jday_max,
  						   inc=inc,
                 dist_start=dist_start, #Maximum distance from calving area centerpoint to initialize caribou
                 r, 
                 out.opts=out.opts #outputs (see end of this script for list of options)
                 )

#Process output
proc_sim_output=Process_Outputs(
								sim_output,
								grid_list,
								r,
								mv_jday,
								inc)

return(proc_sim_output)

}



### Run simulation rep
# Run simulation ---------
Run_Simulation_Rep<-function(grid_list,
												 rdcoords,
                         mv_jday,
                         N0,
												 jday_max,
												 inc,
                         dist_start,
                         akc3,
                         out.opts=NULL){
  out.list=vector(mode="list",length=0)
  
  # Pull coords for output summaries
  coords=terra::crds(akc3)
  
  # Initialize caribou on landscape ---------
  pop<-Initialize_Population(grid_list,N0,dist_start,mv_jday,sample_input=TRUE)
  centroids=grid_list$centroids
  
  # Output initial condition objects ---------
  if(!missing(out.opts)){
    if("init_locs"%in%out.opts){
      templist=vector(mode="list",length=1)
      centroids=grid_list$centroids
      cdf=CentroidsRowtoXY(pop[,3],coords)
      
      templist[[1]]=cdf
      out.list=append(out.list,templist)
      names(out.list)[[length(out.list)]]="init_locs"
    }
    
    if("all_pop"%in%out.opts){
      all_pop=vector(mode="list",length=365)
    }
    
  }
  
  # Start run through jdays ---------
  shape=mv_jday$sl_shp[1] 
  rate=mv_jday$sl_rat[1]
  
  if(!missing(out.opts)){
    if("tracking"%in%out.opts){
      tracking<-TRUE
      loc_mat=pop[,3]
    } else{
      tracking<-FALSE
    }
  } else{
    tracking<-FALSE
  }

      #road_list$coords needs to be converted from projected x/y coordinates
      rsf=sf::st_as_sf(as.data.frame(rdcoords),coords=c(1,2),crs=sf::st_crs(akc3))

      #1-get cell number of raster where the coordinates lie
      cells=terra::cellFromXY(akc3,st_coordinates(rsf))
      #2-get the x/y of centroids from this
      rcoords_grid=centroids[cells,1:2]
      
  
  print("starting movement")

  		for(d in 1:jday_max){    
   
      if("all_pop"%in%out.opts){
      all_pop[[d]]<-pop
      }
      
      #Pull which row in jday based on d
      sel_row=NA
      i=1
      while(is.na(sel_row)){
			if(d>=mv_jday[i,6]&d<=mv_jday[i,7]){sel_row=i}
      i=i+1
			}
      
      #convert sel_row to centroids column
      cent_col=sel_row+1 #starts on col 3 of centroids, but starting at 0 index for cpp function
      
      #do movement
      pop=Movement(pop,centroids,shape,rate,cent_col,rcoords_grid,inc)
      
      #update outputs
      if(tracking){
      loc_mat=cbind(loc_mat,pop[,3])
      }
      
      }
  
  # Output tracking object ---------
  
  if(!missing(out.opts)){
    if("tracking"%in%out.opts){
      templist=vector(mode="list",length=1)
      templist[[1]]=loc_mat
      out.list=append(out.list,templist)
      names(out.list)[[length(out.list)]]="tracking"
    }
    if("all_pop"%in%out.opts){
      templist=vector(mode="list",length=1)
      templist[[1]]=all_pop
      out.list=append(out.list,templist)
      names(out.list)[[length(out.list)]]="all_pop"
    }
  }
  return(out.list)
  
}


Vizualize_Tracks<-function(tracking,
													 path="./track_viz.gif",
													 spatial_input,
													 country="United States of America",
													 plot_buffer=c(-250000,-100000,100000,120000)){
	
	require(rnaturalearth)
	require(rnaturalearthdata)
	
	r=spatial_input$r
	rdcoords=spatial_input$rdcoords
	range_list=spatial_input$range_list
	
	trackdf=do.call(rbind,tracking)
		
	rsf=st_as_sf(as.data.frame(rdcoords),coords=c(1,2),crs=sf::st_crs(r))
	line_geom <- st_sfc(st_linestring(st_coordinates(rsf)))
	line_sf <- st_sf(geometry = line_geom, crs = st_crs(r))
	
	tracksf=sf::st_as_sf(trackdf,coords=c(1,2),crs=sf::st_crs(range_list[[1]]))
	world <- ne_countries(scale='medium',returnclass = 'sf')
	world_subset <- subset(world, admin == country)

	world_subset_formatted <- ggplot(data = world_subset) +
     geom_sf(fill = "lightgray", color=NA)+
	theme(panel.background = element_rect(fill = "aliceblue"))
	
	#get bbox coords
	coords=terra::crds(r)
	minx=min(coords[,1])+plot_buffer[1]
	miny=min(coords[,2])+plot_buffer[2]
	maxx=max(coords[,1])+plot_buffer[3]
	maxy=max(coords[,2])+plot_buffer[4]
	
	#make state as factor
	tracksf$state=as.factor(tracksf$state)
	
	myPlot=
	world_subset_formatted +
  geom_sf(tracksf, 
  				mapping=aes(colour = state),alpha = 0.7, show.legend = FALSE)+
	scale_colour_manual(values=c("blue","red"))+
  geom_sf(data=line_sf,show.legend = FALSE)+
	coord_sf(crs = sf::st_crs(range_list[[1]]), 
     					xlim = c(minx, maxx), 
     					ylim = c(miny, maxy), 
     					expand = FALSE, 
     					datum = NA)+
	transition_time(day) +
  ease_aes('linear')+theme_minimal()
	
	animate(myPlot, fps = 5, width = 1000, height = 1000, renderer = gifski_renderer())
	anim_save(path)
	
	return(tracksf)
	
	}

