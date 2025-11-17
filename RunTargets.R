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

range_dist_sprc<-tar_read(range_dist_sprc)
grid2<-tar_read(grid2)



line1=out$tracking[[1]]
mapview(line1)


line2=out$tracking[[2]]
mapview(line2)
#movements aren't drifting, staying in one place and around center
#need make sure they're getting updated at each timestep