
## Read data ----- 
ReadBiomass<-function(path){
  read.csv(file.path(path,"test_biomass.csv"))
}

ReadAKNLCD<-function(path){
  terra::rast(file.path(path,"NLCD_2016_Land_Cover_AK_20200724","NLCD_2016_Land_Cover_AK_20200724.img"))
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


Recode_AK<-function(akc){
  akc[akc==11|akc==12|akc==31]<-1 #barren
  akc[akc==0|akc==21|akc==22|akc==23|akc==24|akc==81|akc==82]<-0 #no data
  akc[akc==41|akc==42|akc==43|akc==90]<-2 #forest
  akc[akc==51|akc==52|akc==71|akc==72|akc==74|akc==95]<-3 #herb/shrub

  return(akc)
}

#### Convert recoded AK map into matrix for simulation ---------
Convert_toGrid<-function(akc2){
  #input ras needs be square, hence subset
  Make_Grid(akc2[1:1335,1592:2926,drop=FALSE])
}




