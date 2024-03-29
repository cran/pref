% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pref_data.R
\name{pref.data}
\alias{pref.data}
\title{put election data in an R file (.rda)}
\usage{
pref.data(
  datafile,
  mult = FALSE,
  details = TRUE,
  parties = FALSE,
  ballot = FALSE,
  friendly = FALSE,
  header = FALSE
)
}
\arguments{
\item{datafile}{File with election data}

\item{mult}{Whether includes aggregated votes (default FALSE)}

\item{details}{Whether full election detail (default) or just vote matrix}

\item{parties}{File with party details (default FALSE, i.e. omit)}

\item{ballot}{Default FALSE (meaning pref format)}

\item{friendly}{Default FALSE (meaning most details after votes)}

\item{header}{Whether a vote matrix has a header}
}
\value{
A standardised list of election info to save in a .rda file; for details see manual pref_pkg_manual.pdf (section 4)
}
\description{
put election data in an R file (.rda)
}
\examples{
datafile=system.file("extdata","yale.dat",package="pref")
yale=pref.data(datafile,details=FALSE)
datafile=system.file("extdata","Jedburgh2012.blt",package="pref")
parties12=system.file("extdata","parties_SC2012.txt",package="pref")
jed12=pref.data(datafile,mult=TRUE,parties=parties12)
datafile=system.file("extdata","jmt2002.blt",package="pref")
j02=pref.data(datafile,friendly=TRUE)
}
