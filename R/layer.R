# ggplot2 adapter for the data-space outlines returned by compute_cluster_outlines().

.outline_facet_expressions <- function(facet) {
  params <- facet$params
  c(params$facets, params$rows, params$cols)
}

.outline_data_names <- function(expression, available) {
  if (rlang::is_symbol(expression)) return(intersect(rlang::as_string(expression), available))
  if (!is.call(expression)) return(character())
  if (rlang::is_call(expression, c("$", "[["))) {
    if (rlang::is_symbol(expression[[2L]], ".env")) return(character())
    if (rlang::is_symbol(expression[[2L]], ".data")) return(rlang::as_string(expression[[3L]]))
  }
  arguments <- as.list(expression)[-1L]
  unique(unlist(lapply(arguments, .outline_data_names, available = available), use.names = FALSE))
}

.outline_direct_facet_names <- function(facet) {
  expressions <- .outline_facet_expressions(facet)
  if (!length(expressions)) return(character())
  keys <- vapply(expressions, function(facet) {
    expression <- rlang::get_expr(facet)
    if (rlang::is_symbol(expression)) return(rlang::as_string(expression))
    if (rlang::is_call(expression, "$") && rlang::is_symbol(expression[[2L]], ".data") &&
        rlang::is_symbol(expression[[3L]])) return(rlang::as_string(expression[[3L]]))
    if (rlang::is_call(expression, "[[") && rlang::is_symbol(expression[[2L]], ".data") &&
        is.character(expression[[3L]]) && length(expression[[3L]]) == 1L) return(expression[[3L]])
    NA_character_
  }, character(1))
  if (anyNA(keys)) return(NULL)
  unique(keys)
}

.outline_has_nonlinear_scale <- function(scales) {
  any(!vapply(scales, function(scale) identical(scale$trans$name, "identity"), logical(1)))
}

StatFrozenClusterOutline <- ggplot2::ggproto(
  "StatFrozenClusterOutline",
  ggplot2::StatIdentity,
  extra_params = c("na.rm", "facet_keys"),
  compute_layer = function(data, params, layout) {
    actual_keys <- .outline_direct_facet_names(layout$facet)
    if (is.null(actual_keys) || !setequal(params$facet_keys, actual_keys)) {
      stop("Frozen cluster_outlines need matching facet keys from direct facet variables; recompute paths for transformed facets.", call. = FALSE)
    }
    if (.outline_has_nonlinear_scale(layout$panel_scales_x) || .outline_has_nonlinear_scale(layout$panel_scales_y)) {
      stop("geom_cluster_outline() supports untransformed Cartesian scales only.", call. = FALSE)
    }
    ggplot2::StatIdentity$compute_layer(data, params, layout)
  }
)

