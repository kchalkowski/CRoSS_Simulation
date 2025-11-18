library(targets)
library(tarchetypes)

#set directories
setwd(this.path::this.dir())
outdir<-file.path("Output")

#source targets file
source("_targets.R")

#Get pipeline
tar_manifest()

#Make pipeline
tar_make()
#tar_make_clustermq(workers = 6)


#Interactive troubleshooting
#checking outputs
library(mapview)
library(sf)

range_dist_sprc<-tar_read(range_dist_sprc)


out<-tar_read(processed_outputs)
line2=out$tracking[[7]]
#mapview(line2)
mapview(line2,zcol="state")
mapview(line2,zcol="state")+mapview(range_dist_sprc[3])

PT2=line2 %>% st_sf %>% st_cast("POINT")

grid_list<-tar_read(grid_list)
centroids=grid_list$centroids

range_dist_sprc<-tar_read(range_dist_sprc)

hist(rgamma(100,shape=10,rate=0.3))

pops<-out[[3]]


pops[[53]][,7]

