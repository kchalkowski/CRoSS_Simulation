\name{Format_Spatial_Data}
\alias{Format_Spatial_Data}
\title{
Format spatial data to run caribou movement simulation
}
\description{
This function takes in a list of sf polygons and road coordinates, and creates a formatted set of inputs needed for the caribou movement simulation. These intermediate objects include a matrix grid with relative coordinates, a base raster, and a set of distance rasters for each spatial range.
}
\usage{
Format_Spatial_Data(range_list,rdcoords,inc)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{range_list}{a list of sf dataframes per seasonal range}
  \item{rdcoords}{a matrix of xy coordinates}
  \item{inc}{an integer, the spatial resolution for the simulation in meters}
}
\value{
A named list containing the following:
\item{range_list}{List, user-input range_list}
\item{dist_r_sprc}{SpatRasterCollection of rasters with values indicating the distance from each cell to the centroid of each polygon in the range_list seasonal ranges. Each distance raster corresponds to a seasonal range.}
\item{grid_list}{List of objects needed for movement algorithm}
\item{r}{SpatRaster with input resolution (inc). Extent and CRS are drawn from input spatial ranges}
\item{rdcoords}{matrix, user-input start and end road coordinates}
\item{inc}{integer, user-input grid resolution}
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
