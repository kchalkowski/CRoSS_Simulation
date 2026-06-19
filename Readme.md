# Caribou-Road Systems Science (CRoSS) Simulation    
The purpose of this repository is to develop a predictive simulation on caribou movements in response to roads.     

# Current status
* Simple movement framework based on movement between seasonal range polygons

# Next steps   
## Overall model framework
* Convert gamma-distributed step-length random walk to correlated velocity model movement (using example tau and speed parameters with discrete CVM formulation)
* Create algorithm to change movement process (i.e., speed/tau) dependent on road intersection
* Currently roads are 100% impermeable, add user input permeability as probability
* Add user input to set mv jday df

## Sample setup
* Add user input in targets to change range polygon parameters
* Add user input in targets to change road parameters
* Add random generation of polygon/road range option

## Realistic range input
* Add instructions for WAH range input data (link and how to add to pipeline locally)
* Allow user input for selecting ranges from data




