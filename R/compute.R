# Bounded, process-local cache. Keys refer to complete panel inputs.
.outline_cache <- new.env(parent = emptyenv())
.outline_cache$order <- character()
.outline_cache$sizes <- numeric()

clear_outline_cache <- function() {
  keys <- .outline_cache$order
  if (length(keys)) rm(list = keys, envir = .outline_cache)
  .outline_cache$order <- character()
  .outline_cache$sizes <- numeric()
  invisible(NULL)
}

cache_result <- function(key, value) {
  size <- as.numeric(utils::object.size(value))
  limit <- 16 * 1024^2
  if (size > limit) return(invisible(NULL))
  while (length(.outline_cache$order) >= 16L || sum(.outline_cache$sizes) + size > limit) {
    first <- .outline_cache$order[1L]
    rm(list = first, envir = .outline_cache)
    .outline_cache$order <- .outline_cache$order[-1L]
    .outline_cache$sizes <- .outline_cache$sizes[names(.outline_cache$sizes) != first]
  }
  .outline_cache[[key]] <- value
  .outline_cache$order <- c(.outline_cache$order, key)
  .outline_cache$sizes[key] <- size
}

compute_cluster_outlines <- function(data, x, y, group, clusters = NULL,
                                     method = c("territory", "tight", "islands"),
                                     bandwidth = NULL, mass = .9, grid_size = 160L,
                                     cache = TRUE, component = NULL, facets = NULL) {
  if (missing(method) && !is.null(component)) method <- "tight"
  method <- match.arg(method)
  fields <- list(x, y, group)
  valid_field <- function(s) is.character(s) && length(s) == 1L &&
    !is.na(s) && nzchar(s) && sum(names(data) == s) == 1L
  if (!is.data.frame(data) || !nrow(data) || !all(vapply(fields, valid_field, logical(1))))
    stop("Supply a nonempty data frame and unambiguous x, y and group column names.", call. = FALSE)
  xx <- data[[x]]
  yy <- data[[y]]
  labels <- data[[group]]
  numeric_vector <- function(z) is.numeric(z) && is.null(dim(z)) && all(is.finite(z))
  if (!numeric_vector(xx) || !numeric_vector(yy))
    stop("Coordinates must be finite numeric vectors.", call. = FALSE)
  if (!is.atomic(labels) || !is.null(dim(labels)) || anyNA(labels))
    stop("Each row needs one nonmissing cluster ID.", call. = FALSE)
  labels <- as.character(labels)
  if (any(!nzchar(labels))) stop("Empty cluster IDs are unsupported.", call. = FALSE)
  observed <- sort(unique(labels), method = "radix")
  if (is.null(clusters)) clusters <- observed
  if (!is.atomic(clusters) || !is.null(dim(clusters)) || anyNA(clusters))
    stop("Supply distinct observed cluster IDs.", call. = FALSE)
  clusters <- as.character(clusters)
  if (!length(clusters) || anyDuplicated(clusters) || !all(clusters %in% observed))
    stop("Supply distinct observed cluster IDs.", call. = FALSE)
  scalar <- function(v) is.numeric(v) && length(v) == 1L && is.finite(v)
  if (!is.null(bandwidth) && (!scalar(bandwidth) || bandwidth <= 0))
    stop("bandwidth must be positive and finite.", call. = FALSE)
  if (!scalar(mass) || mass <= 0 || mass >= 1) stop("mass must lie between 0 and 1.", call. = FALSE)
  if (!scalar(grid_size) || grid_size < 32 || grid_size > 512 || grid_size != floor(grid_size))
    stop("grid_size must be an integer from 32 to 512.", call. = FALSE)
  if (!is.logical(cache) || length(cache) != 1L || is.na(cache))
    stop("cache must be TRUE or FALSE.", call. = FALSE)
  parts <- NULL
  if (!is.null(component)) {
    if (method != "tight" || !valid_field(component)) stop("component requires tight geometry and a column name.", call. = FALSE)
    parts <- data[[component]]
    if (!is.atomic(parts) || !is.null(dim(parts)) || anyNA(parts) || any(!nzchar(as.character(parts))))
      stop("Each observation needs a component ID.", call. = FALSE)
    parts <- as.character(parts)
  }
  facet_data <- NULL
  if (!is.null(facets)) {
    reserved <- c("cluster","path","x","y","type","component","vertex","hole","PANEL","group",
                  "status","input_points","paths","assigned_points","unresolved_points","open_paths","other_points")
    if (!is.character(facets) || !length(facets) || anyDuplicated(facets) ||
        !all(vapply(facets,valid_field,logical(1))) || any(facets %in% reserved))
      stop("Supply distinct facet column names separate from output geometry fields.",call.=FALSE)
    facet_data <- data[facets]
    if (anyNA(facet_data) || !all(vapply(facet_data,function(v) is.atomic(v) && is.null(dim(v)),logical(1))))
      stop("Facet keys must be complete scalar values.",call.=FALSE)
  }
  columns <- list(x = x, y = y, group = group, component = component, facets = facets)
  input_sha256 <- digest::digest(list(xx, yy, labels, parts, as.list(facet_data)),
                                 algo = "sha256", serializeVersion = 2L)
  provenance <- list(
    package_version = as.character(utils::packageVersion("ggclusteroutline")),
    coordinate_space = "linear Cartesian", columns = columns, input_sha256 = input_sha256,
    r_version = as.character(getRversion()),
    sp_version = as.character(utils::packageVersion("sp")),
    dbscan_version = as.character(utils::packageVersion("dbscan"))
  )
  if (!is.null(facets)) {
    # Integer keys prevent collisions when original strings contain separators.
    keys <- lapply(facet_data,function(v) match(v,unique(v)))
    panel <- do.call(interaction,c(unname(as.list(keys)),list(drop=TRUE)))
    paths <- diagnostics <- settings <- list()
    for (index in split(seq_along(panel),panel)) {
      wanted <- intersect(clusters,labels[index])
      if (!length(wanted)) next
      part <- compute_cluster_outlines(data[index,,drop=FALSE],x,y,group,wanted,
                                       method,bandwidth,mass,grid_size,cache,component)
      info <- attr(part,"diagnostics")
      key <- facet_data[index[1L],,drop=FALSE]
      diagnostics[[length(diagnostics)+1L]] <- cbind(info,key[rep(1L,nrow(info)),,drop=FALSE])
      settings[[length(settings)+1L]] <- list(keys=key,settings=attr(part,"settings"))
      paths[[length(paths)+1L]] <- cbind(as.data.frame(part),key[rep(1L,nrow(part)),,drop=FALSE])
    }
    result <- do.call(rbind,paths)
    class(result) <- c("cluster_outlines","data.frame")
    attr(result,"diagnostics") <- do.call(rbind,diagnostics)
    attr(result,"settings") <- settings
    attr(result,"provenance") <- provenance
    attr(result,"facet_keys") <- facets
    attr(result,"method") <- method
    return(result)
  }
  if (cache) {
    key <- digest::digest(list(provenance,clusters,method,bandwidth,mass,grid_size),
                          algo = "sha256")
    if (exists(key, envir = .outline_cache, inherits = FALSE)) {
      .outline_cache$order <- c(.outline_cache$order[.outline_cache$order != key], key)
      return(report_outline_status(.outline_cache[[key]]))
    }
  }
  result <- if (method == "islands") {
    occupied_island_hulls(xx, yy, labels, clusters, bandwidth, as.integer(grid_size))
  } else if (is.null(parts)) {
    outline_geometry(xx, yy, labels, clusters, method, bandwidth, mass, as.integer(grid_size))
  } else {
    component_hulls(xx, yy, labels, parts, clusters)
  }
  meta <- attr(result,"ring_metadata")
  if (!"component" %in% names(result)) {
    result$component <- as.character(result$path)
    result$hole <- rep(FALSE,nrow(result))
    if (!is.null(meta) && nrow(meta)) {
      matched <- match(paste(result$cluster,result$path),paste(meta$cluster,meta$path))
      use <- !is.na(matched)
      result$component[use] <- as.character(meta$component[matched[use]])
      result$hole[use] <- meta$hole[matched[use]]
    }
  } else {
    result$hole <- rep(FALSE,nrow(result))
  }
  result$vertex <- if (nrow(result)) {
    sequence(rle(paste(result$cluster,result$path))$lengths)
  } else integer()
  class(result) <- c("cluster_outlines", "data.frame")
  attr(result,"method") <- method
  attr(result,"provenance") <- provenance
  if (cache) cache_result(key, result)
  report_outline_status(result)
}


