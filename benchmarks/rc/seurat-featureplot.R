# Run from the package checkout with Seurat and ggclusteroutline installed.
library(Seurat)
library(ggplot2)
library(ggclusteroutline)

# Give two existing identities display names on a copy of the example object.
example <- RenameIdents(pbmc_small, `1` = "Cluster 1", `2` = "Cluster 2")
highlight <- c("Cluster 1", "Cluster 2")
p <- FeaturePlot(example, features = "MS4A1", reduction = "tsne",
                 order = TRUE, raster = FALSE, combine = FALSE)[[1]]
# Let the axes include the whole outline, even beyond the outermost point.
outlined <- p + scale_x_continuous() + scale_y_continuous() +
  geom_cluster_outline(aes(group = ident), clusters = highlight)
labelled <- LabelClusters(outlined, id = "ident", clusters = highlight,
                          position = "nearest", repel = TRUE, seed = 17)

original <- ggplot_build(p)$data[[1]]
layers <- ggplot_build(labelled)$data
stopifnot(identical(layers[[1]][c("x", "y", "colour")], original[c("x", "y", "colour")]),
          nrow(original) == ncol(pbmc_small),
          all(is.finite(layers[[2]]$x)), all(is.finite(layers[[2]]$y)),
          setequal(layers[[2]]$cluster, highlight),
          identical(sort(as.character(layers[[3]]$label)), sort(highlight)))
ggsave("man/figures/seurat-featureplot.png", labelled, width = 5, height = 3.8,
       dpi = 160, bg = "white")
