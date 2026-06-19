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

#Current problem
	#impassable barrier is extending beyond start and end point of road
	#being treated as line rather than line segment

