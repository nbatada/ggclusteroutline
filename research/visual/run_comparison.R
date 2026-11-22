#!/usr/bin/env Rscript
# M0 research-only benchmark. It does not provide package functions.

options(warn = 1)
stopifnot(requireNamespace("ggplot2", quietly = TRUE))
stopifnot(requireNamespace("ggforce", quietly = TRUE))
stopifnot(requireNamespace("ggdensity", quietly = TRUE))
stopifnot(requireNamespace("ggalt", quietly = TRUE))

library(ggplot2)
library(ggforce)
library(ggdensity)
library(ggalt)

out_dir <- "research/visual/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
input_dir <- "research/visual/input"
dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20261122)
PANEL_LIMITS <- c(-4, 4)

make_ring <- function(n = 180) {
  angle <- runif(n, 0, 2 * pi)
  radius <- rnorm(n, 1, 0.055)
  data.frame(x = radius * cos(angle), y = radius * sin(angle), group = "ring")
}

make_islands <- function(n = 100) {
  data.frame(
    x = c(rnorm(n, -1.8, .20), rnorm(n, 1.8, .20)),
    y = c(rnorm(n, 0, .22), rnorm(n, 0, .22)),
    group = "islands"
  )
}

make_crescent <- function(n = 180) {
  angle <- runif(n, 0.15 * pi, 1.85 * pi)
  radius <- rnorm(n, 1, .075)
  data.frame(x = radius * cos(angle), y = radius * sin(angle), group = "crescent")
}

make_competing_data <- function(kind) {
  primary <- switch(kind, ring = make_ring(), islands = make_islands(), crescent = make_crescent())
  other <- data.frame(x = rnorm(75, 0, .30), y = rnorm(75, -1.7, .26), group = "other")
  rbind(primary, other)
}

convex_outline <- function(data) {
  indices <- grDevices::chull(data$x, data$y)
  data[indices, , drop = FALSE]
}

base_plot <- function(data, title) {
  ggplot(data, aes(x, y)) +
    geom_point(aes(colour = group), alpha = .50, size = .8, show.legend = FALSE) +
    scale_colour_manual(values = c(crescent = "#0072B2", islands = "#0072B2", other = "#999999", ring = "#0072B2")) +
    coord_equal(xlim = PANEL_LIMITS, ylim = PANEL_LIMITS, expand = FALSE) +
    theme_void(base_size = 9) +
    ggtitle(title) +
    theme(plot.title = element_text(hjust = .5, face = "bold", size = 10))
}

draw_methods <- function(kind, data = make_competing_data(kind)) {
  target <- subset(data, group != "other")
  convex <- convex_outline(target)
  common <- base_plot(data, sprintf("%s: points", kind))
  convex_plot <- common +
    geom_polygon(data = convex, aes(x, y), inherit.aes = FALSE, colour = "#D55E00", fill = NA, linewidth = .65)
  force_plot <- common +
    geom_mark_hull(data = target, aes(x, y), inherit.aes = FALSE,
                   expand = grid::unit(0, "mm"), radius = grid::unit(0, "mm"),
                   con.cap = grid::unit(0, "mm"), colour = "#D55E00", fill = NA, linewidth = .65,
                   label.colour = NA, label.fill = NA)
  encircle_plot <- common +
    geom_encircle(data = target, aes(x, y), inherit.aes = FALSE,
                  colour = "#D55E00", fill = NA, size = 1.85, expand = 0, spread = .03)
  density_plot <- common +
    geom_hdr_lines(data = target, aes(x, y), inherit.aes = FALSE, xlim = c(-4, 4), ylim = c(-4, 4),
                   probs = .95, colour = "#D55E00", alpha = 1, linewidth = .65)
  list(convex = convex_plot, ggforce = force_plot, ggalt = encircle_plot, ggdensity = density_plot)
}

save_plot <- function(plot, path) {
  ggsave(path, plot, width = 3.1, height = 3.0, units = "in", dpi = 180, bg = "white")
}

plot_records <- list()
case_data <- list()
plate_plots <- list()
for (kind in c("ring", "islands", "crescent")) {
  case_data[[kind]] <- make_competing_data(kind)
  write.csv(case_data[[kind]], file.path(input_dir, paste0(kind, ".csv")), row.names = FALSE)
  methods <- draw_methods(kind, case_data[[kind]])
  for (method in names(methods)) {
    plate_plots[[length(plate_plots) + 1L]] <- methods[[method]] + ggtitle(paste(kind, method))
    png_path <- file.path(out_dir, sprintf("%s_%s.png", kind, method))
    svg_path <- file.path(out_dir, sprintf("%s_%s.svg", kind, method))
    elapsed <- system.time(save_plot(methods[[method]], png_path))["elapsed"]
    save_plot(methods[[method]], svg_path)
    plot_records[[length(plot_records) + 1]] <- data.frame(case = kind, method = method, render_seconds = unname(elapsed))
  }
}
plate <- patchwork::wrap_plots(plate_plots, ncol = 4) +
  patchwork::plot_annotation(title = "Matched synthetic outline comparison")
