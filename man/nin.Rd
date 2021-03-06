% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{\%nin\%}
\alias{\%nin\%}
\title{\verb{\%nin\%}}
\usage{
x \%nin\% y
}
\arguments{
\item{x}{vector of items}

\item{y}{vector of all values}
}
\value{
logical vector of items in x not in y
}
\description{
Convenience 'not-in' operator
}
\details{
Complement of the built-in operator \code{\%in\%}. Returns the elements of \code{x} that are not in \code{y}.
}
\examples{
fruit <- c("apples", "oranges", "banana")
"apples" \%nin\% fruit
"pears" \%nin\% fruit
}
\author{
Kieran Healy
}
