% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/details.R
\name{.details}
\alias{.details}
\title{Single Entity Details}
\usage{
.details(
  uuid = character(),
  catalog = NULL,
  view = c("projects", "files", "samples", "bundles")
)
}
\arguments{
\item{uuid}{character() unique *_id}

\item{catalog}{character(1) source of data. Use \code{catalogs()}
for possible values.}

\item{view}{character() type of entity i.e. project, file, sample, or bundle}
}
\value{
list-of-lists containing relevant details about the project, file,
sample, or bundle
}
\description{
Single Entity Details
}
