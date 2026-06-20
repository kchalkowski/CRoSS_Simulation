
# Get distance rasters and append to grid ---------

#Helper function: Create distance raster from centroid
Create_Dist_Rast<-function(ctr,ras){
  ctr_ras=terra::rasterize(ctr,ras)
  terra::distance(ctr_ras)
}

Range_Ops<-function(range,contour){
	range=range[range$Contour==contour,]
	range=sf::st_cast(range,"POLYGON")
	#st_centroid(range)
	}

Distance_Ranges<-function(range_list,akc3,sample_input,contour=NULL){
	if(sample_input){
	#get centerpoint for each polygon
  range_centers=lapply(range_list,st_centroid)
	} else{
		
	range_centers=lapply(range_list,st_centroid)
		
  }

  base_rast=akc3
  
  #create range dists vectors
  range_dists=lapply(range_centers,Create_Dist_Rast,ras=base_rast)
  range_dists=terra::sprc(range_dists)
  names(range_dists)=names(range_list)
  
  
  return(range_dists)
}


Append_Each_Dist<-function(distr,grid,name,sample_input){
	if(!sample_input){
  distvals=round(values(distr),0)
	} else{
	distvals=round(values(distr),0)
		}
  grid$grid=cbind(grid$grid,distvals)
  colnames(grid$grid)[ncol(grid$grid)]=name
  grid$centroids=cbind(grid$centroids,distvals)
  colnames(grid$centroids)[ncol(grid$centroids)]=name
  return(grid)
}

Append_Grid_Distance<-function(grid,range_dist_sprc,range_list,sample_input){
  
  for(r in 1:length(range_dist_sprc)){
    name=names(range_list)[r]
    grid=Append_Each_Dist(range_dist_sprc[r],grid,name,sample_input)
  }
  
  return(grid)
}

# Move jday df ---------
#will allow inputs later
Move_Jday<-function(sample_input=TRUE,
									  sel_range_names=NULL,
									  sl_shp=NULL,
										sl_rat=NULL,
										start=NULL,
								    end=NULL
										){
	
	#Earlier version
  #jday 1-60, resource driven, select inside calving area
  #jday 61-150, resource driven, select inside summer area
  #jday 151-X, go to wintering grounds, change movement when inside wintering grounds
  #jday X-300, resource driven, select inside wintering grounds
  #jday 301-X, go to calving grounds, change movement when inside calving grounds
	
	#Key for earlier version:
		#migr
			#1-migratory movement- move towards destination range, then change movement rate to next season parameters when reach that location
			#0-non-migr movement, resource driven
		#attract - ? can't remember what these did. could be a switch in movement function.
			#1, 2, 3
		#start/end - jday to switch season to next. '0' switches mean they switch when they reach certain location rather than by jday
	
  if(sample_input){
  mv_jday=data.frame(matrix(nrow=3,ncol=7))
  colnames(mv_jday)=c("state","sl_shp","sl_rat","migr","attract","start","end")
  mv_jday[,1]=c("p1",
                "p2",
                "p3")
  mv_jday[,2]=c(5,5,10.0)
  mv_jday[,3]=c(0.3550,0.3550,0.3)
  mv_jday[,4]=c(1,1,1)
  mv_jday[,5]=c(1,1,1)
  mv_jday[,6]=c(1,100,200)
  mv_jday[,7]=c(99,199,365)
  } else{

  mv_jday=data.frame(matrix(nrow=length(sel_range_names),ncol=7))
  colnames(mv_jday)=c("state","sl_shp","sl_rat","migr","attract","start","end")
  mv_jday[,1]=sel_range_names
  mv_jday[,2]=sl_shp
  mv_jday[,3]=sl_rat
  mv_jday[,4]=rep(1,length(sel_range_names))
  mv_jday[,5]=rep(1,length(sel_range_names))
  mv_jday[,6]=start
  mv_jday[,7]=end
   #mv_jday[,2]=c(10000,10000,10000)
  #mv_jday[,3]=c(0.8,0.8,0.8)
  #mv_jday[,4]=c(1,1,1)
  #mv_jday[,5]=c(1,1,1)
  #mv_jday[,6]=c(1,100,200)
  #mv_jday[,7]=c(99,199,365)

  	}
  
  return(mv_jday)
}