ggsave(file.path(out_dir, "matched_plate_3x4.png"), plate, width = 12, height = 9, units = "in", dpi = 180, bg = "white")
ggsave(file.path(out_dir, "matched_plate_3x4.svg"), plate, width = 12, height = 9, units = "in", bg = "white")

measure_removal_stability <- function(kind, seed = 17) {
  set.seed(seed)
  full <- switch(kind, ring = make_ring(400), islands = make_islands(200), crescent = make_crescent(400))
  reduced <- full[sample.int(nrow(full), floor(.9 * nrow(full))), ]
  hull_area <- function(data) {
    polygon <- convex_outline(data)
    x <- c(polygon$x, polygon$x[1])
    y <- c(polygon$y, polygon$y[1])
    abs(sum(x[-1] * y[-length(y)] - y[-1] * x[-length(x)])) / 2
  }
  data.frame(case = kind, method = "convex_hull", full_area = hull_area(full), reduced_area = hull_area(reduced),
             area_ratio = hull_area(reduced) / hull_area(full), removal_fraction = .10)
}

timings <- do.call(rbind, plot_records)
stability <- do.call(rbind, lapply(c("ring", "islands", "crescent"), measure_removal_stability))

point_in_polygon <- function(point, polygon, tolerance = 1e-10) {
  polygon <- as.matrix(polygon[, c("x", "y"), drop = FALSE])
  if (nrow(polygon) < 3L) return(FALSE)
  next_vertex <- c(2:nrow(polygon), 1L)
  x1 <- polygon[, 1]; y1 <- polygon[, 2]
  x2 <- polygon[next_vertex, 1]; y2 <- polygon[next_vertex, 2]
  cross <- (point[2] - y1) * (x2 - x1) - (point[1] - x1) * (y2 - y1)
  on_segment <- abs(cross) < tolerance &
    point[1] >= pmin(x1, x2) - tolerance & point[1] <= pmax(x1, x2) + tolerance &
    point[2] >= pmin(y1, y2) - tolerance & point[2] <= pmax(y1, y2) + tolerance
  if (any(on_segment)) return(TRUE)
  crossings <- (y1 > point[2]) != (y2 > point[2])
  x_cross <- (x2 - x1) * (point[2] - y1) / (y2 - y1) + x1
  sum(crossings & point[1] < x_cross) %% 2L == 1L
}

in_even_odd_paths <- function(point, paths) {
  sum(vapply(paths, point_in_polygon, logical(1), point = point)) %% 2L == 1L
}

ggforce_paths <- function(data) {
  path <- ggforce:::concaveman(as.matrix(data[, c("x", "y")]), concavity = 2, threshold = 0)
  list(data.frame(x = path[, 1], y = path[, 2]))
}

hdr_paths <- function(data) {
  plot <- ggplot(data, aes(x, y)) +
    coord_equal(xlim = PANEL_LIMITS, ylim = PANEL_LIMITS, expand = FALSE) +
    geom_hdr_lines(probs = .95, alpha = 1, xlim = c(-4, 4), ylim = c(-4, 4))
  built <- ggplot_build(plot)$data[[1]]
  if (nrow(built) == 0L) return(list())
  lapply(split(built, built$group), function(path) path[, c("x", "y"), drop = FALSE])
}

paths_are_closed <- function(paths, tolerance = 1e-6) {
  length(paths) > 0L && all(vapply(paths, function(path) {
    nrow(path) >= 3L && sqrt((path$x[1] - path$x[nrow(path)])^2 + (path$y[1] - path$y[nrow(path)])^2) <= tolerance
  }, logical(1)))
}

capture_paths <- function(method, data) {
  warnings <- character()
  result <- tryCatch(withCallingHandlers(
    switch(method,
      convex = list(convex_outline(data)),
      ggforce = ggforce_paths(data),
      ggdensity = hdr_paths(data)
    ), warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }), error = function(error) error)
  if (inherits(result, "error")) return(list(paths = list(), warning = paste(warnings, collapse = " | "), error = conditionMessage(result)))
  list(paths = result, warning = paste(warnings, collapse = " | "), error = "")
}

