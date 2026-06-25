\name{calving23}
\alias{calving23}
\docType{data}
\title{
Western Arctic Herd calving23 Seasonal Range
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
A geopackage containing seasonal calving range in 2023 from 50 percent utilization distributions in sf format, projected to NAD83/Alaska Albers. Each row is a POLYGON object. 
}
\usage{}
\format{
  An sf data frame
  \describe{
    \item{\code{ID}}{ID number}
    \item{\code{Contour}}{utilization distribution percentage}
    \item{\code{Shape_Length}}{length of all calving23 polygons}
    \item{\code{Shape_Area}}{area of all calving23 polygons}
    \item{\code{geometry}}{sf format coordinate information}
  }
}
\details{
%%  ~~ If necessary, more details than the __description__ above ~~
}
\source{
%%  ~~ reference to a publication or URL from which the data were obtained ~~
}
\references{
%%  ~~ possibly secondary sources and usages ~~
Seasonal range derived from:
Joly K. 2026. Western Arctic Herd caribou annual and seasonal range distributions. National Park Service
https://irma.nps.gov/DataStore/Reference/Profile/2318272
}
\examples{
calving23<-st_read(system.file("inst/wah_range_list.gpkg",layer="calving23",package="crossR"))
}
\keyword{datasets}
