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



akc=tar_read(akc)

