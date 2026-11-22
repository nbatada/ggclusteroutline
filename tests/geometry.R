library(ggclusteroutline)
engine <- getFromNamespace("outline_geometry", "ggclusteroutline")
membership <- getFromNamespace(".outline_membership", "ggclusteroutline")
even_odd_membership <- getFromNamespace(".outline_even_odd_membership", "ggclusteroutline")

expect_error <- function(expression) {
  failed <- inherits(try(force(expression), silent = TRUE), "try-error")
  stopifnot(failed)
}

square <- list(x = c(-1, 1, 1, -1, -1), y = c(-1, -1, 1, 1, -1))
hole <- list(x = c(-.25, .25, .25, -.25, -.25), y = c(-.25, -.25, .25, .25, -.25))
annulus_membership <- membership(c(0, .75), c(0, 0), list(square, hole))
stopifnot(identical(rowSums(annulus_membership) %% 2L == 1L, c(FALSE, TRUE)))
stopifnot(identical(even_odd_membership(c(0, .75), c(0, 0), list(square, hole)), c(FALSE, TRUE)))

points <- data.frame(
  x = c(0, 1, 0, 4, 5, 4, 9, 9),
  y = c(0, 0, 1, 0, 0, 1, 9, 10),
  group = c(rep("a", 3), rep("b", 3), rep("tiny", 2)),
  stringsAsFactors = FALSE
)
tight <- engine(points$x, points$y, points$group, c("tiny"), method = "tight", grid_size = 80L)
stopifnot(identical(unique(tight$type), "segment"), nrow(attr(tight, "diagnostics")) == 1L)
expect_error(engine(points$x, points$y, points$group, c("missing"), method = "tight"))
expect_error(engine(c(0, NA), c(0, 1), c("a", "a"), "a", method = "tight"))
constant_territory <- engine(c(0, 0), c(0, 0), c("same", "same"), "same", method = "territory")
constant_diagnostics <- attr(constant_territory, "diagnostics")
stopifnot(!nrow(constant_territory), identical(constant_diagnostics$status, "no_territory"),
          constant_diagnostics$other_points == 0L)

# Segment endpoints must span the dominant (here vertical) coordinate.
near_vertical <- data.frame(x = c(0, 1e-16, 2e-16), y = c(0, 1, .5), g = "A")
contains_segment <- function(path, x, y, tolerance = 1e-12) {
  dx <- path$x[2L] - path$x[1L]
  dy <- path$y[2L] - path$y[1L]
  length_squared <- dx^2 + dy^2
  parameter <- ((x - path$x[1L]) * dx + (y - path$y[1L]) * dy) / length_squared
  distance <- abs((x - path$x[1L]) * dy - (y - path$y[1L]) * dx) / sqrt(length_squared)
  parameter >= -tolerance & parameter <= 1 + tolerance & distance <= tolerance
}
for (method in c("tight", "islands")) {
  band <- compute_cluster_outlines(near_vertical, "x", "y", "g", method = method,
                                   bandwidth = 2, cache = FALSE)
  diagnostics <- attr(band, "diagnostics")
  stopifnot(identical(band$type, c("segment", "segment")),
            all(contains_segment(band, near_vertical$x, near_vertical$y)),
            diagnostics$assigned_points == nrow(near_vertical), diagnostics$unresolved_points == 0L)
}

fixture <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
pbmc <- engine(fixture$x, fixture$y, fixture$leiden, "4", method = "territory", mass = .9, grid_size = 160L)
diagnostics <- attr(pbmc, "diagnostics")
stopifnot(identical(diagnostics$status, "ok"), diagnostics$paths == 2L, diagnostics$assigned_points == 48L)
stopifnot(all(pbmc$type == "polygon"), length(unique(pbmc$path)) == 2L)
tight_pbmc <- engine(fixture$x, fixture$y, fixture$leiden, "4", method = "tight", mass = .9, grid_size = 160L)
tight_diagnostics <- attr(tight_pbmc, "diagnostics")
stopifnot(identical(tight_diagnostics$status, "ok"), tight_diagnostics$paths == 2L,
          tight_diagnostics$assigned_points == 48L, tight_diagnostics$unresolved_points == 0L)
polygon_area <- function(path) {
  next_vertex <- c(2:nrow(path), 1L)
  abs(sum(path$x * path$y[next_vertex] - path$y * path$x[next_vertex])) / 2
}
stopifnot(isTRUE(all.equal(sum(vapply(split(tight_pbmc, tight_pbmc$path), polygon_area, numeric(1))), 1.578884, tolerance = 1e-6)))

cat("geometry tests passed\n")

# Concentric rings have coincident centroids; parent/child comes from nesting.
rings <- do.call(rbind,lapply(1:2,function(i) {
  q <- if(i==1L) square else hole
  data.frame(cluster="A",path=i,x=q$x,y=q$y,type="polygon")
}))
metadata <- getFromNamespace(".outline_ring_metadata","ggclusteroutline")(rings)
stopifnot(identical(metadata$cluster,c("A","A")),identical(metadata$hole,c(FALSE,TRUE)),
          identical(metadata$component,c(1L,1L)))
small <- data.frame(x=c(-1,0,1,-1,0,1),y=c(0,1,0,.2,1.2,.2))
fragments <- engine(small$x,small$y,rep("A",6),"A",method="tight")
stopifnot(!nrow(fragments),attr(fragments,"diagnostics")$status=="insufficient_island_support")
# Absolute coordinate units alone must not collapse a valid triangle.
triangle <- data.frame(x=c(0,1e-12,0),y=c(0,0,1e-12),id="A",island="a")
triangle_hull <- compute_cluster_outlines(triangle,"x","y","id",component="island")
stopifnot(all(triangle_hull$type=="polygon"),nrow(triangle_hull)==4L)
