# Release audit · ggclusteroutline v0.1.1 local candidate

**Technical GO on the tested macOS environment.** The patch clears the v0.1.0 facet blocker and the other verified correctness defects. The candidate is ready for scientist review. Public release approval and Windows/Linux verification remain open.

**Artifact.** On 22 November 2026, R 4.5.3 built `ggclusteroutline_0.1.1.tar.gz`. SHA-256 is `c9b121cf1252b81c9b5d77ddd5216b1030dd175b89c9c793d5bdbc47c19005db`. A fresh R process confirmed the package was absent, then installed the archive in an empty target library. The test environment used isolated dependencies and disabled the site library. The earlier candidate also passed the README checkout installation with pak. [Checksum](SHA256SUMS-v0.1.1)

## Updated one-line default

The omitted method now selects territory in both the live layer and precomputation. The rendered one-line layer drew one contour on the compact 400-cell fixture, 22/23 groups on the full Yost embedding and 13/18 on NSCLC. It produced two territories for PBMC cluster 4. The original two all-member hulls remain available with explicit tight mode. Supplying a component column retains the existing component-hull behavior. A regression test compares the default layer's actual vertices to explicit territory and confirms strict tight still abstains on the same Gaussian. [Full-map comparison](../research/default-review/default-comparison.png)

## Corrections verified

| v0.1.0 finding | v0.1.1 evidence |
|---|---|
| Separate computed layer silently pooled panels | Keyed panels returned x ranges 0–2 and 10–12. Missing keys produced an error for either order of adding the layer and facets. Setting `replicate = TRUE` explicitly returned 0–12 in both. Tests also covered a key supplied only by another layer, partial keys, functions returning layer data, and expressions with an external parameter. |
| Near-vertical segment missed its highest member | For the three-point fixture spanning y = 0–1, tight and single-tile islands returned endpoints spanning the full range. Independent projection onto the segment agreed with the assigned count of three. |
| Reordering frozen rows produced a self-crossing path | The shuffled square retained area 1. A v0.1.0 RDS loaded with v0.1.1 recovered its original vertex sequence. Invalid orders and open polygons were rejected. Distinct facet tuples containing separator characters kept separate paths. |
| Territory diagnostics omitted other labels | The overlap fixture returned 369 enclosed A cells and 41 enclosed B cells. Independent point-in-polygon counts agreed. Each label on the two full atlases also agreed with the independent benchmark classifier. |
| Frozen geometry lacked source identity | RDS retained the coordinate space, geometry column names, package and runtime versions, and source SHA-256. Changing the facet membership changed the fingerprint. Changing expression alone preserved it. |
| Method choice, styling and release instructions were unclear | The README now documents default yield, potential tile fragmentation, fixed outline styling, coordinate overrides, facet replication and Cartesian zoom. It gives separate installation routes for the patch checkout and source archive, plus a link to the published v0.1.0 release. |

## Release checks

- **Package.** Full `R CMD check` on the final archive completed with 0 errors, 0 warnings and 0 notes. All seven test scripts, Rd examples, dependency and namespace checks, and the PDF manual passed. The archive contains the MIT and CellStyle notices and the example data attribution. The patch adds no dependency. [Full check log](R-CMD-check-v0.1.1.txt)
- **Compatibility.** Native ggplot2 tests ran on 3.5.0, 3.5.2, 4.0.3 and 4.0.4. Seurat 5.5.1 with SeuratObject 5.4.0 ran on the latter three versions. Its dependency stack requires ggplot2 ≥3.5.2, so the Seurat test skipped on 3.5.0. A separate split DimPlot retained the original colours and all 700 points across both facets. The README plots produced four PDF pages, and the territory diagnostics example executed.
- **Geometry.** The full PBMC reference recovered both cluster-4 hulls, 48/48 members, zero other cells and combined area 1.578884. On separate synthetic fixtures, the tight method covered 80/80 compact members and 8/8 disconnected members in two polygons. It warned and abstained on the overlapping and sparse fixtures. Occupied islands covered all 100 overlapping and all seven sparse members, including a segment and a singleton. Territory covered 50/100 overlapping members.
- **Reuse.** The cache tests exercised marker reuse, coordinate/competitor/parameter invalidation, bounded eviction and clearing. Two fresh R processes returned identical serialized-result hashes for all three methods on PBMC cluster 4. The atlas cache hits also returned identical objects to cold computation.
- **Independent review.** A separate fresh installation passed targeted checks of panel membership, external facet parameters, shuffled frozen paths, source fingerprints and territory counts. The scientist retains visual acceptance.

## Full-data replay

The replay verified the original compressed input hashes and unique IDs before computing territory geometry on every cell. The grid, bandwidth and mass matched the pinned v0.1.0 profile. All own-member and other-label counts agreed with separate classification of the returned polygons, label by label. Comparison to stored CellStyle paths reproduced the single Yost classification difference and zero NSCLC differences.

| Full embedding | Cells | Labels drawn by territory | Own / other-label inclusions | Cold / cached geometry |
|---|---:|---:|---:|---:|
| Yost | 33,106 | 23/23 | 22,515 / 8,854 | 0.572 / 0.006 s |
| NSCLC | 622,791 | 14/18 | 395,316 / 193,288 | 1.513 / 0.081 s |

Times are single local runs. Rendering retained all points. Explicit tight mode warned and produced 0/23 and 0/18 groups. Occupied islands drew 23/23 and 18/18. These outcomes are documented method choices. On the preceding candidate’s separate 100,000-point, 100-component overhead test, median geometry plus build and draw was 0.445 s versus 0.360 s for direct base hulls across three repeats. Median peak RSS was 230 versus 224 MiB. Both ratios passed the proposed 2× budget for supplied components.

**Next action.** Submit the local candidate for scientist review, then run release CI on the approved source before publication.
