# Territory geometry adapted from CellStyle, copyright 2026 CellStyle contributors.
# See inst/LICENSE-CellStyle for its MIT license.

.outline_blur <- function(values, offsets, kernel) {
  blur_margin <- function(input, margin) {
    result <- matrix(0, nrow(input), ncol(input))
    for (index in seq_along(offsets)) {
      offset <- offsets[index]
      if (margin == 1L) {
        source <- max(1L, 1L - offset):min(nrow(input), nrow(input) - offset)
        result[source + offset, ] <- result[source + offset, ] + kernel[index] * input[source, , drop = FALSE]
      } else {
        source <- max(1L, 1L - offset):min(ncol(input), ncol(input) - offset)
        result[, source + offset] <- result[, source + offset] + kernel[index] * input[, source, drop = FALSE]
      }
    }
    result
  }
  blur_margin(blur_margin(values, 1L), 2L)
}

.outline_closed <- function(path) {
  length(path$x) >= 4L && isTRUE(all.equal(path$x[1], path$x[length(path$x)], tolerance = 1e-10)) &&
    isTRUE(all.equal(path$y[1], path$y[length(path$y)], tolerance = 1e-10))
}

.outline_path_frame <- function(cluster, path, type, path_id) {
  data.frame(cluster = cluster, path = path_id, x = path$x, y = path$y, type = type,
             stringsAsFactors = FALSE)
}

.outline_degenerate <- function(cluster, coordinates, path_id) {
  unique_coordinates <- unique(coordinates)
  if (nrow(unique_coordinates) == 1L) {
    return(data.frame(cluster = cluster, path = path_id, x = unique_coordinates$x, y = unique_coordinates$y,
                      type = "point", stringsAsFactors = FALSE))
  }
  collinear <- function(points) {
    if (nrow(points) < 3L) return(TRUE)
    origin <- as.numeric(points[1L, ])
    delta <- sweep(as.matrix(points), 2L, origin, "-")
    scale <- max(abs(delta))
    if (!is.finite(scale)) stop("Coordinate range exceeds finite precision.",call.=FALSE)
    delta <- delta/scale
    anchor <- which.max(rowSums(delta^2))
    if (anchor == 1L) return(TRUE)
    cross <- delta[, 1L] * delta[anchor, 2L] - delta[, 2L] * delta[anchor, 1L]
    all(abs(cross) <= 100 * .Machine$double.eps)
  }
  if (nrow(unique_coordinates) == 2L || collinear(unique_coordinates)) {
    ordering <- order(unique_coordinates$x, unique_coordinates$y, method = "radix")
    ends <- unique_coordinates[ordering[c(1L, length(ordering))], , drop = FALSE]
    return(data.frame(cluster = cluster, path = path_id, x = ends$x, y = ends$y,
                      type = "segment", stringsAsFactors = FALSE))
  }
  NULL
}

.outline_membership <- function(x, y, paths) {
  if (!length(paths)) return(matrix(FALSE, nrow = length(x), ncol = 0L))
  memberships <- vapply(paths, function(path) {
    in_bounds <- x >= min(path$x) & x <= max(path$x) & y >= min(path$y) & y <= max(path$y)
    inside <- logical(length(x))
    if (any(in_bounds)) {
      inside[in_bounds] <- sp::point.in.polygon(x[in_bounds], y[in_bounds], path$x, path$y) > 0L
    }
    inside
  }, logical(length(x)))
  dim(memberships) <- c(length(x), length(paths))
  memberships
}

.outline_hull <- function(cluster, coordinates, path_id) {
  degenerate <- .outline_degenerate(cluster, coordinates, path_id)
  if (!is.null(degenerate)) return(degenerate)
  index <- grDevices::chull(coordinates$x, coordinates$y)
  hull <- coordinates[index, , drop = FALSE]
  hull <- rbind(hull, hull[1L, , drop = FALSE])
  data.frame(cluster = cluster, path = path_id, x = hull$x, y = hull$y,
             type = "polygon", stringsAsFactors = FALSE)
}

