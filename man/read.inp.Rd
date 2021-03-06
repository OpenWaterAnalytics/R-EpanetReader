% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/epanet.inp-s3.r
\name{read.inp}
\alias{epanet.inp}
\alias{read.inp}
\title{Read .inp file}
\usage{
read.inp(inpFile)
}
\arguments{
\item{inpFile}{path to the .inp file to read}
}
\value{
Returns an epanet.inp s3 object which is a list with
the following elements:
\item{Title}{character}
\item{Junctions}{data.frame}
\item{Tanks}{data.frame}
}
\description{
Read an Epanet .inp file into R
}
\details{
This function reads a text file in Epanet's .inp format
and returns an S3 object which is a list with entries for
sections of the .inp file.  Sections of the .inp file which are implemented
appear in the Value section.

ID fields are read "as is" and stored as characters not factors.

Sections which are absent from the .inp file are NULL in the list.

Columns of data.frames use the headings exported by
the Epanet GUI.

The [OPTIONS] section in the .inp file is used to update
         a list of Epanet's default options. In this way if an option such as
         units is not specified by the .inp file, the units that would be used by
         default are provided.

In the [PATTERNS] and [CURVES] sections, integers used as names of list elements are backquoted
         according to the default behavior in R.  So if the .inp file has a pattern "1"
         this pattern will appear as element `1` in the list that is returned. A warning is issued in this case.
}
\examples{
# path to Net1.inp example file included with this package
inp <- file.path( find.package("epanetReader"), "extdata","Net1.inp")
n1 <- read.inp(inp)
summary(n1)
names(n1)
summary(n1$Junctions)
summary(n1$Pipes)
plot(n1)
}
\references{
Rossman, L. A. (2000). Epanet 2 users manual. US EPA, Cincinnati, Ohio.

http://nepis.epa.gov/Adobe/PDF/P1007WWU.pdf
}