StatClusterOutline <- ggplot2::ggproto(
  "StatClusterOutline",
  ggplot2::Stat,
  required_aes = "group",
  extra_params = c("na.rm", "clusters", "method", "bandwidth", "mass", "grid_size", "cache", "replicate", "source_columns"),
  compute_layer = function(self, data, params, layout) {
    if (!isTRUE(params$replicate)) {
      # ggplot resolved all layers' data before forming panels. A variable
      # supplied only by a sibling layer is still a facet key for this layer.
      facets <- .outline_facet_expressions(layout$facet)
      keys <- unlist(lapply(facets, function(facet) {
        .outline_data_names(rlang::get_expr(facet), layout$facet_params$.possible_columns)
      }), use.names = FALSE)
      missing <- setdiff(keys, params$source_columns)
      if (length(missing)) {
        stop("Computed cluster outlines need facet keys in their data: ",
             paste(missing, collapse = ", "), ". For intentional replication set replicate = TRUE.", call. = FALSE)
      }
    }
    ggplot2::ggproto_parent(ggplot2::Stat, self)$compute_layer(data, params, layout)
  },
  setup_data = function(data, params) {
    if (!all(c("x", "y") %in% names(data))) {
      seurat_axes <- c("UMAP_1", "UMAP_2")
      if (all(seurat_axes %in% names(data))) {
        data$x <- data[[seurat_axes[[1L]]]]
        data$y <- data[[seurat_axes[[2L]]]]
      } else {
        stop(
          "geom_cluster_outline() needs x and y aesthetics. For Seurat DimPlot, map its embedding columns explicitly when they are not named UMAP_1 and UMAP_2.",
          call. = FALSE
        )
      }
    }
    invalid_coordinates <- !is.finite(data$x) | !is.finite(data$y)
    if (!"cluster_key" %in% names(data)) {
      stop("geom_cluster_outline() requires an unscaled original group key.", call. = FALSE)
    }
    invalid_groups <- is.na(data$cluster_key) | is.na(data$group)
    invalid <- invalid_coordinates | invalid_groups
    if (any(invalid)) {
      if (isTRUE(params$na.rm)) {
        warning("geom_cluster_outline() omitted invalid rows: ", sum(invalid), call. = FALSE)
        data <- data[!invalid, , drop = FALSE]
      } else {
      stop(
        "geom_cluster_outline() requires finite x/y coordinates and nonmissing group keys; invalid rows: ",
        sum(invalid_coordinates | invalid_groups),
        call. = FALSE
      )
      }
    }
    if (!is.null(params$clusters)) {
      unknown <- setdiff(as.character(params$clusters), unique(as.character(data$cluster_key)))
      if (length(unknown)) {
        stop("Unknown selected cluster IDs: ", paste(unknown, collapse = ", "), call. = FALSE)
      }
    }
    data
  },
  compute_panel = function(data, scales, clusters = NULL, method = "tight",
                           bandwidth = NULL, mass = 0.9, grid_size = 160L,
                           cache = TRUE, na.rm = FALSE) {
    if (!identical(scales$x$trans$name, "identity") || !identical(scales$y$trans$name, "identity")) {
      stop("geom_cluster_outline() supports untransformed Cartesian scales only.", call. = FALSE)
    }
    if (!is.null(clusters)) {
      clusters <- intersect(as.character(clusters), unique(as.character(data$cluster_key)))
      if (!length(clusters)) {
        empty <- data.frame(
          x = numeric(), y = numeric(), cluster = character(), path = integer(),
          type = character(), group = integer(), outline_type = character()
        )
        empty$PANEL <- data$PANEL[0L]
        return(empty)
      }
    }
    outlines <- compute_cluster_outlines(
      data = data,
      x = "x",
      y = "y",
      group = "cluster_key",
      clusters = clusters,
      method = method,
      bandwidth = bandwidth,
      mass = mass,
      grid_size = grid_size,
      cache = cache
    )
    if (nrow(outlines) == 0L) return(outlines)

    outlines$group <- as.integer(interaction(outlines$cluster, outlines$path, drop = TRUE))
    outlines$outline_type <- outlines$type
    outlines$PANEL <- data$PANEL[[1L]]
    outlines
  }
)

GeomClusterOutline <- ggplot2::ggproto(
  "GeomClusterOutline",
  ggplot2::Geom,
  required_aes = c("x", "y"),
  optional_aes = c("label", "outline_type"),
  default_aes = ggplot2::aes(
    colour = "#C23B22", linewidth = 0.5, linetype = 1,
    alpha = NA, group = NA, size = 1.5, shape = 16, stroke = 0.5,
    cluster_key = NA, outline_type = NA
  ),
  draw_key = ggplot2::draw_key_path,
  draw_panel = function(data, panel_params, coord, na.rm = FALSE) {
    supported_coordinate <- inherits(coord, "CoordCartesian") && isTRUE(coord$is_linear()) && !inherits(coord,"CoordSf")
    if (!supported_coordinate) {
      stop("geom_cluster_outline() supports Cartesian coordinates and coord_flip() only.", call. = FALSE)
    }

    type <- if ("outline_type" %in% names(data)) data$outline_type else data$type
    points <- data[type == "point", , drop = FALSE]
    paths <- data[type != "point", , drop = FALSE]
    grobs <- list()
    if (nrow(paths) > 0L) {
      grobs[[length(grobs) + 1L]] <- ggplot2::GeomPath$draw_panel(
        paths, panel_params, coord, na.rm = na.rm
      )
    }
    if (nrow(points) > 0L) {
      if (!"fill" %in% names(points)) points$fill <- NA_character_
      grobs[[length(grobs) + 1L]] <- ggplot2::GeomPoint$draw_panel(
        points, panel_params, coord, na.rm = na.rm
      )
    }
    do.call(grid::grobTree, grobs)
  }
)