.outline_ring_metadata <- function(output, nested = TRUE) {
  polygons <- output[output$type == "polygon", , drop = FALSE]
  if (!nrow(polygons)) return(data.frame(cluster=character(), path=integer(), component=integer(), hole=logical()))
  records <- lapply(split(polygons, polygons$cluster), function(cluster_paths) {
    paths <- split(cluster_paths, cluster_paths$path)
    ids <- as.integer(names(paths))
    component <- ids
    hole <- rep(FALSE,length(ids))
    # Same-level contour lines are disjoint or nested. A vertex of the
    # child, unlike its centroid, cannot lie inside one of its own children.
    if (nested && length(paths) > 1L) {
      points <- do.call(rbind,lapply(paths,function(p) p[1L,c("x","y")]))
      parents <- .outline_membership(points$x,points$y,paths)
      diag(parents) <- FALSE
      depth <- rowSums(parents)
      hole <- depth %% 2L == 1L
      for (i in which(hole)) {
        outer <- which(parents[i,] & !hole)
        component[i] <- ids[outer[which.max(depth[outer])]]
      }
    }
    data.frame(cluster=cluster_paths$cluster[1L], path=ids, component=component, hole=hole)
  })
  do.call(rbind,records)
}

.outline_territory <- function(x, y, group_index, selected, bandwidth, mass, grid_size) {
  x_range <- range(x)
  y_range <- range(y)
  span <- max(diff(x_range), diff(y_range))
  if (!is.null(bandwidth) && (!is.numeric(bandwidth) || length(bandwidth) != 1L || !is.finite(bandwidth) || bandwidth <= 0))
    stop("bandwidth must be one positive finite number.", call. = FALSE)
  if (!is.finite(span) || span <= 0) {
    return(list(rings = setNames(vector("list", length(selected)), selected), open = setNames(integer(length(selected)), selected),
                valid = character(), bandwidth = bandwidth, grid_size = grid_size))
  }
  bandwidth <- if (is.null(bandwidth)) .035 * span else bandwidth
  midpoint <- c(mean(x_range), mean(y_range))
  width <- span + 8 * bandwidth
  nodes <- seq(-width / 2, width / 2, length.out = grid_size)
  grid_x <- midpoint[1] + nodes
  grid_y <- midpoint[2] + nodes
  step <- nodes[2L] - nodes[1L]
  if (!is.finite(step) || step <= 0 || any(diff(grid_x) <= 0) || any(diff(grid_y) <= 0))
    stop("Grid spacing is below coordinate precision. Centre or rescale the embedding.",call.=FALSE)
  radius <- ceiling(4 * bandwidth / step)
  offsets <- -radius:radius
  kernel <- exp(-.5 * (offsets * step / bandwidth)^2)
  kernel <- kernel / sum(kernel)
  selected_density <- list()
  thresholds <- numeric()
  valid <- character()
  winner <- matrix("", grid_size, grid_size)
  best <- matrix(-Inf, grid_size, grid_size)
  retain_selected <- length(selected) * grid_size^2 * 8 <= 32 * 1024^2
  density_for <- function(id) {
    rows <- group_index[[id]]
    coordinates <- data.frame(x = x[rows], y = y[rows])
    ix <- pmin(grid_size, pmax(1L, floor((coordinates$x - grid_x[1L]) / step + .5) + 1L))
    iy <- pmin(grid_size, pmax(1L, floor((coordinates$y - grid_y[1L]) / step + .5) + 1L))
    bins <- matrix(tabulate(ix + (iy - 1L) * grid_size, nbins = grid_size^2), nrow = grid_size, ncol = grid_size)
    .outline_blur(bins, offsets, kernel)
  }

  for (id in sort(names(group_index), method = "radix")) {
    rows <- group_index[[id]]
    coordinates <- data.frame(x = x[rows], y = y[rows])
    if (!is.null(.outline_degenerate(id, coordinates, 1L))) next
    density <- density_for(id)
    if (id %in% selected) {
      ordered <- sort(as.vector(density), decreasing = TRUE)
      thresholds[id] <- ordered[which(cumsum(ordered) >= mass * sum(ordered))[1L]]
    }
    valid <- c(valid, id)
    take <- density > best
    winner[take] <- id
    best[take] <- density[take]
    if (retain_selected && id %in% selected) selected_density[[id]] <- density
  }
  mask_offsets <- -3:3
  mask_kernel <- exp(-.5 * mask_offsets^2)
  mask_kernel <- mask_kernel / sum(mask_kernel)
  result <- setNames(vector("list", length(selected)), selected)
  open <- setNames(integer(length(selected)), selected)
  for (id in selected) {
    if (!id %in% valid) next
    density <- if (retain_selected) selected_density[[id]] else density_for(id)
    mask <- (winner == id) & density >= thresholds[[id]]
    rings <- grDevices::contourLines(grid_x, grid_y, .outline_blur(mask * 1, mask_offsets, mask_kernel), levels = .75)
    open[[id]] <- sum(!vapply(rings, .outline_closed, logical(1)))
    result[[id]] <- Filter(.outline_closed, rings)
  }
  list(rings = result, open = open, valid = valid, bandwidth = bandwidth, grid_size = grid_size)
}

