# Caribou-Road Systems Science (CRoSS) Simulation    
The purpose of this pipeline is to generate a predictive simulation of caribou movements in response to roads.     

# Overview   
This pipeline in it's current form can run two kinds of movement simulations
1. A more abstract simulation featuring movement between sample range polygons divided by a sample polyline road on a 100x100 grid
2. A simulation featuring movement between select Western Arctic Herd winter and calving ranges with a sample generated polyline road on a raster grid large enough to contain entire WAH range plus a 100km buffer to prevent edge effects

# How to use this pipeline
1. Clone this repository
2. Download input geodatabases needed to run the WAH simulation.   
    * WAH_Ranges: https://irma.nps.gov/DataStore/Reference/Profile/2318272   
    * Ambler_Road: https://eplanning.blm.gov/Map-Data/?id=9ba0fa87-a7f2-f011-8407-001dd803d067&spid=4c183c4d-a8f2-f011-8407-001dd80c29f3   
3. Create a folder called Input in the root directory of the pipeline
4. Unzip geodatabases into the Input folder
5. Run RunTargets.R to run the pipeline

# Next steps   
## Overall model framework
* Convert gamma-distributed step-length random walk to correlated velocity model movement (using example tau and speed parameters with discrete CVM formulation)
* Create algorithm to change movement process (i.e., speed/tau) dependent on road intersection
* Currently roads are 100% impermeable, add user input permeability as probability

## Sample setup
* Add user input in targets to change range polygon parameters
* Add user input in targets to change road parameters
* Add random generation of polygon/road range option



