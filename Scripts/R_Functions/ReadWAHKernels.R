
Range_Ops<-function(range,contour){
	range=range[range$Contour==contour,]
	range=sf::st_cast(range,"POLYGON")
	return(range)
	}

Pull_Range_Layers=function(Input_folder,gdb_filename,ambler=FALSE){
path <- paste0(Input_folder,"/",gdb_filename)
layer_list = st_layers(path)
layers=layer_list$name
if(!ambler){
ranges=vector(mode="list",length=length(layers))
for(i in 1:length(layers)){
range=vect(path,layer=layers[i])
ranges[[i]]=sf::st_as_sf(range)
}

ranges=lapply(ranges,Range_Ops,contour=50)


range_out=list("ranges"=ranges,"range_names"=layers)

} else{

ranges=vector(mode="list",length=1)
range=vect(path,layer=layers[34])
ranges[[1]]=sf::st_as_sf(range)
layers=layers[34]

pt1=st_cast(st_geometry(ranges[[1]])[28],"POINT")[1]
pt2=st_cast(st_geometry(ranges[[1]])[6],"POINT")[1]

coords=matrix(nrow=2,ncol=2)
coords[1,]=st_coordinates(pt1)
coords[2,]=st_coordinates(pt2)
coords[1,1]=-157992.5 #adjust this to see road effect with further over
coords[2,1]=coords[2,1]-70000 #adjust to keep on raster map
coords[2,2]=coords[2,2]+70000 #adjust to keep on raster map
range_out=list("ranges"=ranges,"coords"=coords)


	}


return(range_out)
}

#sel_range_names=c("winter_22_23","calving23")
Sample_WAH_Layers<-function(wah_range_layers,sel_range_names){
range_names=wah_range_layers$range_names
ranges=wah_range_layers$ranges
range_list_out=vector(mode="list",length=length(sel_range_names))
names(range_list_out)=sel_range_names
for(i in 1:length(sel_range_names)){
	range_list_out[[i]]=ranges[[which(range_names==sel_range_names[i])]]
}
return(range_list_out)
}

