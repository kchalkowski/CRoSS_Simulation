
Tracking_Viz<-function(tracking){
	#tracking is list of tracks in simulation
	#each item in list is a caribou
		#each row in each item is a jday
	trackdf=do.call(rbind,tracking)
	
	myPlot=ggplot(trackdf, aes(x, y, colour = state)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  # Here comes the gganimate specific bits
  transition_time(day) +
  ease_aes('linear')+theme_minimal()
	animate(myPlot, fps = 5, width = 200, height = 200, renderer = gifski_renderer())
	anim_save("Output/movement_animation.gif")
	
	return("string")
	
	}






