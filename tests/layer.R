library(ggclusteroutline)

testthat::test_that("computed outlines retain selected groups across facets", {
  points <- data.frame(
    x = c(-2, -1.8, -2.1, 2, 2.2, 1.9, -2, -1.8, -2.1, 2, 2.2, 1.9),
    y = c(-1, -1.1, -0.8, 1, 1.2, 0.8, 1, 0.9, 1.2, -1, -1.2, -0.8),
    leiden = rep(c("rare-A", "other"), each = 3, times = 2),
    panel = rep(c("left", "right"), each = 6)
  )
  plot <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    ggplot2::geom_point() +
    geom_cluster_outline(ggplot2::aes(group = leiden), clusters = "rare-A", method = "islands") +
    ggplot2::facet_wrap(~panel)

  built <- ggplot2::ggplot_build(plot)
  outline_data <- built$data[[2L]]
  testthat::expect_setequal(unique(outline_data$PANEL), c(1L, 2L))
  testthat::expect_equal(length(unique(outline_data$PANEL)), 2L)
})

testthat::test_that("a selected label absent from a facet yields no path there", {
  points <- data.frame(
    x = c(-1, 0, 1, -1, 0, 1),
    y = c(0, 1, 0, 0, 1, 0),
    leiden = c(rep("4", 3), rep("7", 3)),
    panel = rep(c("contains", "absent"), each = 3)
  )
  plot <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_cluster_outline(ggplot2::aes(group = leiden), clusters = "4", method = "islands") +
    ggplot2::facet_wrap(~panel)
  outline_data <- ggplot2::ggplot_build(plot)$data[[1L]]
  testthat::expect_equal(length(unique(outline_data$PANEL)), 1L)
})

testthat::test_that("frozen paths use fixed outline styling", {
  points <- data.frame(
    x = c(-1, 0, 1, -1, 0, 1),
    y = c(0, 1, 0, 0.2, 1.2, 0.2),
    leiden = rep("4", 6),
    expression = seq_len(6)
  )
  frozen <- compute_cluster_outlines(points, "x", "y", "leiden", method = "islands")
  plot <- ggplot2::ggplot(points, ggplot2::aes(x, y, colour = expression)) +
    ggplot2::geom_point() +
    geom_cluster_outline(frozen, colour = "black")
  outline_data <- ggplot2::ggplot_build(plot)$data[[2L]]
  testthat::expect_true(all(outline_data$colour == "black"))
  testthat::expect_true("outline_type" %in% names(outline_data))
  testthat::expect_error(geom_cluster_outline(frozen, method = "islands"), "cannot receive geometry arguments")
})

testthat::test_that("frozen paths require and retain facet keys", {
  points <- data.frame(
    x = c(-1, 0, 1, -1, 0, 1),
    y = c(0, 1, 0, 0.2, 1.2, 0.2),
    leiden = rep("4", 6),
    sample = rep(c("left", "right"), each = 3)
  )
  keyed <- compute_cluster_outlines(points, "x", "y", "leiden", method = "islands", facets = "sample")
  faceted <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~sample) +
    geom_cluster_outline(keyed)
  built <- ggplot2::ggplot_build(faceted)
  testthat::expect_setequal(unique(built$data[[2L]]$PANEL), c(1L, 2L))

  faceted_after <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    ggplot2::geom_point() + geom_cluster_outline(keyed) + ggplot2::facet_wrap(~sample)
  testthat::expect_setequal(unique(ggplot2::ggplot_build(faceted_after)$data[[2L]]$PANEL), c(1L, 2L))

  unkeyed <- compute_cluster_outlines(points, "x", "y", "leiden", method = "islands")
  testthat::expect_error(
    ggplot2::ggplot_build(
      ggplot2::ggplot(points, ggplot2::aes(x, y)) + ggplot2::facet_wrap(~sample) +
        geom_cluster_outline(unkeyed)
    ),
    "matching facet keys"
  )
})

