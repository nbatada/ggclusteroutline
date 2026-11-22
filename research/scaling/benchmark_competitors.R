#!/usr/bin/env Rscript

# M0 research artifact. ggforce resolves hull geometry during grid drawing,
# while ggdensity resolves its statistic during ggplot_build(). The three
# timings intentionally preserve that difference.

library(ggplot2)
library(ggforce)
library(ggdensity)
options(device = function(...) grDevices::pdf(NULL))
out_dir <- "research/scaling/results"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20261122)

design <- data.frame(
  method = c(rep("ggforce::geom_mark_hull", 4L), rep("ggdensity::geom_hdr_lines", 3L)),
  n = c(10000L, 10000L, 100000L, 100000L, 10000L, 10000L, 100000L),
  groups = c(1L, 10L, 1L, 100L, 1L, 10L, 100L)
)
arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) == 3L && arguments[[1L]] == "--case") {
  fields <- strsplit(arguments[[2L]], ",", fixed = TRUE)[[1L]]
  design <- data.frame(method = fields[[1L]], n = as.integer(fields[[2L]]), groups = as.integer(fields[[3L]]))
  repetitions <- as.integer(arguments[[3L]])
} else if (length(arguments) == 0L) {
  repetitions <- 3L
} else {
  stop("use --case METHOD,N,K REPETITIONS")
}

make_points <- function(n, groups) {
  set.seed(20261122L + n + groups)
  group <- rep(seq_len(groups), length.out = n)
  columns <- ceiling(sqrt(groups))
  data.frame(
    x = rnorm(n, ((group - 1L) %% columns) * 4, 0.7),
    y = rnorm(n, ((group - 1L) %/% columns) * 4, 0.7),
    group = factor(group)
  )
}

elapsed <- function(expression) {
  started <- proc.time()[["elapsed"]]
  value <- force(expression)
  list(value = value, seconds = proc.time()[["elapsed"]] - started)
}

draw_png <- function(grob) {
  temporary <- tempfile(fileext = ".png")
  ragg::agg_png(temporary, width = 960, height = 800, units = "px", res = 160)
  on.exit({ grDevices::dev.off(); unlink(temporary) }, add = TRUE)
  grid::grid.newpage()
  grid::grid.draw(grob)
}

export_complexity <- function(grob) {
  temporary <- tempfile(fileext = ".svg")
  svglite::svglite(temporary, width = 6, height = 5)
  grid::grid.newpage()
  grid::grid.draw(grob)
  grDevices::dev.off()
  xml <- paste(readLines(temporary, warn = FALSE), collapse = "\n")
  unlink(temporary)
  outline_tags <- regmatches(
    xml,
    gregexpr("<(path|polyline|polygon)[^>]*stroke: #C23B22[^>]*>", xml, perl = TRUE)
  )[[1L]]
  point_tags <- outline_tags[grepl("<(polyline|polygon)\\b", outline_tags)]
  vertices <- sum(vapply(point_tags, function(tag) {
    points <- sub(".*points='([^']*)'.*", "\\1", tag)
    length(strsplit(trimws(points), "[[:space:]]+")[[1L]])
  }, integer(1L)))
  c(outline_svg_path_like_elements = length(outline_tags), outline_svg_vertices = vertices)
}

one_run <- function(method, n, groups, repetition) {
  points <- make_points(n, groups)
  layer <- if (method == "ggforce::geom_mark_hull") {
    geom_mark_hull(aes(group = group), colour = "#C23B22", expand = grid::unit(0, "mm"), radius = grid::unit(0, "mm"), label.buffer = grid::unit(0, "mm"))
  } else if (method == "ggdensity::geom_hdr_lines") {
    geom_hdr_lines(aes(group = group), probs = 0.95, colour = "#C23B22")
  } else {
    stop("unknown method: ", method)
  }
  plot <- ggplot(points, aes(x, y)) +
    geom_point(size = 0.08, alpha = 0.35) + layer + coord_equal() + theme_void()
  build <- elapsed(ggplot_build(plot))
  gtable <- elapsed(ggplot_gtable(build$value))
  draw <- elapsed(draw_png(gtable$value))
  complexity <- export_complexity(gtable$value)
  data.frame(
    method = method, n = n, groups = groups, repetition = repetition,
    build_seconds = build$seconds, gtable_seconds = gtable$seconds,
    draw_seconds = draw$seconds,
    total_seconds = build$seconds + gtable$seconds + draw$seconds,
    outline_svg_path_like_elements = complexity[["outline_svg_path_like_elements"]],
    outline_svg_vertices = complexity[["outline_svg_vertices"]], stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, lapply(seq_len(nrow(design)), function(index) {
  item <- design[index, ]
  do.call(rbind, lapply(seq_len(repetitions), function(repetition) {
    one_run(item$method, item$n, item$groups, repetition)
  }))
}))

if (length(arguments) == 0L) {
  write.csv(results, file.path(out_dir, "competitor_measurements.csv"), row.names = FALSE)
  writeLines(trimws(capture.output(sessionInfo()), which = "right"), file.path(out_dir, "competitor_sessionInfo.txt"))
}
