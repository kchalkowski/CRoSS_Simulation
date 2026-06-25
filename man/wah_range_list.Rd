\name{WAH Seasonal Ranges}
\alias{Range List}
\docType{data}
\title{
Western Arctic Herd Seasonal Range List
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
List of consecutive seasonal ranges (winter 2022-2023 to calving 2023) from 50 percent utilization distributions. Can be used as sample input data for Format_Spatial_Ranges. Each item in the list comprises a single seasonal range in sf format, projected to NAD83/Alaska Albers. For each sf data frame, each row indicates a part of the seasonal range in POLYGON format. 
}
\usage{data("wah_range_list")}
\format{
  A list with two items
  \describe{
    \item{\code{winter_22_23}}{an sf data frame}
    \item{\code{calving23}}{an sf data frame}
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
}
\examples{
rdcoords=data(wah_rdcoords)
range_list=data(wah_range_list)
Format_Spatial_Ranges(range_list,rdcoords)
}
\keyword{datasets}
