
# Create_Sample_Ras - helper --------
Create_Sample_Ras<-function(len,inc,sample_input=TRUE,range_list=NULL){
	require(terra)

if(sample_input
	){
print("test")
# 1. Define the spatial extent (xmin, xmax, ymin, ymax)
ext_global <- terra::ext(0, 100, 0, 100)

# 2. Initialize the raster with a specific resolution (e.g., 1 degree)
# By default, terra calculates the correct dimensions (rows and columns)
r <- terra::rast(ext = ext_global, resolution = inc)

} else{
	ranges_sf=do.call(rbind,range_list)
	
	#get bbox around ranges
	rbbox=sf::st_bbox(ranges_sf)
	
	#bbox needs to be square
	len_w=abs(rbbox$xmax-rbbox$xmin)
	len_h=abs(rbbox$ymax-rbbox$ymin)
	lendiff=abs(len_w-len_h)
	if(len_w<len_h){
	rbbox[3]=rbbox$xmax+lendiff
	}
	if(len_h<len_w){
	rbbox[4]=rbbox$ymax+lendiff
	}
	
	#Need some extra buffer around bbox to prevent edge effects
	rbbox[1]=rbbox[1]-200000
	rbbox[2]=rbbox[2]-200000
	rbbox[3]=rbbox[3]+200000
	rbbox[4]=rbbox[4]+200000
	
ext_global <- terra::ext(rbbox)
r <- terra::rast(ext = ext_global, resolution = inc, crs=crs(ranges_sf))
}
	
values(r)=0
# 3. Inspect the object properties
#print(r)


return(r)

}

# Make_Grid - helper -------
Make_Grid<-function(object,grid.opt="homogeneous"){
  require(terra)
  
  if(grid.opt=="homogenous"){
    grid.opt="homogeneous"
  }
  
  if(class(object)=="numeric"){
    len=object[1]
    inc=object[2]
  }
  
  if(class(object)=="SpatRaster"){
    ras=object
    len=dim(ras)[1]
    inc=res(ras)[1]
    
    if(dim(ras)[1]!=dim(ras)[2]){stop("raster needs to be square")}
  }
  
  #get number of cells in grid
  cells=len^2
  
  #if grid homogeneous-- can later enter ability to alter LULC
  if("homogeneous"%in%grid.opt){
    #initialize empty grid matrix
    grid=matrix(nrow=round(cells),ncol=7)
  } else {
    #initialize empty grid matrix
    grid=matrix(nrow=round(cells),ncol=8)
  }
  
  #first column is just cell indices
  grid[,1]=1:cells
  
  #Top left X coordinate of each cell
  grid[,2]=rep(seq(0,((inc*len)-inc),inc),times=len)
  
  #Top left Y coordinate of each cell
  grid[,3]=rep(seq(0,((inc*len)-inc),inc),each=len)
  
  #Top right X coordinate of each cell
  grid[,4]=rep(seq(inc,(inc*len),inc),times=len)
  
  #Top right Y coordinate of each cell
  grid[,5]=rep(seq(inc,(inc*len),inc),each=len)
  
  #Center X coordinate of each cell
  grid[,6]=rep(seq(((0+inc)/2),(((inc*len)-inc)+(inc*len))/2,inc),times=len)
  
  #Center Y coordinate of each cell
  grid[,7]=rep(seq(((0+inc)/2),(((inc*len)-inc)+(inc*len))/2,inc),each=len)
  
  #get centroids-only object
  centroids=grid[,c(6,7)]
  
  if(!("homogeneous"%in%grid.opt)){
    
    #simulates a spatially random neutral landscape model with values drawn from a uniform distribution
    #values rescaled to range from 0-1
    if("random"%in%grid.opt){
      r=NLMR::nlm_random(len,len,inc,rescale=TRUE)
      grid[,8]=round(values(r),2)
      
      centroids=cbind(centroids,grid[,8])
      grid.list=list("cells"=cells,"grid"=grid,"centroids"=centroids,"r"=r)
      
    }
    
    if(class(object)=="SpatRaster"){
      #need to get values from ras
      grid[,8]=values(ras)
      #assign to centroids
      centroids=cbind(centroids,grid[,8])
      grid.list=list("cells"=cells,"grid"=grid,"centroids"=centroids)
    }
    
  } else{
    grid.list=list("cells"=cells,"grid"=grid,"centroids"=centroids)
  }
  
  return(grid.list)
  
}

#Create_Dist_Rast - helper --------
#Create distance raster from centroid
Create_Dist_Rast<-function(ctr,ras){
  ctr_ras=terra::rasterize(ctr,ras)
  terra::distance(ctr_ras)
}

#Distance_Ranges - helper ---------
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

#Append_Each_Dist - helper ---------
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

#Append_Grid_Distance - helper ------
Append_Grid_Distance<-function(grid,range_dist_sprc,range_list,sample_input){
  
  for(r in 1:length(range_dist_sprc)){
    name=names(range_list)[r]
    grid=Append_Each_Dist(range_dist_sprc[r],grid,name,sample_input)
  }
  
  return(grid)
}

# Format_Spatial_Data --------
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

# Move_Jday - helper ---------
Move_Jday<-function(sample_input=TRUE,
									  sel_range_names=NULL,
									  sl_shp=NULL,
										sl_rat=NULL,
										start=NULL,
								    end=NULL
										){
	
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

# Set_Spatial_Movement - user ---------
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