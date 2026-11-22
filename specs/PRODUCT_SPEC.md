# Proposed product specification v0.2 · M0 decision draft

## Smallest useful task

Given a table of finite 2D coordinates, a group column and a continuous measurement, draw all points coloured by the measurement. Select one or more named groups for an outline. Reuse the exact same outline when the measurement changes. The overlay describes the supplied embedding and labels. Group identity and cell membership come from the input.

The manual baseline already works. Filter the outline layer's data to the desired groups, use a fixed line colour, and add a ggforce mark, a closed base convex hull or a ggdensity contour. The proposed reason for a thin R interface is to make coverage, degenerate cases and reuse reliable across figures. Scientist acceptance of that added value is pending.

## Proposed R interface

```r
ggplot(df, aes(UMAP1, UMAP2)) +
  geom_point(aes(colour = expression)) +
  geom_cluster_outline(aes(group = leiden), data = subset(df, leiden %in% chosen))
```

Aspirational API. Use ggplot2's layer-data selection for named groups. Keep position and group mapping explicit when continuous colour is inherited from the plot. Default to a single fixed stroke, no fill or guide. Honour a deliberately mapped outline aesthetic that is constant within the supplied group. Reject ambiguity rather than splitting a biological group by point colour.

**Proposed default for a bounded M1.** An all-observation convex envelope per supplied group, computed in data space. One finite unique position gets a point marker. Two or more collinear positions get the segment joining the extremes. Three or more non-collinear positions get a closed polygon. Convex coverage includes empty space between same-label islands. A caller with known component identifiers may partition the supplied group explicitly before drawing. Never infer or discard a component in this mode. The default is appropriate only if the scientist accepts the illustrated tradeoff. If an automatic multi-island outline is essential to the first release, keep M1 closed.

**Representative regions.** A separately named, opt-in density mode is a later proposal. A requested probability refers to estimated density mass. Report bandwidth, grid extent, resolution, level, and excluded or undrawable groups. Keep all original observations in the point layer. The number of observed points inside a contour can differ from its probability level. Do not switch from full enclosure to density automatically.

## Coordinates, facets and reuse

- In M1, support linear Cartesian scales and Cartesian zoom, equal aspect, and axis flip. Reject unsupported nonlinear scales and coordinates with a diagnostic until their input/transform order is tested. Scale-limit censoring before geometry needs a documented policy. Use Cartesian zoom for cropping a completed outline.
- Preserve original group keys (including character strings and factor labels) and facet keys through precomputation. ggplot2's integer group and PANEL codes are local to a build. Separate observations with the same group label in different panels. Require facet variables or explicit replication intent for an independently supplied layer table.
- Require finite coordinates and nonmissing group keys. Default to a diagnostic naming the affected rows/counts. An explicitly requested omission policy must report counts per panel/group and leave the input and point layer intact. Duplicate positions may be collapsed for geometry only. Keep original row counts for diagnostics.
- Proposed reusable representation is a table of facet keys, original group key, component and ring IDs, hole flag, geometry type, vertex order, x and y, plus method, parameters, coordinate-space and version metadata. Store closure explicitly for rings. Allow points and segments as first-class results. Draw precomputed geometry as a separate layer. Store physical stroke width as styling. Physical padding would need separate draw-time treatment.
- Later cache work must include membership, positions, facet/component keys, method/version, all resolved parameters, missingness policy, grid/domain and coordinate assumptions in the key. Canonicalize row permutations or document cache misses on reordering. Preserve duplicate weights for density. Ignore expression colour and line styling for data-space geometry. Measure hashing cost before adding automatic storage. An explicit precomputed object addresses reuse first.

## Scope and dependencies

Prefer ggplot2's public layer/Stat/Geom contracts, grDevices for convex hulls, and ordinary path, point and segment rendering. M0 selected no new geometry dependency. Keep optional density work contingent on comparison with calling ggdensity directly. Exclude labels, disk caching, Seurat/Scanpy dependencies, smoothing, automatic island detection and a Python adapter from M1. Contrast true overlap and distinct components in documentation. [Acceptance gates](ACCEPTANCE.md) · [audit](../AUDIT.md)
