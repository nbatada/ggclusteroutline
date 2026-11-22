# Independent release audit of ggclusteroutline v0.1.0

**Recommendation — NO-GO for unrestricted use of v0.1.0.** A faceted plot can silently display cells from other panels in its outline. A separate numerical defect can truncate an all-member segment while reporting complete assignment. Both failures occur in the installed release. The bundled PBMC example and the published territory counts on both large datasets reproduced.

## Release identity and installation

Audited on 22 November 2026. The published GitHub release is final. The remote annotated tag object is `0dab90cf610cb148cd06d48859356ddc64e3c9b7`, pointing to commit `f682da708857f3901a008b763939e93159fdab84`. The downloaded source archive had SHA-256 `27fe49f3ae7085a421d717608d381b9dff262883cc5b8848bc40072d50ba32fa`, matching both the published checksum asset and the checksum in the tag. Every file in the archive matched the tagged source except DESCRIPTION, where R added the four standard packaging fields. All probes used this archive or a fresh export of the same tag. [Published release](https://github.com/nbatada/ggclusteroutline/releases/tag/v0.1.0) · [Audited source](https://github.com/nbatada/ggclusteroutline/tree/f682da708857f3901a008b763939e93159fdab84)

On macOS arm64 with R 4.5.3, the audit created a temporary user library from 147 installed dependencies, including the suggested test and Seurat dependencies. The site library was disabled. Only the temporary library and R's own library were on the search path. A fresh process confirmed the target package was absent before installation. `R CMD INSTALL` installed the downloaded archive and a second process loaded it from the temporary library.

**Full R CMD check — 0 errors, 0 warnings, 0 notes.** The network-enabled run finished with `Status: OK`, including all seven test scripts, Rd examples and PDF manual. The first sandboxed run also finished OK but printed repository-access warnings, so the audit repeated it with network access. Both runs used the published tarball.

## Findings and regression cases

### BLOCKER — a separate layer table without facet keys pools the panels

The specification requires facet keys or explicit replication intent for independently supplied layer data. In two panels containing different locations of label A, the correctly keyed layer returned x ranges 0–2 and 10–12. Removing only the facet column returned 0–12 in **both** panels with zero warnings. Both point panels still displayed their own observations. This can give the wrong impression of where a group occurs in each sample. The existing frozen-path facet guard does not cover this computed-layer case.

```r
library(ggplot2)
library(ggclusteroutline)
d <- data.frame(x = c(0:2, 10:12), y = rep(c(0, 1, 0), 2),
                label = "A", sample = rep(c("left", "right"), each = 3))
p <- ggplot(d, aes(x, y)) + geom_point() + facet_wrap(~sample)
ranges <- function(layer_data) {
  g <- ggplot_build(p + geom_cluster_outline(aes(group = label),
    data = layer_data, method = "islands", bandwidth = 20))
  lapply(split(g$data[[2]]$x, g$data[[2]]$PANEL), range)
}
ranges(d)
ranges(d[c("x", "y", "label")])
```

### IMPORTANT — a nearly vertical segment can omit a member

For three nearly collinear points, the endpoints returned by tight mode have y coordinates 0 and 0.5. The member at y = 1 falls half a unit beyond the segment. The diagnostics report three assigned and zero unresolved. Occupied-island mode with a single occupied tile gives the same result. The collinearity test uses a tolerance, then chooses the segment extremes by x first even when almost all the spread is along y. The input is numerically unusual, but the missing distance is half the cluster's full span.

```r
d <- data.frame(x = c(0, 1e-16, 2e-16), y = c(0, 1, 0.5), g = "A")
for (m in c("tight", "islands")) {
  band <- compute_cluster_outlines(d, "x", "y", "g", method = m, bandwidth = 2)
  print(band[c("x", "y", "type")])
  print(attr(band, "diagnostics"))
}
```

### IMPORTANT — default tight mode drew zero outlines on both full datasets

All three fresh-process trials produced zero tight paths for all 23 Yost labels and all 18 NSCLC labels. The package warned each time, as specified for ambiguous assignments. This is a practical limit on the one-line default. Both large-data successes shown in the release use territory mode. State the observed default yield alongside those examples so readers can choose the coverage they need.

### IMPORTANT — frozen paths lack source identity and engine version

The frozen RDS round-trip preserved the vertices exactly. Inspection of all three methods found method settings and diagnostics, but no source-coordinate or membership fingerprint, coordinate-space identifier or engine version. The README makes the caller responsible for matching the originating embedding. The saved object alone cannot verify that match. Add those identifiers if frozen paths are to support provenance checks across sessions.

### MINOR — release documentation still describes a candidate

The tagged README install heading and NEWS call 0.1.0 a candidate. The tagged release procedure describes publication as pending. The GitHub release page correctly identifies the final release and documents the methods and limitations. The source archive excludes the repository benchmark, research and LICENSE.md paths linked from its README, so those relative links only resolve in the repository. Link to versioned online evidence from the distributed README.

## Compatibility, examples and geometry

- **ggplot2.** Re-ran the shipped scripts with ggplot2 3.5.0, 3.5.2, 4.0.3 and 4.0.4. Native tests exercised computed and frozen paths, facets, layer reuse, coordinate restrictions, PNG export and point glyphs. With 3.5.0 the Seurat test skipped because this host's Seurat stack requires ggplot2 ≥3.5.2. Native support passed at the declared minimum. The host used R 4.5.3 throughout. Windows, Linux and R 4.1 were outside this execution.
- **Seurat.** Built a real Seurat 5.5.1 object using SeuratObject 5.4.0, the bundled 700 saved coordinates and cluster labels, and one placeholder count feature. DimPlot kept all 700 point rows and their original colours after adding two cluster-4 paths. The integration test executed at ggplot2 3.5.2, 4.0.3 and 4.0.4.
- **README.** Executed the three analysis blocks from the tag, supplying the Seurat object the example assumes. Four plots rendered to a four-page PDF with warnings treated as errors. The freeze example saved and reloaded an identical RDS object. Both installation recipes succeeded. The checkout recipe installed pak from CRAN, built the tagged source and resolved the installed package from its separate temporary library.
- **Disconnected PBMC cluster.** Re-ran the tagged PBMC verification script on the installed package. With all 700 cells as input, tight mode returned two polygons around all 48 cluster-4 members and zero of the 652 other cells. Their combined area was 1.578884 and matched the independent manual split within the specified absolute tolerance of 1e-8. The comparator ggforce layer rendered one polygon.
- **Licenses and dependencies.** DESCRIPTION declares MIT + file LICENSE, package authorship, seven imports, four suggests and R ≥4.1.0. The CellStyle MIT license in the archive matched the upstream notice byte for byte. The bundled data notice credits 10x Genomics, identifies CC BY 4.0, links the source and describes the derived coordinates, labels and feature selection. All three exports have help entries. R's dependency, namespace, example, Rd and manual checks passed.

### Independent geometric checks

Directly tested member coordinates against closed polygons and point/segment primitives. The synthetic cases used bandwidth 0.25, mass 0.9 and a 160 × 160 grid. Counts below are selected members covered by the emitted geometry. Zero with abstention means the method emitted no geometry for that label.

| Selected population | Tight | Territory | Occupied islands |
|---|---|---|---|
| Compact, 80 members | 80/80, one polygon | 80/80, one polygon | 80/80, one polygon |
| Overlapping, 100 | Abstained | 50/100, one polygon | 100/100, one polygon and one point |
| Sparse, 7 | Abstained on insufficient island support | 7/7, three polygons | 7/7, one polygon, one segment and one point |
| Disconnected, 8 | 8/8, two polygons | 8/8, two polygons | 8/8, two polygons |

The disconnected tight hulls had combined area 0.08. Zoom, axis flip and point recolouring preserved the tested native layer's data-space paths. SVG export succeeded. A nonlinear position scale produced the documented warning and an empty layer. Position-scale limits that censored 278 rows raised an invalid-coordinate error. The help would be clearer if it directed readers to Cartesian zoom for cropping. Scientist visual acceptance remains separate from the measured containment and rendering results.

## Full-data performance and containment

The audit re-read the two original compressed inputs, checked the SHA-256 digests pinned in the tagged benchmark, verified unique cell IDs and exact row counts, and recomputed all territories. The benchmark used a 256 × 256 grid, mass 0.97 and bandwidth equal to 1.2% of map span with the pinned NSCLC rounding. Cold and cached results were identical. A separate live ggplot build and 720 × 720 Cairo PNG draw retained every point.

| Input | Labels drawn | Members inside own territory | Other-label inclusions across territories | Cold / cached geometry | Peak RSS | ggplot build / draw |
|---|---:|---:|---:|---:|---:|---:|
| Yost BCC, 33,106 cells | 23/23 | 22,515 | 8,854 | 0.704 / 0.005 s | 236 MiB | 0.600 / 0.137 s |
| NSCLC T/NK, 622,791 cells | 14/18 | 395,316 | 193,288 | 1.153 / 0.080 s | 466 MiB | 1.389 / 1.568 s |

These single-run times describe this host. Peak RSS covers the complete benchmark replay, including input reading and all cell-by-label comparisons. Build time includes cold geometry. NSCLC labels 4, 8, 10 and 14 had no supported territory and produced the documented warning. Compared with the saved CellStyle Python paths, one of 761,438 Yost cell-by-label classifications differed and all 11,210,238 NSCLC classifications agreed. The audit classified cells against the stored ggforce polygons and reproduced full own-member coverage for both datasets. Only the small PBMC comparator was rendered afresh. These measurements test the overlays on the supplied embeddings and labels.

A second benchmark ran each method three times per dataset, each time in a fresh process. The table shows median cold / warm geometry time in seconds, including validation and cache hashing. Tight and islands used package defaults. Territory used the published profile above.

| Dataset | Tight | Occupied islands | Territory |
|---|---|---|---|
| Yost | 0.272 / 0.006, 0 groups | 0.099 / 0.005, 23 groups | 0.474 / 0.006, 23 groups |
| NSCLC | 1.016 / 0.077, 0 groups | 0.419 / 0.077, 18 groups | 1.067 / 0.078, 14 groups |

## Cache and reproducibility

- Changing only NKG7 preserved the cache entry and result. A competitor coordinate, competitor label, mass or grid change caused misses. Row permutation also caused the documented miss while preserving PBMC territory geometry. Cartesian zoom reused the entry. The installed cache tests verified the 16-entry limit, estimated storage within 16 MiB on the tested objects, and explicit clearing.
- Two exact-density competitors produced the same winning label after reversing input order. Twenty permutations of a square with duplicate and edge-collinear observations produced the same hull. Frozen paths survived an RDS round-trip.
- Two independent vanilla R processes recomputed PBMC label 4 with caching disabled. The SHA-256 hashes of the serialized full result matched across processes for tight (`9c657ce6…c98744b`), islands (`c58da1fe…98bce244`) and territory (`67db792b…73aed8a`). This establishes repeatability in the tested software environment.

## Next action

Prepare a patch release that rejects missing facet keys on separate computed-layer tables unless replication is explicit. Add regression tests for both keyed and unkeyed input, including facets added after the outline layer. Fix segment endpoint selection along the direction of greatest spread and test containment independently of the diagnostics. Re-run the two reproductions and the full package check before recommending the patch.
