
## Read data ----- 
ReadBiomass<-function(path){
  read.csv(file.path(path,"test_biomass.csv"))
}

ReadAKNLCD<-function(path){
  terra::rast(file.path(path,"NLCD_2016_Land_Cover_AK_20200724","NLCD_2016_Land_Cover_AK_20200724.img"))
  
  
  }

ReadRanges<-function(path){
  range_files=list.files(file.path(path,"Mock_Shapefiles"))
  calving=st_read(file.path(path,"Mock_Shapefiles","calving_area.kmz"))
  range_list=vector(mode="list",length=length(range_files))
  names(range_list)=range_files
  for(f in 1:length(range_files)){
    range_list[[f]]=st_read(file.path(path,"Mock_Shapefiles",range_files[f]))
  }
  return(range_list)
    }


## Set up landscape data for simulation ----- 

Refactor_AK<-function(akc,type,res=NULL,fact=NULL){
  if(type=="factor"){
    akc_out=aggregate(akc,fact=fact,fun=mean)  
  } 
  
  if(type=="res"){
    akcr=akc
    res(akcr)=res
    akc_out=resample(akc,akcr,method="near")
  }
  return(akc_out)
}

Transform_AK<-function(akc){
  new_crs="EPSG:6393"
  terra::project(akc,new_crs)
}

Recode_AK<-function(akc){
  akc[akc==11|akc==12|akc==31]<-1 #barren
  akc[akc==0|akc==21|akc==22|akc==23|akc==24|akc==81|akc==82]<-0 #no data
  akc[akc==41|akc==42|akc==43|akc==90]<-2 #forest
  akc[akc==51|akc==52|akc==71|akc==72|akc==74|akc==95]<-3 #herb/shrub

  return(akc)
}

Crop_Raster<-function(akc2){
  akc2[1:1335,1592:2926,drop=FALSE]
}

# Convert recoded AK map into matrix for simulation ---------
Convert_toGrid<-function(akc3){
  #input ras needs be square, hence subset
  Make_Grid(akc3)
}

# Get distance rasters and append to grid ---------

#Helper function: Transform to raster type
Transform_CRS_Albers<-function(sfo){
  st_transform(sfo,crs=st_crs(6393))
}

#Helper function: Create distance raster from centroid
Create_Dist_Rast<-function(ctr,ras){
  #terra::distance(ctr,base_rast)
  ctr_ras=terra::rasterize(ctr,ras)
  terra::distance(ctr_ras)
}

Distance_Ranges<-function(range_list,akc3){
  range_centers=lapply(range_list,st_centroid)
  range_centers=lapply(range_centers,Transform_CRS_Albers)
  base_rast=akc3
  range_dists=lapply(range_centers,Create_Dist_Rast,ras=base_rast)
  range_dists=terra::sprc(range_dists)
  names(range_dists)=names(range_list)
  return(range_dists)
  #loses names in targets pipeline.. not sure why.. fix another time
}


Append_Each_Dist<-function(distr,grid,name){
  distvals=round(values(distr)/1000,0)
  grid$grid=cbind(grid$grid,distvals)
  colnames(grid$grid)[ncol(grid$grid)]=name
  grid$centroids=cbind(grid$centroids,distvals)
  colnames(grid$centroids)[ncol(grid$centroids)]=name
  return(grid)
}

Append_Grid_Distance<-function(grid,range_dist_sprc,range_list){
  
  for(r in 1:length(range_dist_sprc)){
    name=names(range_list)[r]
    grid=Append_Each_Dist(range_dist_sprc[r],grid,name)
  }
  
  return(grid)
}

# Move jday df ---------
#will allow inputs later
Move_Jday<-function(){
  #jday 1-60, resource driven, select inside calving area
  #jday 61-150, resource driven, select inside summer area
  #jday 151-X, go to wintering grounds, change movement when inside wintering grounds
  #jday X-300, resource driven, select inside wintering grounds
  #jday 301-X, go to calving grounds, change movement when inside calving grounds
  mv_jday=data.frame(matrix(nrow=5,ncol=7))
  colnames(mv_jday)=c("state","sl_shp","sl_rat","migr","attract","start","end")
  mv_jday[,1]=c("calving",
                "summer",
                "falmigr",
                "winter",
                "sprmigr")
  mv_jday[,2]=c(5,5,10.0,5,10.0)
  mv_jday[,3]=c(0.3550,0.3550,0.3,0.3550,0.3)
  mv_jday[,4]=c(0,0,1,0,1)
  mv_jday[,5]=c(1,2,3,3,1)
  mv_jday[,6]=c(1,61,151,0,301)
  mv_jday[,7]=c(60,150,0,300,0)
  
  return(mv_jday)
}

