
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
	tracksf=sf::st_as_sf(trackdf,coords=c(1,2),crs=sf::st_crs(range_list$p1))
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
  geom_sf(data=road,show.legend = FALSE)+
	coord_sf(crs = sf::st_crs(range_list$p1), 
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
	
	return("string2")
	
	}






