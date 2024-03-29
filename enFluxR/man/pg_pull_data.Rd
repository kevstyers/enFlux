% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pg_pull_data.R
\name{pg_pull_data}
\alias{pg_pull_data}
\title{Grab EC data from pg}
\usage{
pg_pull_data(site = NULL, start_date = NULL, end_date = NULL, verbose = TRUE)
}
\arguments{
\item{site}{character, 4 letter site code}

\item{start_date}{character/date, yyyy-mm-dd, start date to pull}

\item{end_date}{character/date, yyyy-mm-dd, end date to pull}

\item{verbose}{logical, TRUE if you want your query back}
}
\value{
NA
}
\description{
This pulls EC data using the parameters user specifies to generate a SQL query that collects data from the PG server
}