#Helper function - convert cell number/centroid row number to x/y coords
CentroidsRowtoXY<-function(locs,centroids,ras){
  clocs=centroids[as.integer(locs),c(1,2)]
  ccol=round(clocs[,1])
  crow=round(clocs[,2])
  
  cx=terra::xFromCol(ras,ccol)
  cy=terra::yFromRow(ras,crow)
  xy=data.frame("x"=cx,"y"=cy)
  
  return(xy)
}

#Helper function
ConvertSFtoLines<-function(x){
  x=sf::st_as_sf(as.data.frame(x),coords=c(1,2),crs=st_crs(6393))
  x %>% st_combine() %>% st_cast("LINESTRING")
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
    #need to create object with 1/0 if in the winter/summer/calving ranges...
    #for now just ask if within 30 km of centroid...
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
                         mv_jday,
                         N0,
                         dist_start,
                         akc3,
                         cpp_functions,
                         out.opts=NULL){
  out.list=vector(mode="list",length=0)
  
  # Initialize cpp functions -----
  #for(i in 1:length(cpp_functions)){
    #print(paste0("sourcing ",cpp_functions[[i]]))
    #Rcpp::sourceCpp(cpp_functions[[i]])
  #}
  Rcpp::sourceCpp(cpp_functions[[1]])
  
  print("sourced cpp script")
  
  
  # Initialize caribou on landscape ---------
  pop<-Initialize_Population(grid_list,N0,dist_start,mv_jday)
  
  # Output initial condition objects ---------
  if(!missing(out.opts)){
    if("init_locs"%in%out.opts){
      templist=vector(mode="list",length=1)
      centroids=grid_list$centroids
      cdf=CentroidsRowtoXY(pop[,3],centroids,akc3)
      
      templist[[1]]=cdf
      out.list=append(out.list,templist)
      names(out.list)[[length(out.list)]]="init_locs"
    }
    
    if("all_pop"%in%out.opts){
      all_pop=vector(mode="list",length=365)
    }
    
  }
  
  # Start run through jdays ---------
  shape=mv_jday$sl_shp[1] #hard coding these for now
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
  
  print("starting movement")

      #for(d in 1:365){
      for(d in 1:365){
        
      if("all_pop"%in%out.opts){
      all_pop[[d]]<-pop
      }
        
      print(d)
      pop=Movement(pop,centroids,shape,rate)
      if(tracking){
      loc_mat=cbind(loc_mat,pop[,3])
      }
      pop=Behav_St_Changes(d,pop,mv_jday,grid_list$grid)
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

#Helper function
ConvertSFtoStateLines<-function(x){
  x=sf::st_as_sf(as.data.frame(x),coords=c(1,2),crs=st_crs(6393))
  
  l1=st_as_sf(x[x$state==1,] %>% st_combine() %>% st_cast("LINESTRING"))
  l2=st_as_sf(x[x$state==2,] %>% st_combine() %>% st_cast("LINESTRING"))
  l3=st_as_sf(x[x$state==3,] %>% st_combine() %>% st_cast("LINESTRING"))
  l5=st_as_sf(x[x$state==5,] %>% st_combine() %>% st_cast("LINESTRING"))
  
  x1=rbind(l1,l2,l3,l5)
  x1$state=c("calving","summer","fallwinter","spring")
  return(x1)
  }

Process_Outputs<-function(output_list,grid_list,akc3,mv_jday){
  centroids=grid_list$centroids
  processed_outputs=vector(mode="list",length=0)
  outputs=names(output_list)
  
  if("init_locs"%in%outputs){
  init_locs=output_list$init_locs
  init_locs_out=sf::st_as_sf(as.data.frame(init_locs),coords=c(1,2),crs=st_crs(6393))
  
  templist=vector(mode="list",length=1)
  templist[[1]]=init_locs_out
  processed_outputs=append(processed_outputs,templist)
  names(processed_outputs)[length(processed_outputs)]="init_locs"
  }
  
  if("tracking"%in%outputs){
    tracking=output_list$tracking
    track_list=
      apply(tracking,1, function(x)
      CentroidsRowtoXY(x,centroids,akc3),
      simplify=FALSE
      )
    
    track_list2=lapply(track_list,add_cols_track, mv_jday=mv_jday)
    lines=lapply(track_list2, ConvertSFtoStateLines)

    templist=vector(mode="list",length=1)
    templist[[1]]=lines
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