report_outline_status <- function(result) {
  diag <- attr(result, "diagnostics")
  missing <- diag$cluster[diag$paths == 0L]
  if (length(missing)) {
    shown <- paste(utils::head(missing, 8L), collapse = ", ")
    more <- if (length(missing) > 8L) sprintf(" and %d more",length(missing)-8L) else ""
    warning("No supported outline for ", shown, more,
            ". Inspect attr(result, 'diagnostics') for the reason.", call. = FALSE)
  }
  result
}

component_hulls <- function(x, y, labels, parts, clusters) {
  ix <- split(seq_along(labels), labels)
  output <- list()
  diagnostics <- vector("list", length(clusters))
  for (i in seq_along(clusters)) {
    id <- clusters[i]
    rows <- ix[[id]]
    groups <- split(rows, parts[rows])
    for (j in seq_along(groups)) {
      r <- groups[[j]]
      coords <- data.frame(x=x[r], y=y[r])
      p <- .outline_hull(id, coords, j)
      p$component <- names(groups)[j]
      output[[length(output) + 1L]] <- p
    }
    diagnostics[[i]] <- data.frame(cluster=id, status="supplied_components",
      input_points=length(rows), paths=length(groups), assigned_points=length(rows),
      unresolved_points=0L)
  }
  result <- do.call(rbind, output)
  attr(result,"diagnostics") <- do.call(rbind, diagnostics)
  attr(result,"settings") <- list(method="tight", components="supplied")
  result
}

