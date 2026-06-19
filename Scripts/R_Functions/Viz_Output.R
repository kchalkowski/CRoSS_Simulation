
Tracking_Viz<-function(tracking,
												filename,
												sample_input=FALSE,
												akc3=NULL,
												road=NULL,
												range_list=NULL
												){
	
	#tracking is list of tracks in simulation
	#each item in list is a caribou
		#each row in each item is a jday
	trackdf=do.call(rbind,tracking)
	
	if(sample_input){
	myPlot=ggplot(trackdf, aes(x, y, colour = state)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  # Here comes the gganimate specific bits
  transition_time(day) +
  ease_aes('linear')+theme_minimal()
	animate(myPlot, fps = 5, width = 200, height = 200, renderer = gifski_renderer())
	anim_save(paste0("Output/",filename))
	} else{
		
	require(rnaturalearth)
	require(rnaturalearthdata)
	if(!is.null(akc3)){

	#road=ambler_layers$ranges[[1]]
	rpts=road$coords
	rsf=st_as_sf(as.data.frame(rpts),coords=c(1,2),crs=sf::st_crs(akc3))
	line_geom <- st_sfc(st_linestring(st_coordinates(rsf)))
	line_sf <- st_sf(geometry = line_geom, crs = st_crs(akc3))
	
	tracksf=sf::st_as_sf(trackdf,coords=c(1,2),crs=sf::st_crs(range_list[[1]]))
	world <- ne_countries(scale='medium',returnclass = 'sf')
	usa <- subset(world, admin == "United States of America")
	alaska <- ggplot(data = usa) +
     geom_sf(fill = "lightgray", color=NA)+
	theme(panel.background = element_rect(fill = "aliceblue"))
	
	#get bbox coords
	coords=terra::crds(akc3)
	minx=min(coords[,1])-250000
	miny=min(coords[,2])-100000
	maxx=max(coords[,1])+100000
	maxy=max(coords[,2])+120000
	
	#make state as factor
	tracksf$state=as.factor(tracksf$state)
	
	myPlot=
	alaska +
  geom_sf(tracksf, 
  				mapping=aes(colour = state),alpha = 0.7, show.legend = FALSE)+
	scale_colour_manual(values=c("turquoise","magenta"))+
  geom_sf(data=line_sf,show.legend = FALSE)+
	coord_sf(crs = sf::st_crs(range_list[[1]]), 
     					xlim = c(minx, maxx), 
     					ylim = c(miny, maxy), 
     					expand = FALSE, 
     					datum = NA)+
	transition_time(day) +
  ease_aes('linear')+theme_minimal()
	
	animate(myPlot, fps = 5, width = 200, height = 200, renderer = gifski_renderer())
	anim_save(paste0("Output/",filename))
	}
		}
	
	return(trackdf)
	
	}


PlotRangeLayers<-function(range_layers,wah_r,folder,road){
	require(rnaturalearth)
	require(rnaturalearthdata)
	require(dplyr)
	require(stringr)
	
	if(!dir.exists(paste0("Output/",folder))){
		dir.create(paste0("Output/",folder))
		}
	
	ranges=range_layers$ranges
	rn=range_layers$range_names
	
	coords=terra::crds(wah_r)
	minx=min(coords[,1])-250000
	miny=min(coords[,2])-100000
	maxx=max(coords[,1])+100000
	maxy=max(coords[,2])+120000
	
	world <- ne_countries(scale='medium',returnclass = 'sf')
	usa <- subset(world, admin == "United States of America")
	alaska <- ggplot(data = usa) +
     geom_sf(fill = "lightgray", color=NA)+
	theme(panel.background = element_rect(fill = "aliceblue"))
	
	#remove second yr from winter and annual to simplify regex
	rn[grep("_\\d",rn)]=stringr::str_sub(rn[grep("_\\d",rn)],1,-4)

	rdf=data.frame("range_name"=rn)
	
	#subset by year
	result <- rdf %>%
  mutate(extracted_number = str_extract(range_name, "\\d+"))
	
	ny=unique(result$extracted_number)
	
	for(i in 1:length(ny)){
		yr=ny[i]
		names_yr=rn[grep(yr,rn)]
		ranges_yr=ranges[grep(yr,rn)]
		
		for(j in 1:length(ranges_yr)){
			ranges_yr[[j]]$season=names_yr[j]
			}
		
		ranges_sf=dplyr::bind_rows(ranges_yr)
		
	myplot=
	alaska +
  geom_sf(ranges_sf, 
  				mapping=aes(fill = season),alpha = 0.7, show.legend = TRUE)+
	geom_sf(data=road,show.legend = FALSE)+
	coord_sf(crs = sf::st_crs(ranges_sf), 
     					xlim = c(minx, maxx), 
     					ylim = c(miny, maxy), 
     					expand = FALSE, 
     					datum = NA)+
			ggtitle(paste0("Seasonal ranges for year ",ny[i]))
		
		ggsave(
			filename=paste0("Output/",folder,"/seasonal_range_yr",ny[i],".png"),
			plot=myplot,
			width=8,
			height=8,
			units="in",
			bg="white"
			)
		
	
		}
	
	
	}