testthat::test_that("frozen point primitives render together", {
  frozen <- structure(
    data.frame(
      cluster = c("a", "b", "c"), path = 1:3,
      x = c(-1, 0, 1), y = c(0, 1, 0), type = "point"
    ),
    class = c("cluster_outlines", "data.frame")
  )
  output <- tempfile(fileext = ".png")
  testthat::expect_silent(
    ggplot2::ggsave(
      output,
      ggplot2::ggplot() + geom_cluster_outline(frozen),
      width = 3, height = 2, dpi = 100, device = grDevices::png
    )
  )
  testthat::expect_true(file.exists(output))
})

testthat::test_that("unknown selection and invalid input are diagnosed", {
  points <- data.frame(x = c(0, 1, 2), y = c(0, 1, 0), leiden = "4")
  unknown <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_cluster_outline(ggplot2::aes(group = leiden), clusters = "absent", method = "islands")
  testthat::expect_error(ggplot2::ggplot_build(unknown), "Unknown selected cluster IDs")

  points$x[[2L]] <- NA_real_
  invalid <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_cluster_outline(ggplot2::aes(group = leiden), method = "islands", na.rm = TRUE)
  testthat::expect_warning(ggplot2::ggplot_build(invalid), "omitted invalid rows")
})

testthat::test_that("unsupported coordinates and transformed scales fail", {
  points <- data.frame(x = c(1, 2, 1), y = c(1, 1, 2), leiden = "4")
  polar <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_cluster_outline(ggplot2::aes(group = leiden), method = "islands") + ggplot2::coord_polar()
  logged <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_cluster_outline(ggplot2::aes(group = leiden), method = "islands") + ggplot2::scale_x_log10()
  testthat::expect_error(ggplot2::ggplotGrob(polar), "Cartesian coordinates")
  testthat::expect_warning(ggplot2::ggplot_build(logged), "untransformed Cartesian scales")
})

testthat::test_that("a real Seurat DimPlot accepts the normal outline layer", {
  testthat::skip_if_not_installed("Seurat")
  fixture <- utils::read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
  cells <- paste0("cell_", seq_len(nrow(fixture)))
  counts <- Matrix::Matrix(
    matrix(1L, nrow = 1L, ncol = length(cells), dimnames = list("placeholder", cells)),
    sparse = TRUE
  )
  object <- Seurat::CreateSeuratObject(counts)
  object$leiden <- factor(fixture$leiden)
  embeddings <- matrix(
    c(fixture$x, fixture$y),
    ncol = 2,
    dimnames = list(cells, c("UMAP_1", "UMAP_2"))
  )
  object[["umap"]] <- SeuratObject::CreateDimReducObject(
    embeddings = embeddings,
    key = "UMAP_",
    assay = SeuratObject::DefaultAssay(object)
  )
  dim_plot <- Seurat::DimPlot(object, reduction = "umap", group.by = "leiden")
  built <- ggplot2::ggplot_build(
    dim_plot + geom_cluster_outline(ggplot2::aes(group = leiden), clusters = "4")
  )
  testthat::expect_gt(nrow(built$data[[2L]]), 0L)
  testthat::expect_equal(nrow(built$data[[1L]]), nrow(fixture))
  testthat::expect_identical(built$data[[1L]]$colour,ggplot2::ggplot_build(dim_plot)$data[[1L]]$colour)
  testthat::expect_length(unique(built$data[[2L]]$group),2L)
})

testthat::test_that("a layer object can be reused with different plot coordinates", {
  d <- data.frame(a=c(1,2,4),b=c(2,4,3),id="a")
  layer <- geom_cluster_outline(ggplot2::aes(group=id),method="islands")
  first <- ggplot2::ggplot(d,ggplot2::aes(a,b))+layer
  second <- ggplot2::ggplot(d,ggplot2::aes(b,a))+layer
  testthat::expect_null(layer$mapping$x)
  testthat::expect_equal(sort(unique(ggplot2::ggplot_build(first)$data[[1]]$x)),sort(d$a))
  testthat::expect_equal(sort(unique(ggplot2::ggplot_build(second)$data[[1]]$x)),sort(d$b))
})