# Connected components on occupied square tiles, within each original label.
# DBSCAN with minPts=1 at sqrt(2) grid units is 8-neighbour connectivity.
# The compact tile representation avoids materialising cell-cell neighbour lists.
occupied_island_hulls <- function(x, y, labels, clusters, bandwidth, grid_size) {
  span <- max(diff(range(x)),diff(range(y)))
  width <- if (is.null(bandwidth)) .035 * span else bandwidth
  width <- max(width,span/grid_size)
  if (!is.finite(width)) stop("Coordinate range is too large for a finite grid.",call.=FALSE)
  parts <- integer(length(x))
  if (width > 0) {
    ix <- floor((x-min(x))/width)
    iy <- floor((y-min(y))/width)
    stride <- max(ix)+1
    cell <- ix + stride*iy
    indexed <- split(seq_along(labels),labels)
    for (id in clusters) {
      rows <- indexed[[id]]
      tiles <- sort(unique(cell[rows]))
      if (length(tiles)==1L) next
      xy <- cbind(x=tiles %% stride,y=tiles %/% stride)
      components <- dbscan::dbscan(xy,eps=sqrt(2)+1e-8,minPts=1L)$cluster
      parts[rows] <- components[match(cell[rows],tiles)]
    }
  }
  result <- component_hulls(x,y,labels,parts,clusters)
  attr(result,"diagnostics")$status <- "occupied_islands"
  attr(result,"settings") <- list(method="islands",tile_width=width,grid_size=grid_size)
  result
}
