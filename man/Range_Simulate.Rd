\name{Range_Simulate}
\alias{Range_Simulate}
\title{
Run simulation of animal movement and road interaction
}
\description{
Run simulation of animal movement and road interaction using specified movement distance per time step and preference for movement towards seasonal ranges. Movement algorithm determines distance for each individual at each time step using input gamma distribution parameters, and selects cells preferentially by selecting lowest distance value for current seasonal range determined from range_dist_sprc SpatRasterCollection within spatial_input, where distance values represent the minimum distance from seasonal range centroids.    

Number of time steps in simulation are determined from mv_jday, starting with the minimum jday in the 'start' column and ending with the maximum jday in the 'end' column.    

N0 number of individuals are initialized at distance from first seasonal range 'dist_start'.    
}
\usage{
Range_Simulate(spatial_input,
				mv_jday,
				N0,
				dist_start,
				out.opts=c("tracking"))
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{spatial_input}{List, output from Format_Spatial_Data}
  \item{mv_jday}{Data frame, output from Set_Spatial_Movement}
  \item{N0}{Integer, number of individuals to simulate}
  \item{dist_start}{Integer, distance in meters from centroid of first range to initialize individuals}
  \item{out.opts}{out.opts}
}
\value{
List
}
\references{
}
\author{
Kayleigh Chalkowski, Kayleigh.Chalkowski@tamuk.edu
}
\note{
}

\seealso{
}
\examples{

}
