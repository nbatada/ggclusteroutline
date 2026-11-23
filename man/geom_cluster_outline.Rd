\name{geom_cluster_outline}
\alias{geom_cluster_outline}
\title{Draw cluster outlines on a two-dimensional ggplot}
\description{Overlay computed or frozen paths on a scatterplot with supplied cluster assignments.}
\usage{
geom_cluster_outline(mapping = NULL, data = NULL, clusters = NULL,
  method = c("territory", "tight", "islands"), bandwidth = NULL, mass = 0.9,
  grid_size = 160L, cache = TRUE, ..., colour = "#C23B22", linewidth = 0.5,
  linetype = 1, alpha = NA, size = 1.5, shape = 16, stroke = 0.5,
  na.rm = FALSE, show.legend = NA,
  inherit.aes = TRUE, replicate = FALSE, label = FALSE)
}
\arguments{
\item{mapping}{Aesthetic mapping. Supply \code{aes(group = cluster_id)} with
the original ID column.}
\item{data}{Full embedding table, or a result from \code{compute_cluster_outlines()}.
The point layer may map gene expression to colour.}
\item{clusters}{Optional original cluster IDs. Default draws all eligible groups.}
\item{method,bandwidth,mass,grid_size,cache}{Geometry controls documented in
\code{\link{compute_cluster_outlines}}.}
\item{label}{Use \code{TRUE} for outlines with labels or \code{"only"} for labels alone. Draw one boxed cluster ID per panel for each selected territory
with a member cell strictly inside it. Use live cell data or territory paths computed with \code{label = TRUE}. Defaults to \code{FALSE}.}
\item{replicate}{Allow a separately supplied data table without all facet-key
columns to repeat in every facet. Defaults to \code{FALSE}; otherwise, a
faceted plot requires the complete facet keys in that table.}
\item{...}{Fixed line aesthetics, such as \code{colour}, \code{linewidth}
or \code{linetype}.}
\item{colour,linewidth,linetype,alpha}{Fixed stroke colour, line width, line type and transparency.}
\item{size,shape,stroke}{Point marker settings for a degenerate one-position group.}
\item{na.rm}{Missing-value handling for the layer.}
\item{show.legend}{Whether to include the outline layer in a legend.}
\item{inherit.aes}{Whether to inherit available positioning and grouping
aesthetics.}
}
\value{An object that adds the outline layer to a ggplot.}
\details{Supply full-panel coordinates and group labels for competition. Use
\code{clusters} to select the displayed paths. The point data and its aesthetic
mappings remain available to ggplot. An independent layer data table must
contain every facet-key column unless \code{replicate = TRUE} is intentional.
The default method draws locally dominant territories. Use linear Cartesian axes.}
\examples{
library(ggplot2)
d <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
ggplot(d, aes(x, y)) +
  geom_point(aes(colour = NKG7), size = 0.6) +
  geom_cluster_outline(aes(group = leiden), clusters = "4") +
  coord_equal()
}