#' Internal engine for precomputed cluster outlines.
#'
#' `tight` uses territory rings only to assign a selected label's observed cells
#' to spatial islands, then returns an all-member convex hull for each island.
#' Ambiguous or unmatched cells leave that cluster unresolved.
outline_geometry <- function(x, y, group, clusters, method = c("tight", "territory"), bandwidth = NULL, mass = .9, grid_size = 160L) {
  method <- match.arg(method)
  if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y) || length(x) != length(group))
    stop("x, y, and group must have equal length, with numeric x and y.", call. = FALSE)
  if (any(!is.finite(x)) || any(!is.finite(y)) || anyNA(group))
    stop("x and y must be finite and group must be identified.", call. = FALSE)
  if (!is.character(clusters) || !length(clusters) || anyNA(clusters) || anyDuplicated(clusters))
    stop("clusters must be a nonempty unique character vector.", call. = FALSE)
  if (!is.numeric(mass) || length(mass) != 1L || !is.finite(mass) || mass <= 0 || mass >= 1)
    stop("mass must be one number strictly between zero and one.", call. = FALSE)
  if (!is.numeric(grid_size) || length(grid_size) != 1L || !is.finite(grid_size) || grid_size != as.integer(grid_size) || grid_size < 32L)
    stop("grid_size must be an integer of at least 32.", call. = FALSE)
  groups <- as.character(group)
  group_index <- split(seq_along(groups), groups, drop = TRUE)
  missing_clusters <- setdiff(clusters, names(group_index))
  if (length(missing_clusters)) stop("clusters must be observed group IDs: ", paste(missing_clusters, collapse = ", "), call. = FALSE)

  if (method == "tight") {
    selected_coordinates <- lapply(clusters, function(id) data.frame(x = x[group_index[[id]]], y = y[group_index[[id]]]))
    if (all(vapply(selected_coordinates, function(coordinates) !is.null(.outline_degenerate("", coordinates, 1L)), logical(1)))) {
      rows <- Map(function(id, coordinates, path_id) .outline_degenerate(id, coordinates, path_id), clusters, selected_coordinates, seq_along(clusters))
      output <- do.call(rbind, rows)
      attr(output, "diagnostics") <- do.call(rbind, Map(function(id, coordinates) data.frame(cluster = id, status = "degenerate", input_points = nrow(coordinates), paths = 1L,
        assigned_points = nrow(coordinates), unresolved_points = 0L, open_paths = 0L, stringsAsFactors = FALSE), clusters, selected_coordinates))
      attr(output, "ring_metadata") <- .outline_ring_metadata(output, nested = method == "territory")
      attr(output, "settings") <- list(method = method, bandwidth = bandwidth, mass = mass, grid_size = as.integer(grid_size))
      return(output)
    }
  }

  territory <- .outline_territory(x, y, group_index, clusters, bandwidth, mass, as.integer(grid_size))
  rows <- list()
  diagnostics <- list()
  next_path <- 0L
  for (id in clusters) {
    coordinates <- data.frame(x = x[group_index[[id]]], y = y[group_index[[id]]])
    degenerate <- .outline_degenerate(id, coordinates, next_path + 1L)
    if (method == "tight" && !is.null(degenerate)) {
      next_path <- next_path + 1L
      rows[[length(rows) + 1L]] <- degenerate
      diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = "degenerate", input_points = nrow(coordinates), paths = 1L,
        assigned_points = nrow(coordinates), unresolved_points = 0L, open_paths = 0L, stringsAsFactors = FALSE)
      next
    }
    rings <- territory$rings[[id]]
    if (territory$open[[id]] > 0L) {
      diagnostics[[length(diagnostics)+1L]] <- data.frame(cluster=id,status="open_contour",
        input_points=nrow(coordinates),paths=0L,assigned_points=0L,unresolved_points=nrow(coordinates),
        open_paths=territory$open[[id]])
      next
    }
    if (method == "territory") {
      if (!length(rings)) {
        status <- "no_territory"
        diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = status, input_points = nrow(coordinates), paths = 0L,
          assigned_points = 0L, unresolved_points = nrow(coordinates), open_paths = territory$open[[id]], stringsAsFactors = FALSE)
        next
      }
      for (ring in rings) {
        next_path <- next_path + 1L
        rows[[length(rows) + 1L]] <- .outline_path_frame(id, ring, "polygon", next_path)
      }
      membership <- rowSums(.outline_membership(coordinates$x, coordinates$y, rings)) %% 2L == 1L
      diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = "ok", input_points = nrow(coordinates), paths = length(rings),
        assigned_points = sum(membership), unresolved_points = sum(!membership), open_paths = territory$open[[id]], stringsAsFactors = FALSE)
      next
    }
    if (!length(rings)) {
      status <- "unresolved"
      diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = status, input_points = nrow(coordinates), paths = 0L,
        assigned_points = 0L, unresolved_points = nrow(coordinates), open_paths = territory$open[[id]], stringsAsFactors = FALSE)
      next
    }
    membership <- .outline_membership(coordinates$x, coordinates$y, rings)
    assignment_count <- rowSums(membership)
    if (!length(rings) || any(assignment_count != 1L)) {
      diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = "unresolved", input_points = nrow(coordinates), paths = 0L,
        assigned_points = sum(assignment_count == 1L), unresolved_points = sum(assignment_count != 1L), open_paths = territory$open[[id]], stringsAsFactors = FALSE)
      next
    }
    occupied <- which(colSums(membership)>0L)
    # Separate tight polygons require 2D support in each inferred island.
    # Explicit/singleton components can still be drawn with point/segment glyphs.
    if (length(occupied)>1L && any(vapply(occupied,function(j) {
      !is.null(.outline_degenerate(id,coordinates[membership[,j],,drop=FALSE],j))
    },logical(1)))) {
      diagnostics[[length(diagnostics)+1L]] <- data.frame(cluster=id,status="insufficient_island_support",
        input_points=nrow(coordinates),paths=0L,assigned_points=0L,unresolved_points=nrow(coordinates),
        open_paths=territory$open[[id]])
      next
    }
    for (ring_id in occupied) {
      assigned <- coordinates[membership[, ring_id], , drop = FALSE]
      if (!nrow(assigned)) next
      next_path <- next_path + 1L
      rows[[length(rows) + 1L]] <- .outline_hull(id, assigned, next_path)
    }
    diagnostics[[length(diagnostics) + 1L]] <- data.frame(cluster = id, status = "ok", input_points = nrow(coordinates), paths = sum(colSums(membership) > 0L),
      assigned_points = nrow(coordinates), unresolved_points = 0L, open_paths = territory$open[[id]], stringsAsFactors = FALSE)
  }
  output <- if (length(rows)) do.call(rbind, rows) else data.frame(cluster = character(), path = integer(), x = numeric(), y = numeric(), type = character())
  attr(output, "diagnostics") <- do.call(rbind, diagnostics)
  attr(output, "ring_metadata") <- .outline_ring_metadata(output, nested = method == "territory")
  attr(output, "settings") <- list(method = method, bandwidth = territory$bandwidth, mass = mass, grid_size = territory$grid_size)
  output
}
