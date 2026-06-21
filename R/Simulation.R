#' Initialize population matrix
#' @param grid_list, list
#' @param N0, integer
#' @param dist_start, integer
#' @param mv_jday, data frame
#' @param sample_input, boolean 
#' @noRd
Initialize_Population<-function(grid_list,N0,dist_start,mv_jday,sample_input){
	
#Initializes the population matrix
#Option to incorporate heterogeneous landscape preference

#Inputs: 
#centroids: numeric matrix, x y coordinates of centroids of every cell in grid
#grid: matrix with coordinates for all cells in grid
#pop_init_args:
#initialization arguments
#for pop_init_type="init_pop", need a vector with N0 (initial pop size) and ss (sounder size)
#for pop_init_type="init_single", need a vector with init_loc (cell number to initialize group/individual) and n (number of individuals to initialize)
#pop_init_type: string, "init_pop" or "init_single"
#pop_init_grid_opts: string, "homogeneous" or "ras" or "heterogeneous"
	
  grid=grid_list$grid
  centroids=grid_list$centroids
  start_range=colnames(grid_list$grid)[8]
  
  ind=which(centroids[,which(colnames(centroids)==start_range)]<dist_start)

  ## Initialize population 
  
    #use this to weight preference so that still end up with N0 size population
    pref.wt=N0/length(ind) 
    
    #assign to cells with weighted preference
    assigns=rbinom(length(ind),1,pref.wt)
    
    #get the locations where individuals have been initialized
    init_locs<-ind[assigns==1] 
    
    #Initialize the population matrix
    #each row is a caribou
    pop<-matrix(nrow=length(init_locs),ncol=10)
    pop[,1]=1
    pop[,3]=init_locs #this will be grid location (row number)
    pop[,4]=0 #this will be assigned movement distance
    pop[,5]=centroids[pop[,3],1] #present location X 
    pop[,6]=centroids[pop[,3],2] #present location Y
    pop[,7]=1 #this will be behavioral state (based on row of mv_jday), starting with calving
    pop[,8]=8 #column of grid to use for selection preference for current state movement
    pop[,9]=mv_jday[1,2] #calving period step length shape
    pop[,10]=mv_jday[1,3] #calving period step length rate
    
    #display current lc vals in pop mat
    pop[,2]=grid[pop[,3],8]
    
    if(any(pop[,3]>nrow(centroids))){
      stop("agents initialized off the grid")
    }
    
  ## Tidying outputs 
  
  #add column names
  colnames(pop)=c("N","lc","cell","dist","ctrx","ctry","state","gridcol","sl_shp","sl_rat")
  
  #error catches
  if(any(pop[,3]>nrow(centroids))){
    stop("agents initialized off the grid")
  }

  return(pop)
  
}

# CentroidsRowtoXY - helper --------
CentroidsRowtoXY<-function(locs,coords){
  xy=as.data.frame(coords[locs,])
  return(xy)
}

# Movement - helper ---------
Movement=function(pop,centroids,shape,rate,cent_col,road_coords,inc){
  nshp=unique(pop[,9])
  nrat=unique(pop[,10])
  
  if(length(nshp)==1&length(nrat)==1){
  #get distances from gamma distribution
  pop[,4]=rgamma(nrow(pop),shape=shape,rate=rate)
  #need incorp vairable shape/rate
  } else{
    for(i in 1:length(nshp)){
    pop[which(pop[,9]==nshp[i]),4]=rgamma(length(pop[which(pop[,9]==nshp[i]),4]),shape=nshp[i],rate=nrat[i])
    }
  }
  
  #set those less than grid resolution to 0
  pop[pop[,4]<inc,4]=0 
  
  #move
  #Note: input 2 is unneeded, leaving as placeholder while movement functions are coded
  #mv_pref determines type of movement options. 2 is only option available, see cpp script for more details
  #apoplocs is current location, needed for when distance=0, stays in same cell
  m1=parallelMovementRcpp_portion(pop,pop[,1,drop=FALSE],pop[,3,drop=FALSE],centroids,road_coords,1,cent_col,inc)

  #update locations
  pop[,3]=m1
  
  #update lc vals of current new cell to pop
  pop[,2]=centroids[pop[,3],3]
  
  #update x and y vals of current new cell to pop
  pop[,5]=centroids[pop[,3],1] #x
  pop[,6]=centroids[pop[,3],2] #y
  
  return(pop)
}

# Run_Simulation_Rep - helper ---------
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
  
  # Initialize caribou on landscape
  pop<-Initialize_Population(grid_list,N0,dist_start,mv_jday,sample_input=TRUE)
  centroids=grid_list$centroids
  
  # Output initial condition objects
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
  
  # Start run through jdays
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
  
  # Output tracking object
  
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


# add_cols_track - helper ----
add_cols_track<-function(track, mv_jday){
  track$day=1:nrow(track)
  track$state=1
  track$state[track$day>=mv_jday$start[2]]<-2
  track$state[track$day>=mv_jday$start[3]]<-3
  track$state[track$day>=mv_jday$start[5]]<-5
  
  return(track)
}

# Process_Outputs - helper ----------
Process_Outputs<-function(output_list,grid_list,akc3,mv_jday,inc){
  centroids=grid_list$centroids
  processed_outputs=vector(mode="list",length=0)
  outputs=names(output_list)
  
  if("init_locs"%in%outputs){
  init_locs_out=output_list$init_locs
  templist=vector(mode="list",length=1)
  templist[[1]]=init_locs_out
  processed_outputs=append(processed_outputs,templist)
  names(processed_outputs)[length(processed_outputs)]="init_locs"
  }
  
  if("tracking"%in%outputs){
    tracking=output_list$tracking
    coords=terra::crds(akc3)
    track_list=
      apply(tracking,1, function(x)
      CentroidsRowtoXY(x,coords),
      simplify=FALSE
      )
    
    track_list2=lapply(track_list,add_cols_track, mv_jday=mv_jday)

    templist=vector(mode="list",length=1)
    templist[[1]]=track_list2
    processed_outputs=append(processed_outputs,templist)
    names(processed_outputs)[length(processed_outputs)]="tracking"
  }
  
  if("all_pop"%in%outputs){
    templist=vector(mode="list",length=1)
    templist[[1]]=output_list$all_pop
    processed_outputs=append(processed_outputs,templist)
    names(processed_outputs)[length(processed_outputs)]="all_pop"
  }
  
  return(processed_outputs)
  
  }

# Range_Simulate - export -----------
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

# Vizualize_Tracks - export --------
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
