#!/usr/bin/env Rscript

# M0 research artifact. It measures an explicit convex-hull reference, not a
# candidate package implementation. Results are hardware and device specific.

suppressPackageStartupMessages(library(ggplot2))
options(device = function(...) grDevices::pdf(NULL))

out_dir <- "research/scaling/results"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20261122)

sizes <- data.frame(
  n = c(10000L, 10000L, 100000L, 100000L, 1000000L, 1000000L),
  groups = c(1L, 100L, 1L, 100L, 1L, 1000L)
)
repetitions <- 3L

make_points <- function(n, groups) {
  group <- rep(seq_len(groups), length.out = n)
  center_x <- ((group - 1L) %% ceiling(sqrt(groups))) * 4
  center_y <- ((group - 1L) %/% ceiling(sqrt(groups))) * 4
  data.frame(
    x = rnorm(n, center_x, 0.7),
    y = rnorm(n, center_y, 0.7),
    group = factor(group)
  )
}

convex_hulls <- function(points) {
  hulls <- lapply(split(points, points$group, drop = TRUE), function(group_points) {
    vertices <- group_points[chull(group_points$x, group_points$y), c("x", "y"), drop = FALSE]
    rbind(vertices, vertices[1L, , drop = FALSE])
  })
  do.call(rbind, Map(function(vertices, label) transform(vertices, group = label), hulls, names(hulls)))
}

elapsed <- function(expression) {
  started <- proc.time()[["elapsed"]]
  value <- force(expression)
  list(value = value, seconds = proc.time()[["elapsed"]] - started)
}

measure_one <- function(n, groups, repetition) {
  points <- make_points(n, groups)
  geometry <- elapsed(convex_hulls(points))
  plot <- ggplot(points, aes(x, y)) +
    geom_point(size = 0.08, alpha = 0.35) +
    geom_path(
      data = geometry$value,
      aes(x, y, group = group),
      inherit.aes = FALSE,
      linewidth = 0.25,
      colour = "#C23B22"
    ) +
    coord_equal() + theme_void()
  build <- elapsed(ggplot_build(plot))
  file <- tempfile(fileext = ".png")
  render <- elapsed(ggsave(file, plot, width = 6, height = 5, dpi = 160, device = ragg::agg_png))
  unlink(file)
  data.frame(
    method = "grDevices::chull plus ggplot2",
    n = n,
    groups = groups,
    repetition = repetition,
    geometry_seconds = geometry$seconds,
    build_seconds = build$seconds,
    render_seconds = render$seconds,
    polygon_vertices = nrow(geometry$value),
    render_device = "ragg::agg_png",
    stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, lapply(seq_len(nrow(sizes)), function(index) {
  design <- sizes[index, ]
  do.call(rbind, lapply(seq_len(repetitions), function(repetition) {
    measure_one(design$n, design$groups, repetition)
  }))
}))

write.csv(results, file.path(out_dir, "convex_reference_measurements.csv"), row.names = FALSE)
installed <- rownames(installed.packages())
versions <- data.frame(
  component = c("R", "ggplot2", "ragg", "ggforce", "ggalt", "ggdensity", "concaveman"),
  installed = c(
    R.version.string,
    as.character(packageVersion("ggplot2")),
    as.character(packageVersion("ragg")),
    "ggforce" %in% installed,
    "ggalt" %in% installed,
    "ggdensity" %in% installed,
    "concaveman" %in% installed
  ),
  stringsAsFactors = FALSE
)
write.csv(versions, file.path(out_dir, "environment.csv"), row.names = FALSE)
writeLines(trimws(capture.output(sessionInfo()), which = "right"), file.path(out_dir, "sessionInfo.txt"))
