# Rebuild the README figure from the installed 700-cell example.
library(Seurat)
library(ggplot2)
library(ggclusteroutline)
library(patchwork)

d <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
cells <- paste0("cell_", seq_len(nrow(d)))
expression <- matrix(d$NKG7, nrow = 1, dimnames = list("NKG7", cells))
object <- CreateSeuratObject(counts = CreateAssayObject(data = expression))
umap <- cbind(UMAP_1 = d$x, UMAP_2 = d$y)
rownames(umap) <- cells
object[["umap"]] <- CreateDimReducObject(embeddings = umap, key = "UMAP_", assay = "RNA")
object$leiden <- factor(d$leiden)
Idents(object) <- "leiden"

palette <- c("0" = "#216197", "1" = "#AD490E", "2" = "#937FB2",
             "3" = "#92956B", "4" = "#00796B")
style <- data.frame(id = c("0", "1", "4"), line = c("dotted", "dashed", "solid"),
                    width = c(0.8, 0.7, 0.6))
left <- DimPlot(object, reduction = "umap", cols = palette, pt.size = 1,
                raster = FALSE, combine = FALSE)[[1]]
right <- FeaturePlot(object, features = "NKG7", reduction = "umap", order = TRUE,
                     cols = c("#E2E1E5", "#4C276C"), pt.size = 1,
                     raster = FALSE, combine = FALSE)[[1]]
original <- ggplot_build(right)$data[[1]]

# Freeze the paths once; a fixed stroke per layer keeps expression on its own scale.
bands <- compute_cluster_outlines(d, "x", "y", "leiden", clusters = style$id, method = "tight")
for (i in seq_len(nrow(style))) {
  id <- style$id[i]
  right <- right + geom_cluster_outline(data = bands, clusters = id,
    colour = palette[[id]], linetype = style$line[i], linewidth = style$width[i])
}

# Put each ID just above its island. Group 4 has two islands.
anchors <- function(x, y) c(x = mean(range(x)), y = max(y) + 0.85)
tags <- do.call(rbind, lapply(split(bands, bands$path), function(z)
  data.frame(id = z$cluster[1], t(anchors(z$x, z$y)))))
rest <- do.call(rbind, lapply(split(d[!d$leiden %in% tags$id, ], d$leiden[!d$leiden %in% tags$id]),
  function(z) data.frame(id = as.character(z$leiden[1]), t(anchors(z$x, z$y)))))
label <- function(tab) geom_text(data = tab, aes(x, y, label = id), inherit.aes = FALSE,
                                 colour = "#222222", fontface = "bold", size = 3.6)
left <- left + label(rbind(tags, rest)) + NoLegend() + ggtitle("Leiden clusters")
right <- right + label(tags) + labs(title = "NKG7 expression", colour = "NKG7") +
  guides(colour = guide_colourbar(direction = "horizontal", barwidth = grid::unit(2.5, "cm"),
                                   barheight = grid::unit(0.2, "cm")))
common <- list(scale_x_continuous(limits = range(d$x) + c(-1.1,1.1)),
               scale_y_continuous(limits = range(d$y) + c(-1.1,2.0)), coord_equal(),
               theme_void(base_size = 12), theme(plot.title = element_text(face = "bold"),
               legend.position = "bottom", plot.margin = margin(6,9,6,9)))
left <- left + common + theme(legend.position = "none")
right <- right + common
left_data <- ggplot_build(left)$data[[1]]
layers <- ggplot_build(right)$data
stopifnot(nrow(original) == 700L, nrow(left_data) == 700L,
  identical(layers[[1]][c("x","y","colour")], original[c("x","y","colour")]),
  isTRUE(all.equal(unname(as.matrix(right$data[,c("UMAP_1","UMAP_2")])),
                   unname(umap[rownames(right$data),]), check.attributes=FALSE)),
  all(as.numeric(right$data$NKG7) == expression[1,rownames(right$data)]),
  all(left_data$colour == unname(palette[as.character(left$data$ident)])),
  identical(table(tags$id), table(c("0","1","4","4"))))
for (i in seq_len(nrow(style))) {
  z <- layers[[i + 1L]]
  stopifnot(nrow(z) > 0, all(is.finite(z$x)), all(is.finite(z$y)),
            all(z$colour == palette[[style$id[i]]]), all(z$linetype == style$line[i]),
            all(z$linewidth == style$width[i]))
}
ggsave("man/figures/seurat-featureplot.png", left + right, width = 8.4,
       height = 4.8, dpi = 170, bg = "white")
