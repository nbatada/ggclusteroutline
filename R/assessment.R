# Compare each original observation to the saved polygons in its own panel.
assess_territories <- function(data, territories) {
  if (!inherits(territories, "cluster_outlines") ||
      !identical(attr(territories, "method"), "territory")) {
    stop("Supply territory paths from compute_cluster_outlines().", call. = FALSE)
  }
  origin <- attr(territories, "provenance")
  cols <- origin$columns
  if (!is.data.frame(data) || is.null(cols) ||
      !all(c(cols$x, cols$y, cols$group, cols$facets) %in% names(data))) {
    stop("Supply the original embedding table and its geometry columns.", call. = FALSE)
  }
  x <- data[[cols$x]]
  y <- data[[cols$y]]
  original <- data[[cols$group]]
  ids <- as.character(original)
  facets <- if (length(cols$facets)) data[cols$facets]
  fingerprint <- digest::digest(list(x, y, ids, NULL, as.list(facets)),
                                algo = "sha256", serializeVersion = 2L)
  if (!identical(fingerprint, origin$input_sha256)) {
    stop("Coordinates, IDs, facets or row order differ from the saved inputs.", call. = FALSE)
  }

  summary <- attr(territories, "diagnostics")
  matched <- rep(NA_character_, length(ids))
  hits <- integer(length(ids))
  other <- logical(length(ids))
  for (i in seq_len(nrow(summary))) {
    id <- summary$cluster[i]
    panel <- rep(TRUE, length(ids))
    paths <- territories$cluster == id
    for (key in cols$facets) {
      panel <- panel & facets[[key]] == summary[[key]][i]
      paths <- paths & territories[[key]] == summary[[key]][i]
    }
    rings <- territories[paths, , drop = FALSE]
    rings <- rings[order(rings$path, rings$vertex), , drop = FALSE]
    rows <- which(panel)
    inside <- .outline_even_odd_membership(x[rows], y[rows], split(rings, rings$path))
    rows <- rows[inside]
    different <- ids[rows] != id
    if (sum(!different) != summary$assigned_points[i] ||
        sum(different) != summary$other_points[i]) {
      stop("Path containment differs from the saved territory diagnostics.", call. = FALSE)
    }
    hits[rows] <- hits[rows] + 1L
    matched[rows] <- id
    other[rows] <- other[rows] | different
  }
  matched[hits > 1L] <- NA_character_
  enclosed <- summary$assigned_points + summary$other_points
  summary$purity_pct <- ifelse(enclosed > 0, 100 * summary$assigned_points / enclosed, NA_real_)
  summary$coverage_pct <- 100 * summary$assigned_points / summary$input_points
  cells <- data.frame(original_cluster = original, territory_cluster = matched,
                      n_territories = hits, in_other_territory = other,
                      row.names = rownames(data), stringsAsFactors = FALSE)
  list(summary = summary, cells = cells)
}
