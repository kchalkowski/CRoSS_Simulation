Create_Sample_Ras<-function(len,inc){
	require(terra)

# 1. Define the spatial extent (xmin, xmax, ymin, ymax)
ext_global <- terra::ext(0, 100, 0, 100)

# 2. Initialize the raster with a specific resolution (e.g., 1 degree)
# By default, terra calculates the correct dimensions (rows and columns)
r <- terra::rast(ext = ext_global, resolution = inc)

values(r)=0
# 3. Inspect the object properties
#print(r)
return(r)

}

Create_Range_Polygons<-function(){
	
#Set some coordinates
		coords1 <- matrix(c(
  10, 4,
	30,20,
	20,40,
	15,30,
  10, 4
), ncol = 2, byrow = TRUE)
		
		coords2 <- matrix(c(
  90, 50,
	100,40,
	80,30,
  90, 50
), ncol = 2, byrow = TRUE)

		coords3 <- matrix(c(
  50, 40,
	55,55,
	40,60,
  50, 40
), ncol = 2, byrow = TRUE)
		
# 2. Create the SpatVector polygon object
poly_vector1 <- terra::vect(coords1, type = "polygons")
poly_vector2 <- terra::vect(coords2, type = "polygons")
poly_vector3 <- terra::vect(coords3, type = "polygons")

# 3. View and plot the polygon
plot(poly_vector1, col = "lightblue", border = "darkblue",
	xlim=c(0,100),ylim=c(0,100))
plot(poly_vector2, col = "red", border = "darkblue", add=TRUE)
plot(poly_vector3, col = "red", border = "darkblue", add=TRUE)

#convert into sf polygons
p1=sf::st_as_sf(poly_vector1)
p2=sf::st_as_sf(poly_vector2)
p3=sf::st_as_sf(poly_vector3)

range_list=list(p1,p2,p3)
names(range_list)=c("p1","p2","p3")
#return as list of sf polygons
return(range_list)

}


#Do behavorial state changes by day/location
Behav_St_Changes_Sample<-function(d,pop,mv_jday,grid){
  #in movement function:
		#behav states 3 and 5 are specific to calving/winter ground polygons
			#pulls distance of each caribou to that range (cols3:5 for sample input, p1:p3)
				#bug- all are 0 right now, should have many distances>0
			#selects cell of mindist within possible set to move to
		#need to do this more flexibly
			#ie, get index of column from jday or pop or something
			#maybe behavioural state triggers that change dep on jday or dist algorithm below
			#line 315, indexes 3, this could be input parameter
	
  #pull state changes from mv_jday
  p1_sum=mv_jday$start[1]
  p2_sum=mv_jday$start[2]
  p3_sum=mv_jday$start[3]
  
  #Calving switch to summer
  if(d==p1_sum){
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



