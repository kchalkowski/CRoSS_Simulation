
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

#### Convert recoded AK map into matrix for simulation ---------
Convert_toGrid<-function(akc3){
  #input ras needs be square, hence subset
  Make_Grid(akc3)
}

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
  distvals=values(distr)
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





