# Proposed product specification v0.3 · M0 decision draft

## Smallest useful task

Given a table of finite 2D coordinates, a group column and a continuous measurement, draw all points coloured by the measurement. Select one or more named groups for an outline. Reuse the exact same outline when the measurement changes. The overlay describes the supplied embedding and labels. Group identity and cell membership come from the input.

The manual baseline already works. Filter the outline layer's data to the desired groups, use a fixed line colour, and add a ggforce mark, a closed base convex hull or a ggdensity contour. The proposed reason for a thin R interface is to make coverage, degenerate cases and reuse reliable across figures. Scientist acceptance of that added value is pending.

## Proposed R interface

```r
ggplot(df, aes(UMAP1, UMAP2)) +
  geom_point(aes(colour = expression)) +
  geom_cluster_outline(aes(group = leiden), clusters = chosen)
```

Proposed API. Supply the full embedding to the layer. Select output labels with `clusters`. Keep the original label values and facet keys. Each facet defines its own full competition domain. Keep marker values and display aesthetics outside the geometry inputs. Display the full labelled Leiden reference beside the full expression UMAP.

**Tight bands (scientist-selected visual target).** Each supported spatial island of a selected label receives one taut all-member envelope. If component membership is supplied, use it directly. For the first automatic feasibility test, use territory rings as candidate island seeds and compare component-wise convex hulls of the original member coordinates with the manual two-band reference. Never draw the inset territory itself as an all-member enclosure. Count each selected member exactly once. If a ring lacks support, a member lies outside every candidate, or assignments are ambiguous, report that condition and leave automatic geometry unresolved. A later assignment rule needs separate validation on outliers, rare islands and interleaving. Different labels’ all-member envelopes may overlap.

**Territory (explicit opt-in).** Estimate the locally dominant part of each label's smoothed density support using every eligible label as a competitor. Return all supported rings, including interior holes. Report absent support, empirical member coverage and inclusion of other labels. Keep all observations visible. A minority population may lack a territory. Do not substitute an enclosing polygon on failure. The reference profiles are benchmark settings, not accepted universal defaults.

## Coordinates, facets and reuse

- In M1, support linear Cartesian scales and Cartesian zoom, equal aspect, and axis flip. Reject unsupported nonlinear scales and coordinates with a diagnostic until their input/transform order is tested. Scale-limit censoring before geometry needs a documented policy. Use Cartesian zoom for cropping a completed outline.
- Preserve original group keys (including character strings and factor labels) and facet keys through precomputation. ggplot2's integer group and PANEL codes are local to a build. Separate observations with the same group label in different panels. Require facet variables or explicit replication intent for an independently supplied layer table.
- Require finite coordinates and nonmissing group keys. Default to a diagnostic naming the affected rows/counts. An explicitly requested omission policy must report counts per panel/group and leave the input and point layer intact. Duplicate positions may be collapsed for hull computation. Retain count multiplicity in territory densities. Keep original row counts for diagnostics.
- Proposed reusable representation is a table of facet keys, original group key, component and ring IDs, hole flag, geometry type, vertex order, x and y, plus method, parameters, coordinate-space and version metadata. Store closure explicitly for rings. Allow points and segments as first-class results. Draw precomputed geometry as a separate layer. Store physical stroke width as styling. Physical padding would need separate draw-time treatment.
- Later cache work must include membership, positions, facet/component keys, method/version, all resolved parameters, missingness policy, grid/domain and coordinate assumptions in the key. Canonicalize row permutations or document cache misses on reordering. Preserve duplicate weights for density. Ignore expression colour and line styling for data-space geometry. Measure hashing cost before adding automatic storage. An explicit precomputed object addresses reuse first.

## Scope and dependencies

Use an engine independent of ggplot2 that accepts original keys, numeric coordinates, requested output IDs and a geometry mode. Return ordered paths plus per-group status and resolved settings. A ggplot2 adapter renders those outputs and handles facets. Compute territory with the full panel present even when one outline is requested. For caching, any competitor membership or coordinate change invalidates the panel territory; changing marker colour does not. Start with explicit precomputation. Defer persistent caching, labels and Python integration. [Engineering sequence](../ROADMAP.md) · [acceptance gates](ACCEPTANCE.md) · [territory evaluation](../research/territory/README.md)

## v0.1.0 release-candidate choices

The default remains the strict territory-seeded tight method. When territory support leaves even one member ambiguous, the layer warns and the precompute result records an unresolved status. Benchmarking showed this can occur even for a large Gaussian cloud. The explicit `islands` alternative therefore draws all-member hulls of 8-neighbour connected occupied tiles within each label, including point and line fallbacks. The public dbscan routine on tile centres (minimum one tile) supplies the established connectivity algorithm. Changing tile width changes the geometric partition. It never changes biological cluster IDs. No automatic fallback changes the chosen method. A supplied component column also bypasses inference. Release qualification applies only to the benchmark inputs and platforms listed in the release record.
