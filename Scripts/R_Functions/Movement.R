#This doesn't work yet, adapting Rcpp function for caribou movement
Movement=function(pop,centroids,shape,rate,inc,mv_pref,dist=NULL){

  #get distances from gamma distribution
  pop[,4]=rgamma(nrow(pop),shape=shape,rate=rate)
  
  #set those less than inc to 0
  pop[pop[,4]<inc,][,4]=0 
  
  #move
  #Note: inputs 2 and 3 are unneeded, leaving as placeholders while movement functions are coded
  #mv_pref determines type of movement options. 2 is only option available, see cpp script for more details
  m1=parallelMovementRcpp_portion(pop,pop[,1,drop=FALSE],pop[,1,drop=FALSE],centroids,1)

  #update locations
  pop[,3]=m1
  
  #update lc vals of current new cell to pop
  pop[,2]=centroids[pop[,3],3]
  
  return(pop)
}