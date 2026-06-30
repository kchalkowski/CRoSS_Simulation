# crossR
###### Simulate animal-road interactions
###### Kayleigh Chalkowski

#### About this package
`crossR` is a collection of functions to simulate spatially-explicit animal movement interactions with linear barriers such as roads. It allows you to vary animal movement characteristics in two ways: 1) "where to move?" according to seasonal ranges, where movement is directed towards the centroids of range polygons; and 2) "how to move?", by sampling distances in meters from a gamma-distribution representing step lengths at a given timestep.    

#### To install this package
1. Download .zip file
2. Install the package:
`install.packages(“path/to/file/crossR_1.0.tar.gz", repos = NULL, type="source")`

#### To use the package
Access the vignette:    
`vignette("crossR-vignette")`

#### Upcoming improvements    

1. **Make road input more realistic** - Currently, roads are input as start and end coordinate to form a straight line barrier. Should allow for user input of sf LINESTRING or MULTILINESTRING and format for use in simulation.
2. **Improve movement algorithm** 
	+ **Improve realism of movement model for caribou** - Currently, movement is driven by gamma-distributed step lengths, amounting to a random walk. This is somewhat unrealistic for caribou movement, where movement speed is often correlated with earlier time steps such as in a correlated velocity model (i.e., CVM, Ornstein-Uhlenbeck). The algorithm would need to be changed to a CVM by storing the velocity for the previous timestep in the population matrix (with the starting velocity being a user-input parameter), and calculating the velocity of the next timestep using that velocity and correlation of velocity at the given timestep (i.e., tau). 
	+ **Add option to change movement rules after road interaction** - this could be a switch where the user can input movement rules following a road interaction.
3. **Road permeability** Roads in the current framework are completely impermeable. User-input permeability values could code road permeability overall, or we could integrate this framework with R package `permeability` to allow for within-road permeability differences.