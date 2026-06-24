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
  \item{range_list}{a list}
  \item{rdcoords}{a matrix of xy coordinates}
  \item{inc}{an integer, the spatial resolution for the simulation}
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
\item{grid_list}{list of grid objects}
\item{other outputs}{other stuff}
}
\references{
}
\author{
Kayleigh Chalkowski, kchalkowski@gmail.com
}
\note{
}

\seealso{
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or standard data sets, see data().

## The function is currently defined as
function (x) 
{
  }
}
