# Product specification v0.1 (proposed, not implemented)
API goal:
```r
library(ggclusteroutline)
ggplot(df, aes(UMAP1, UMAP2, color = leiden)) +
  geom_point(size = 0.2) +
  geom_cluster_outline(aes(group = leiden))
```
Selected clusters, independent group mapping, facets, consistent outlines across gene-expression plots, and precomputed geometry are mandatory design cases. The above API is aspirational.
Data: x/y numeric finite coordinates and group labels. No Scanpy/Seurat dependency. Preserve NA policy explicitly; warn or error where needed. Group IDs must not be parsed from display labels.
Geometry: handle one point, two points, collinear points, duplicates, unequal densities, rare groups, holes, disconnected components, interleaving/overlap, outliers, and missing values. Avoid bridging disconnected islands. Allow true overlap; do not fabricate separation. Document whether displayed outline covers all or representative cells. No implicit confidence interpretation.
Rendering: line only by default; restrained fill optional; color inheritance and overrides; legends, scales, faceting, coord_fixed, coord_flip, coordinate transformations, resizing, SVG/PDF/PNG. Device-dependent padding must be explicit and tested.
Scaling: distinguish N points from K groups; lazy selected-group work; deterministic simplification; profile compute and render separately; don't promise O(N) without measurement.
Cache: geometry only; keyed by ordered/normalized coordinates, group membership, relevant parameters, algorithm/version, and any coordinate-space assumptions; never reuse on invalidated data. Cache overhead must be benchmarked. Optional memory/disk storage; bound size and allow clear.
Labels (later): robust inside-region anchors, multi-island decisions, collision handling, optional leader lines and manual overrides; don't duplicate ggrepel without demonstrated need.
