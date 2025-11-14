#This doesn't work yet, adapting Rcpp function for caribou movement
Movement=function(pop,centroids,shape,rate,inc,mv_pref,dist=NULL){

  #get distances from gamma distribution
  pop[,4]=rgamma(nrow(pop),shape=shape,rate=rate)
  
  #set those less than inc to 0
  pop[pop[,4]<inc,][,4]=0 
  
  #move
  m1=parallelMovementRcpp_portion(pop,pop[,3,drop=FALSE],centroids,mv_pref)

  #update locations
  pop[,3]=m1
  
  #update lc vals of current new cell to pop
  pop[,2]=centroids[pop[,3],3]
  
  return(pop)
}