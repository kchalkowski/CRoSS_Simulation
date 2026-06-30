\name{Set_Spatial_Movement}
\alias{Set_Spatial_Movement}
\title{
Set movement parameters
}
\description{
Creates a data frame that defines seasonal movement characteristics for the simulation.
}
\usage{
Set_Spatial_Movement(range_list,sl_shp,sl_rat,start,end)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
	\item{range_list}{List of sf objects, user input seasonal ranges}
  \item{sl_shp}{numeric vector, shape parameter of Gamma distribution fit to step lengths}
  \item{sl_rat}{numeric vector, rate parameter of Gamma distribution fit to step lengths}
  \item{start}{starting time step of each season}
  \item{end}{ending time step of each season}
}
\value{
A dataframe
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