#Do behavorial state changes by day/location
Behav_St_Changes<-function(d,pop,mv_jday,grid){
  
  #pull state changes from mv_jday
  cal_sum=mv_jday$start[2]
  sum_fal=mv_jday$start[3]
  win_spr=mv_jday$start[5]
  
  #Calving switch to summer
  if(d==cal_sum){
    pop[,7]=2
    pop[,9]=mv_jday[2,2]
    pop[,10]=mv_jday[2,3]
  }
  
  #Summer switch to fall
  if(d==sum_fal){
    pop[,7]=3  
    pop[,8]=11
    pop[,9]=mv_jday[3,2]
    pop[,10]=mv_jday[3,3]
  }
  
  #fall switch to winter
  if(d>sum_fal&any(pop[,7]==3)){
    #need to create object with 1/0 if in the winter/summer/calving ranges
    #for now just ask if within 30 km of centroid
    m.ind=which(pop[,7]==3)
    w.ind=which(grid[pop[m.ind,3],11]<30)
    pop[m.ind[w.ind],7]<-4
    pop[m.ind[w.ind],8]<-8
    pop[m.ind[w.ind],9]=mv_jday[4,2]
    pop[m.ind[w.ind],10]=mv_jday[4,3]
  }
  
  #winter switch to spring
  if(d==win_spr){
    pop[,7]=5
    pop[,8]=9
    pop[,9]=mv_jday[5,2]
    pop[,10]=mv_jday[5,3]
  }
  
  #spring migr switch to calving
  if(d>win_spr){
    #need to create object with 1/0 if in the winter/summer/calving ranges...
    #for now just ask if within 30 km of centroid...
    m.ind=which(pop[,7]==5)
    w.ind=which(grid[pop[m.ind,3],9]<30)
    pop[m.ind[w.ind],7]<-1
    pop[m.ind[w.ind],8]<-8
    pop[m.ind[w.ind],9]=mv_jday[1,2]
    pop[m.ind[w.ind],10]=mv_jday[1,3]
  }
  
  return(pop)
  
}

# Run simulation ---------
Run_Simulation<-function(grid_list,
												 road_list,
                         mv_jday,
                         N0,
												 inc,
                         dist_start,
                         akc3,
                         cpp_functions,
                         out.opts=NULL){
  out.list=vector(mode="list",length=0)
  
  # Pull coords for output summaries
  coords=terra::crds(akc3)
  
  # Initialize cpp functions -----
  Rcpp::sourceCpp(cpp_functions[[1]])
  
  print("sourced cpp script")
  
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
      #to coords respective to the grid
      rcoords=road_list$coords
      #rcoords[2,1]=rcoords[2,1]-70000
      #rcoords[2,2]=rcoords[2,2]+70000
      rsf=sf::st_as_sf(as.data.frame(rcoords),coords=c(1,2),crs=sf::st_crs(akc3))
      #mapview(wah_r)+mapview(rsf)
      
      #1-get cell number of raster where the coordinates lie
      cells=terra::cellFromXY(akc3,st_coordinates(rsf))
      #2-get the x/y of centroids from this
      rcoords_grid=centroids[cells,1:2]
      
  
  print("starting movement")

  		for(d in 1:151){    
   
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

#Helper function
add_cols_track<-function(track, mv_jday){
  track$day=1:nrow(track)
  track$state=1
  track$state[track$day>=mv_jday$start[2]]<-2
  track$state[track$day>=mv_jday$start[3]]<-3
  track$state[track$day>=mv_jday$start[5]]<-5
  
  return(track)
}

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


#Helper function - convert cell number/centroid row number to x/y coords
CentroidsRowtoXY<-function(locs,coords){
  xy=as.data.frame(coords[locs,])
  return(xy)
}