#' Draw data-space cluster outlines
#'
#' @param data Data for computation, or a `cluster_outlines` object returned by
#'   `compute_cluster_outlines()`.
#' @param clusters Optional original group keys to draw.
#' @param method Geometry mode passed to `compute_cluster_outlines()`.
#' @param bandwidth,mass,grid_size,cache Geometry settings passed unchanged to
#'   `compute_cluster_outlines()`.
#' @param replicate Allow a separately supplied data table without the plot's
#'   facet keys to be repeated in every facet. Defaults to `FALSE`.
#' @export
geom_cluster_outline <- function(mapping = NULL, data = NULL, clusters = NULL,
                                 method = c("tight", "territory", "islands"),
                                 bandwidth = NULL, mass = 0.9,
                                 grid_size = 160L, cache = TRUE, ...,
                                 colour = "#C23B22", linewidth = 0.5,
                                 linetype = 1, alpha = NA, size = 1.5,
                                 shape = 16, stroke = 0.5,
                                 na.rm = FALSE, show.legend = NA,
                                 inherit.aes = TRUE, replicate = FALSE) {
  frozen_geometry_args <- !missing(method) || !missing(bandwidth) || !missing(mass) ||
    !missing(grid_size) || !missing(cache)
  method <- match.arg(method)
  if (inherits(mapping, "cluster_outlines") && is.null(data)) {
    data <- mapping
    mapping <- NULL
  }
  if (inherits(data, "cluster_outlines")) {
    if (frozen_geometry_args) {
      stop("Frozen cluster_outlines cannot receive geometry arguments.", call. = FALSE)
    }
    frozen <- as.data.frame(data)
    required <- c("cluster", "path", "x", "y", "type")
    missing <- setdiff(required, names(frozen))
    if (length(missing) > 0L) {
      stop("Frozen cluster_outlines data is missing: ", paste(missing, collapse = ", "), call. = FALSE)
    }
    frozen_facet_keys <- attr(data, "facet_keys")
    missing_facet_keys <- setdiff(frozen_facet_keys, names(frozen))
    if (length(missing_facet_keys)) {
      stop("Frozen cluster_outlines data is missing facet keys: ",
           paste(missing_facet_keys, collapse = ", "), call. = FALSE)
    }
    if (!is.null(clusters)) {
      unknown <- setdiff(as.character(clusters),attr(data,"diagnostics")$cluster)
      if (length(unknown)) stop("Unknown frozen cluster IDs: ",paste(unknown,collapse=", "),call.=FALSE)
      frozen <- frozen[frozen$cluster %in% clusters,,drop=FALSE]
    }
    nonpoints <- frozen$type != "point"
    if (any(nonpoints)) {
      if (!"vertex" %in% names(frozen) || !is.numeric(frozen$vertex) ||
          any(!is.finite(frozen$vertex[nonpoints]))) {
        stop("Frozen cluster_outlines paths need finite stored vertex order.", call. = FALSE)
      }
      path_keys <- c(frozen_facet_keys, "cluster", "path")
      path_rows <- frozen[nonpoints, , drop = FALSE]
      key_codes <- lapply(path_rows[path_keys], function(x) match(x, unique(x)))
      path_id <- do.call(interaction, c(unname(key_codes), list(drop = TRUE)))
      valid_path <- function(rows) {
        vertex <- path_rows$vertex[rows]
        type <- unique(path_rows$type[rows])
        if (length(type) != 1L || any(vertex != floor(vertex)) ||
            !all(sort(vertex) == seq_along(vertex))) return(FALSE)
        ordered <- rows[order(vertex, method = "radix")]
        if (type == "segment") return(length(ordered) == 2L)
        if (type != "polygon") return(FALSE)
        length(ordered) >= 4L &&
          isTRUE(all.equal(path_rows$x[ordered[1L]], path_rows$x[ordered[length(ordered)]], tolerance = 1e-10)) &&
          isTRUE(all.equal(path_rows$y[ordered[1L]], path_rows$y[ordered[length(ordered)]], tolerance = 1e-10))
      }
      if (!all(vapply(split(seq_len(nrow(path_rows)), path_id), valid_path, logical(1)))) {
        stop("Frozen cluster_outlines paths need contiguous unique vertex IDs and closed polygons.", call. = FALSE)
      }
      ordering <- do.call(order, c(unname(frozen[path_keys]), list(frozen$vertex, method = "radix")))
      frozen <- frozen[ordering, , drop = FALSE]
    }
    frozen$.outline_draw_group <- interaction(frozen$cluster, frozen$path, drop = TRUE)
    frozen_mapping <- ggplot2::aes(
      x = .data$x, y = .data$y,
      group = .data$.outline_draw_group, outline_type = .data$type
    )
    layer <- ggplot2::layer(
      data = frozen,
      mapping = frozen_mapping,
      stat = StatFrozenClusterOutline,
      geom = GeomClusterOutline,
      position = "identity",
      show.legend = show.legend,
      inherit.aes = FALSE,
      params = list(
        na.rm = na.rm, colour = colour, linewidth = linewidth,
        linetype = linetype, alpha = alpha, size = size,
        shape = shape, stroke = stroke,
        facet_keys = attr(data, "facet_keys"), ...
      )
    )
    attr(layer, "ggco_frozen") <- TRUE
    class(layer) <- c("ggclusteroutline_layer", class(layer))
    return(layer)
  }

  if (!is.null(mapping) && !is.null(mapping$group) && is.null(mapping$cluster_key)) {
    mapping$cluster_key <- mapping$group
  }
  if (!is.logical(replicate) || length(replicate) != 1L || is.na(replicate)) {
    stop("replicate must be TRUE or FALSE.", call. = FALSE)
  }
  layer <- ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = StatClusterOutline,
    geom = GeomClusterOutline,
    position = "identity",
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      clusters = clusters,
      method = method,
      bandwidth = bandwidth,
      mass = mass,
      grid_size = grid_size,
      cache = cache,
      replicate = replicate,
      colour = colour,
      linewidth = linewidth,
      linetype = linetype,
      alpha = alpha,
      size = size,
      shape = shape,
      stroke = stroke,
      ...
    )
  )
  class(layer) <- c("ggclusteroutline_layer", class(layer))
  layer
}

