#This doesn't work fully yet, adapting Rcpp function for caribou movement
Movement=function(pop,centroids,shape,rate){

  #get distances from gamma distribution
  pop[,4]=rgamma(nrow(pop),shape=shape,rate=rate)
  
  #set those less than grid resolution to 0
  pop[pop[,4]<1.0,][,4]=0 
  
  #move
  #Note: input 2 is unneeded, leaving as placeholder while movement functions are coded
  #mv_pref determines type of movement options. 2 is only option available, see cpp script for more details
  #apoplocs is current location, needed for when distance=0, stays in same cell
  m1=parallelMovementRcpp_portion(pop,pop[,1,drop=FALSE],pop[,3,drop=FALSE],centroids,1)

  #update locations
  pop[,3]=m1
  
  #update lc vals of current new cell to pop
  pop[,2]=centroids[pop[,3],3]
  
  #update x and y vals of current new cell to pop
  pop[,5]=centroids[pop[,3],1] #x
  pop[,6]=centroids[pop[,3],2] #x
  
  return(pop)
}