# ggclusteroutline

Keep gene expression in colour and show cluster identity with an outline. Add a ggplot2 layer to an existing Seurat UMAP to outline **one cluster or all clusters**. The default draws the regions where each cluster is locally most abundant.

![622,791 NSCLC T/NK cells on the same UMAP: Leiden assignments, overlapping ggforce hulls and separate ggclusteroutline territories](research/shared-islands/NSCLC.png)

In this lung cancer dataset, several Leiden clusters share one large UMAP island. A few distant members can pull a hull across much of the map. The territory outlines on the right show where each group concentrates. Four of the 18 groups have no territory at the settings shown.

## Install v0.1.1

```r
install.packages("remotes")  # once
remotes::install_github("nbatada/ggclusteroutline@v0.1.1", upgrade = "never")
packageVersion("ggclusteroutline")  # 0.1.1
```

[Download the tested R source archive and checksum](https://github.com/nbatada/ggclusteroutline/releases/tag/v0.1.1).

## Try it on your own Seurat FeaturePlot

Start with a Seurat object named `object` that already has a UMAP, cluster identities and a gene in its active assay. Set the gene and cluster ID for your data. `FeaturePlot()` carries the active identities in its plot data as `ident`; if you keep your desired assignments in a metadata column, set `Idents(object) <- "leiden"` (or `"seurat_clusters"`) first.

```r
library(Seurat)
library(ggplot2)
library(ggclusteroutline)

gene <- "NKG7"                           # a feature in your active assay
levels(Idents(object))                   # available cluster IDs
cluster_id <- "4"                        # choose one of those IDs

p <- FeaturePlot(object, features = gene, reduction = "umap",
                 combine = FALSE)[[1]] +
  scale_x_continuous() + scale_y_continuous()  # allow outlines beyond the outermost cells

# One cluster: keep all cells visible, including the neighboring clusters.
p + geom_cluster_outline(aes(group = ident), clusters = cluster_id,
                         colour = "black", linewidth = 0.6)

# All clusters with a supported territory: omit the clusters argument.
p + geom_cluster_outline(aes(group = ident), colour = "black", linewidth = 0.6)
```

Pass `clusters = c("0", "4")` to highlight several groups. Select groups in the outline layer so it can compare their local densities against the full map. A dispersed cluster can legitimately have no territory.

![Seurat example: Leiden identities beside an NKG7 FeaturePlot with selected cluster outlines in matching colours](man/figures/seurat-featureplot.png)

The example above uses different line styles and the optional `tight` method to show the two islands of PBMC cluster 4. [Complete runnable example, including cluster colours and labels](benchmarks/rc/seurat-featureplot.R).

## How does it compare with ggforce?

The panels use identical coordinates and assignments within each study. The middle panel draws a ggforce concave hull for each Leiden group. The right panel draws its locally dominant territory. Look for outlines that cross a neighboring group's cells.

![33,106 Yost basal cell carcinoma T cells: the same full embedding with Leiden assignments, ggforce hulls and ggclusteroutline territories](research/shared-islands/Yost.png)

| Reading the examples | Members among cells inside the ggforce hull | Members among cells inside the territory | Cluster members retained by the territory |
|---|---:|---:|---:|
| NSCLC T/NK · cluster 6 | 23.6% | **66.9%** | 72.1% |
| Yost BCC T cells · cluster 5 | 7.9% | **67.6%** | 51.8% |

Both hulls enclosed every member of the selected group. The territory sacrifices coverage to show the local concentration. A cell outside its group's outline keeps its original assignment. These full-map comparisons use a 256-node grid per axis, bandwidth of 1.2% of the longer map span and 97% density mass; the quick start uses the package defaults. [NSCLC selected groups](benchmarks/rc/NSCLC-full-map.png) · [Yost selected groups](benchmarks/rc/Yost-full-map.png) · [Benchmark methods and counts](benchmarks/rc/README.md).

## Choose what the outline should show

The one-line default draws the regions where each label locally dominates. With no tuning it drew 22 of 23 Yost groups and 13 of 18 NSCLC groups. A dispersed group may have no territory. Use `tight` for an all-member band when every member can be assigned to one supported island. It drew two bands for PBMC cluster 4 and abstained on both full atlases. Use `islands` when every member needs a glyph or enclosure. Its tile width can split a compact cloud into many pieces (21 paths for the audited 400-point Gaussian at defaults).

```r
library(ggplot2)
library(ggclusteroutline)

cells <- read.csv(system.file("extdata", "pbmc700.csv", package = "ggclusteroutline"))
p <- ggplot(cells, aes(x, y)) +
  geom_point(aes(colour = NKG7), size = 0.7) +
  coord_equal()

p + geom_cluster_outline(aes(group = leiden))
p + geom_cluster_outline(aes(group = leiden), clusters = 4, method = "tight")
```

Always supply the full map. The `clusters` argument selects which outlines to display after all eligible labels have competed. Each ordinary ggplot facet uses its own panel data. Separate outline tables must carry the facet variables for each panel unless you set `replicate = TRUE` to repeat those data across the missing facets. Set outline styling outside `aes()`, for example `colour = "black"`. If the point layer overrides the global coordinates, pass its coordinates explicitly to the outline, for example `aes(x = UMAP_1, y = UMAP_2, group = leiden)`. Use `coord_cartesian()` to zoom while keeping the full geometry input.

| Method | What the line means | What to look for |
|---|---|---|
| `"tight"` | Convex envelope around the observed cell centres assigned to each supported island. Territory contours provide candidate islands. | A returned group covers its members. Ambiguous or unsupported assignments can leave the group without an outline. Other labels may lie inside a hull. |
| `"islands"` | Enclose each connected set of occupied tiles within the original label. All member centres contribute, including isolated points. | Adjacent tiles connect along edges or corners. Tile width controls separation. Distinct labels can have overlapping hulls. |
| `"territory"` (default) | Inset contour of the region where this label has the largest smoothed cell count and meets its own density threshold. | Useful for overlapping populations. A rare or intermixed label may have no band. The contour can omit members and include other labels. |

The tight and territory modes use the existing CellStyle territory algorithm as their reference. For a full-member outline even when territory support is incomplete, use `method = "islands"`. This uses 8-neighbour tile connectivity within each supplied label (DBSCAN on occupied tile centres, minimum one tile). It preserves the existing biological assignments. `bandwidth` sets a smoothing length in embedding units, `mass` controls support before competition, and `grid_size` sets grid resolution. Check the result on the full labelled embedding. For known components, `compute_cluster_outlines(..., component = "island_id")` directly encloses each supplied component.

## On a Seurat DimPlot

```r
# 'leiden' must be a metadata column containing the assignments to outline.
dimplot <- Seurat::DimPlot(object, reduction = "umap", group.by = "leiden",
                          combine = FALSE)[[1]]
dimplot + geom_cluster_outline(aes(group = leiden), clusters = "4")
```

Using an individual ggplot makes the target panel explicit when Seurat returns multiple plots. The example uses the existing UMAP and cluster assignments.

## Freeze geometry across expression plots

```r
bands <- compute_cluster_outlines(cells, "x", "y", "leiden", clusters = 4)
attr(bands, "diagnostics")
saveRDS(bands, "leiden-4.rds")
p + geom_cluster_outline(data = readRDS("leiden-4.rds"), colour = "black")
```

The saved `vertex` numbers preserve path order after sorting or joining rows. Use frozen paths only for their originating embedding, membership and facet definition. New objects store geometry input column names, an order-sensitive input fingerprint, coordinate space and software versions in `attr(bands, "provenance")`. Compare fingerprints to check source identity when reusing saved results. For example, pass `facets = "sample"` when precomputing geometry for independent sample panels. The automatic in-session cache hashes coordinates, labels, selection, mode and geometry parameters. A new marker colour reuses geometry. Changing a competitor or coordinate invalidates that panel. Row reordering can miss the cache. The cache holds at most 16 results and 16 MiB of estimated geometry, with least-recently-used eviction. Use `cache = FALSE` for cold measurements or `clear_outline_cache()` to release its entries.

## Evidence and limitations

Cell-centre containment on existing CellStyle benchmark inputs, using the 256-node grid, 1.2%-of-span bandwidth and 97% mass profile:

| Full embedding | Cells / labels | Inside own territory | Inside own ggforce hull |
|---|---:|---:|---:|
| Yost BCC T cells | 33,106 / 23 | 22,515 (68.0%) | 33,106 (100%) |
| NSCLC T/NK cells | 622,791 / 18 | 395,316 (63.5%) | 622,791 (100%) |

To inspect territory coverage, compute the regions and read the member and other-label counts for each cluster:

```r
regions <- compute_cluster_outlines(cells, "x", "y", "leiden", method = "territory")
attr(regions, "diagnostics")[c("cluster", "input_points", "assigned_points", "other_points")]
```

The ggforce counts use polygons extracted from actual ggforce renders. Broad hulls can include many cells assigned to other labels. The package's territory classifications differed from CellStyle Python for one Yost cell-by-label decision and zero NSCLC decisions. These comparisons concern visualization on a fixed partition. Linear Cartesian axes are the supported coordinate space. For variable-density embeddings, inspect component count, overlap and omissions before reusing paths.

[Benchmark methods, timings and memory](https://github.com/nbatada/ggclusteroutline/blob/v0.1.1/benchmarks/rc/README.md) · [Full PBMC comparison PDF](https://github.com/nbatada/ggclusteroutline/blob/v0.1.1/benchmarks/rc/pbmc700.pdf) · [Research audit](https://github.com/nbatada/ggclusteroutline/blob/v0.1.1/AUDIT.md) · [MIT license](https://github.com/nbatada/ggclusteroutline/blob/v0.1.1/LICENSE.md)
