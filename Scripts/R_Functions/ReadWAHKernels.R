
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

range_out=list("ranges"=ranges,"range_names"=layers)

} else{
print("ambler")
ranges=vector(mode="list",length=1)
range=vect(path,layer=layers[34])
ranges[[1]]=sf::st_as_sf(range)
layers=layers[34]

pt1=st_cast(st_geometry(ranges[[1]])[28],"POINT")[1]
pt2=st_cast(st_geometry(ranges[[1]])[6],"POINT")[1]

coords=matrix(nrow=2,ncol=2)
coords[1,]=st_coordinates(pt1)
coords[2,]=st_coordinates(pt2)

range_out=list("ranges"=ranges,"coords"=coords)


	}


return(range_out)
}

Sample_WAH_Layers<-function(wah_range_layers){
range_names=wah_range_layers$range_names
ranges=wah_range_layers$ranges
winter=ranges[[which(range_names=="winter_23_24")]]
calve=ranges[[which(range_names=="calving25")]]

return(list("p1"=winter,"p2"=calve))
}