ggplot_add.ggclusteroutline_layer <- function(object, plot, ...) {
  # ggproto objects are environments. Derive a child before resolving mappings
  # so one reusable layer can be added to plots with different coordinates.
  original <- object
  object <- ggplot2::ggproto(
    NULL, original,
    setup_layer = function(self, data, plot) {
      if (!isTRUE(attr(original, "ggco_frozen"))) self$stat_params$source_columns <- names(data)
      ggplot2::ggproto_parent(original, self)$setup_layer(data, plot)
    }
  )
  mapping <- object$mapping
  if (is.null(mapping)) mapping <- ggplot2::aes()
  if (isTRUE(object$inherit.aes)) {
    point_layers <- Filter(function(l) inherits(l$geom,"GeomPoint") ||
      inherits(l$geom,"GeomScattermore"),plot$layers)
    sources <- c(list(plot$mapping),lapply(point_layers, function(l) l$mapping))
    for (key in c("x","y","group")) {
      if (!is.null(mapping[[key]])) next
      for (src in sources) if (!is.null(src[[key]])) {
        mapping[[key]] <- src[[key]]
        break
      }
    }
  }
  if (is.null(mapping$group)) stop("Map the supplied cluster ID with aes(group = ...).",call.=FALSE)
  if (is.null(mapping$x) || is.null(mapping$y)) stop("Map x and y to the embedding coordinates.",call.=FALSE)
  if (is.null(mapping$outline_type)) mapping$cluster_key <- mapping$group
  object$mapping <- mapping
  object$inherit.aes <- FALSE
  NextMethod()
}
