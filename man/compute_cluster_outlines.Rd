\name{compute_cluster_outlines}
\alias{compute_cluster_outlines}
\alias{clear_outline_cache}
\title{Compute and reuse cluster outlines in embedding coordinates}
\description{Compute ordered data-space paths for supplied labels or clear the session-local cache.}
\usage{
compute_cluster_outlines(data, x, y, group, clusters = NULL,
  method = c("tight", "territory", "islands"), bandwidth = NULL, mass = .9,
  grid_size = 160L, cache = TRUE, component = NULL, facets = NULL)

clear_outline_cache()
}
\arguments{
\item{data}{A data frame containing the whole embedding for one panel.}
\item{x,y}{Names of columns containing finite numeric coordinates.}
\item{group}{Name of the supplied cluster ID column.}
\item{clusters}{Optional vector of observed IDs to draw. All eligible groups
compete even when selecting a single ID.}
\item{method}{\code{"tight"} fits convex bands to supported islands of assigned cells.
\code{"territory"} contours locally dominant density regions. \code{"islands"} encloses connected occupied tiles within each supplied label.}
\item{bandwidth}{Positive Gaussian bandwidth in embedding units. The default
is 0.035 times the longer panel span. In islands mode this sets tile width, with a minimum of the longer span divided by grid_size.}
\item{mass}{Fraction of a group's smoothed grid mass used to choose its support
threshold, strictly between zero and one.}
\item{grid_size}{Integer from 32 to 512 giving nodes per grid axis.}
\item{component}{Optional column of supplied spatial component IDs for tight mode. Each component gets its own all-member hull.}
\item{facets}{Optional character vector of complete facet-key columns. Compute each panel independently and retain its original keys in frozen geometry.}
\item{cache}{Use the bounded session-local geometry cache. Row reordering can cause
a cache miss.}
}
\details{
On a common padded grid, labelled cell counts are smoothed independently.
Each node is awarded to the highest absolute group density, with deterministic
ties. Territory boundaries trace a smoothed, inset mask within each winner's
mass support. More abundant neighbours can suppress a small population.
A territory can omit members, enclose other labels or be absent.
Neither method changes cell assignments. Tight hulls can enclose cells of other
groups. Unresolved geometry is reported through diagnostics.
The default grid and bandwidth are starting values. Inspect the full map.
}
\value{
A data frame inheriting from \code{cluster_outlines}, containing original cluster
keys as character, path identifiers, ordered \code{x} and \code{y} coordinates
and geometry \code{type}. See \code{attr(result, "diagnostics")} for per-group
status. A frozen table can be stored using \code{saveRDS()} and drawn using
\code{geom_cluster_outline(data = result)}. \code{clear_outline_cache()} clears
the process-local cache and invisibly returns NULL.
}
\examples{
d <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
p <- compute_cluster_outlines(d, "x", "y", "leiden", clusters = 4)
attr(p, "diagnostics")
clear_outline_cache()
}
\seealso{\link{geom_cluster_outline}}
