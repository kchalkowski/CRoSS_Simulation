# Purpose ------

#Initializes the population matrix
#Option to incorporate heterogeneous landscape preference

# Function ------

#Inputs: 
#centroids: numeric matrix, x y coordinates of centroids of every cell in grid
#grid: matrix with coordinates for all cells in grid
#pop_init_args:
#initialization arguments
#for pop_init_type="init_pop", need a vector with N0 (initial pop size) and ss (sounder size)
#for pop_init_type="init_single", need a vector with init_loc (cell number to initialize group/individual) and n (number of individuals to initialize)
#pop_init_type: string, "init_pop" or "init_single"
#pop_init_grid_opts: string, "homogeneous" or "ras" or "heterogeneous"
Initialize_Population<-function(grid_list,N0,dist_start){
  grid=grid_list$grid
  centroids=grid_list$centroids
  ind=which(centroids[,which(colnames(centroids)=="calving_area.kmz") ]<dist_start)
  
  ## Initialize population ----------------------
  
    #use this to weight preference so that still end up with N0 size population
    pref.wt=N0/length(ind) 
    
    #assign to cells with weighted preference
    assigns=rbinom(length(ind),1,pref.wt)
    
    #get the locations where individuals have been initialized
    init_locs<-ind[assigns==1] 
    
    #Initialize the population matrix
    #each row is a caribou
    pop<-matrix(nrow=length(init_locs),ncol=8)
    pop[,1]=1
    pop[,3]=init_locs #this will be grid location (row number)
    pop[,4]=0 #this will be assigned movement distance
    pop[,5]=centroids[pop[,3],1] #present location X 
    pop[,6]=centroids[pop[,3],2] #present location Y
    pop[,7]=1 #this will be behavioral state (based on row of mv_jday), starting with calving
    pop[,8]=8 #column of grid to use for selection preference for current state movement
    
    #display current lc vals in pop mat
    pop[,2]=grid[pop[,3],8]
    
    if(any(pop[,3]>nrow(centroids))){
      stop("agents initialized off the grid")
    }
    
  ## Tidying outputs -----------
  
  #add column names
  colnames(pop)=c("N","lc","cell","dist","ctrx","ctry","state","gridcol")
  
  #error catches
  if(any(pop[,3]>nrow(centroids))){
    stop("agents initialized off the grid")
  }

  return(pop)
  
}