metric_records <- list()
for (case in c("ring", "islands")) {
  target_full <- subset(case_data[[case]], group != "other")
  set.seed(if (case == "ring") 20261123 else 20261124)
  target_reduced <- target_full[sample.int(nrow(target_full), floor(.9 * nrow(target_full))), ]
  probe <- if (case == "ring") c(0, 0) else c(0, 0)
  probe_name <- if (case == "ring") "annulus_center" else "island_midpoint"
  for (sample_name in c("full", "removed_10pct")) {
    target <- if (sample_name == "full") target_full else target_reduced
    for (method in c("convex", "ggforce", "ggdensity")) {
      captured <- capture_paths(method, target)
      closed <- if (method == "ggdensity") paths_are_closed(captured$paths) else length(captured$paths) > 0L
      coverage <- if (closed) mean(vapply(seq_len(nrow(target)), function(row) {
        in_even_odd_paths(unlist(target[row, c("x", "y")]), captured$paths)
      }, logical(1))) else NA_real_
      metric_records[[length(metric_records) + 1L]] <- data.frame(
        case = case, sample = sample_name, method = method, probe = probe_name,
        probe_inside = if (closed) in_even_odd_paths(probe, captured$paths) else NA,
        observed_point_coverage = coverage, path_count = length(captured$paths),
        closed_paths = closed, warning = captured$warning, error = captured$error
      )
    }
  }
}
metrics <- do.call(rbind, metric_records)

degenerate_data <- list(
  one_point = data.frame(x = 0, y = 0),
  two_points_oblique = data.frame(x = c(0, 1), y = c(0, .73)),
  three_points = data.frame(x = c(0, 1, .25), y = c(0, .15, 1)),
  collinear = data.frame(x = 0:4, y = 0),
  duplicates = data.frame(x = rep(0, 4), y = rep(0, 4)),
  mixed_na = data.frame(x = c(0, 1, NA), y = c(0, .2, 1)),
  mixed_inf = data.frame(x = c(0, 1, Inf), y = c(0, .2, 1))
)
try_render <- function(method, data) {
  warnings <- character()
  plot <- tryCatch({
    plot <- ggplot(data, aes(x, y)) + geom_point() + coord_equal()
    switch(method,
    ggforce = plot + geom_mark_hull(aes(label = "x"), expand = grid::unit(0, "mm"),
                                    radius = grid::unit(0, "mm"), con.cap = grid::unit(0, "mm"), label.colour = NA),
    ggalt = plot + geom_encircle(expand = 0, spread = .03),
    ggdensity = plot + geom_hdr_lines(probs = .95),
    convex = plot + geom_polygon(data = convex_outline(data), aes(x, y), inherit.aes = FALSE, fill = NA)
  )}, error = function(error) error)
  if (inherits(plot, "error")) return(c(status = "error", warning = "", error = conditionMessage(plot), empty_output = NA))
  built <- tryCatch(withCallingHandlers(ggplot_build(plot), warning = function(warning) {
    warnings <<- c(warnings, conditionMessage(warning)); invokeRestart("muffleWarning")
  }), error = function(error) error)
  if (inherits(built, "error")) return(c(status = "error", warning = paste(warnings, collapse = " | "), error = conditionMessage(built), empty_output = NA))
  saved <- tryCatch(withCallingHandlers(ggsave(tempfile(fileext = ".png"), plot, width = 2, height = 2, units = "in"), warning = function(warning) {
    warnings <<- c(warnings, conditionMessage(warning)); invokeRestart("muffleWarning")
  }), error = function(error) error)
  if (inherits(saved, "error")) return(c(status = "error", warning = paste(unique(warnings), collapse = " | "), error = conditionMessage(saved), empty_output = NA))
  layer_data <- built$data[[length(built$data)]]
  empty <- if (method == "ggdensity") as.character(nrow(layer_data) == 0L) else "unknown"
  c(status = "rendered", warning = paste(unique(warnings), collapse = " | "), error = "", empty_output = empty)
}
degenerate <- do.call(rbind, lapply(names(degenerate_data), function(case) {
  result <- lapply(c("convex", "ggforce", "ggalt", "ggdensity"), try_render, data = degenerate_data[[case]])
  data.frame(case = case, method = c("convex", "ggforce", "ggalt", "ggdensity"),
             do.call(rbind, result), row.names = NULL)
}))
write.csv(timings, file.path(out_dir, "render_timings.csv"), row.names = FALSE)
write.csv(stability, file.path(out_dir, "convex_removal_stability.csv"), row.names = FALSE)
write.csv(metrics, file.path(out_dir, "region_metrics.csv"), row.names = FALSE)
write.csv(degenerate, file.path(out_dir, "degenerate_render_results.csv"), row.names = FALSE)
write.csv(data.frame(
  package = c("R", "ggplot2", "ggforce", "ggalt", "ggdensity"),
  version = c(R.version.string, as.character(packageVersion("ggplot2")), as.character(packageVersion("ggforce")), as.character(packageVersion("ggalt")), as.character(packageVersion("ggdensity")))
), file.path(out_dir, "versions.csv"), row.names = FALSE)

cat("Rendered", nrow(timings), "controlled figures to", out_dir, "\n")
