\name{assess_territories}
\alias{assess_territories}
\title{Measure territory agreement with the supplied cluster assignments}
\description{Count cell centres in saved territory polygons and flag cells inside a different group's territory.}
\usage{assess_territories(data, territories)}
\arguments{
\item{data}{Original data frame used for precomputation, in the same row order.}
\item{territories}{Result of \code{compute_cluster_outlines()} with the territory method.}
}
\value{A list with \code{summary} (one row per requested group and panel) and
\code{cells} (one row per input observation, retaining row names and original cluster values).
Purity is the percentage of enclosed centres assigned to the territory's group.
Coverage is the percentage of the group's centres enclosed. Empty territories
have undefined purity and zero coverage. \code{territory_cluster} is the sole
containing territory, or NA for zero or multiple hits. \code{n_territories}
distinguishes those cases. \code{in_other_territory} is TRUE if any containing
territory belongs to another group. Only supplied territories are assessed.}
\details{Facets are assessed independently. These descriptive percentages concern the
chosen two-dimensional overlay. All original assignments are preserved.}
\examples{
d <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
regions <- compute_cluster_outlines(d, "x", "y", "leiden")
agreement <- assess_territories(d, regions)
agreement$summary[c("cluster", "purity_pct", "coverage_pct")]
}
