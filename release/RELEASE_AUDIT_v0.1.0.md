# Independent release audit of ggclusteroutline v0.1.0

**NO-GO for general-purpose recommendation of v0.1.0.** The installed package can draw useful, reusable outlines, including the intended split PBMC cluster. The principal correctness blocker is silent cross-panel duplication when an independent layer table lacks the facet key. The strict default is also a poor first experience on real embeddings. This verdict applies to the published tag and source archive only.

## Release identity and independence

GitHub's annotated tag object was `0dab90cf610cb148cd06d48859356ddc64e3c9b7`, peeled commit `f682da708857f3901a008b763939e93159fdab84`. The [official release](https://github.com/nbatada/ggclusteroutline/releases/tag/v0.1.0) source archive was downloaded independently. Its SHA-256 was `27fe49f3ae7085a421d717608d381b9dff262883cc5b8848bc40072d50ba32fa`, matching the published digest and tagged checksum. The archive's R sources, tests, installed data, README and man pages matched the tag export. All executions used scratch installations of the tag or verified published archive. Prior benchmark timings and reported test verdicts were excluded from this assessment.

## Findings

**BLOCKER — Live outlines can silently pool cells across facets.** With points for two visits separated by ten x units, an independent outline data frame containing x, y and identity but missing visit was accepted. In *each* visit panel the computed overlay spanned x = −1.260451 through 11.360121. Both visits' hulls appeared on each panel. Normal ggplot layers can intentionally repeat across facets; this package's own specification requires the facet keys or explicit replication intent for independent data. The frozen path layer checks matching facet keys, while the live stat sees data only after ggplot has replicated the rows. This can silently attach the other visit's evidence to a panel. [Live/frozen layer code](https://github.com/nbatada/ggclusteroutline/blob/f682da708857f3901a008b763939e93159fdab84/R/layer.R#L12)

```r
library(ggplot2)
library(ggclusteroutline)
set.seed(293)
a <- data.frame(x = rnorm(400, 0, .4), y = rnorm(400, 0, .4), id = "A")
d <- rbind(transform(a, visit = "pre"), transform(a, x = x + 10, visit = "post"))
p <- ggplot(d, aes(x, y)) + geom_point() + facet_wrap(~visit)
b <- ggplot_build(p + geom_cluster_outline(aes(group = id),
  data = d[c("x", "y", "id")], method = "islands"))
aggregate(x ~ PANEL, b$data[[2]], range)
```

**IMPORTANT — The one-line default abstains on ordinary data.** With no geometry arguments, `tight` produced zero outlines for one compact 400-cell Gaussian cluster, zero of two well-separated Gaussian clusters, zero of 23 Yost groups, and zero of 18 NSCLC groups. These were explicit warning outcomes. The code intentionally drops an entire group when even one member lacks exactly one seed ring. This satisfies the strict abstention contract but defeats the headline use case on both large examples. The bundled PBMC cluster 4 success is genuine. Show default drawn/requested counts prominently, make method choice explicit on first use, and test any proposed new default against these data. [Decision point](https://github.com/nbatada/ggclusteroutline/blob/f682da708857f3901a008b763939e93159fdab84/R/geometry.R#L256)

**IMPORTANT — Frozen paths draw in physical row order despite storing vertex order.** On a square, retaining all five vertices and the original `vertex` IDs but reordering rows to 1,3,2,4,5 yielded a self-crossing path. The absolute shoelace area of the rendered coordinates changed from 1 to 0. A plain saveRDS/readRDS round-trip passed. The failure affects reordered frozen tables, for example after a join or sort. Sort by facet, cluster, path and vertex, or reject out-of-order/incomplete rings. [Frozen layer](https://github.com/nbatada/ggclusteroutline/blob/f682da708857f3901a008b763939e93159fdab84/R/layer.R#L175)

```r
d <- data.frame(x = c(0,1,1,0), y = c(0,0,1,1), id = "A")
v <- compute_cluster_outlines(d, "x", "y", "id", component = "id")
ggplot(d, aes(x,y)) + geom_point() +
  geom_cluster_outline(data = v[c(1,3,2,4,5), ])
```

**IMPORTANT — Territory diagnostics omit other-label inclusion.** The specification asks for empirical member coverage *and* inclusion of other labels. The installed diagnostics report input, assigned and unresolved member counts plus path counts. They do not tell the user how many other-label centers are inside the returned region. That makes purity impossible to read from the public diagnostic alone. The benchmark scripts compute it separately. [Diagnostics](https://github.com/nbatada/ggclusteroutline/blob/f682da708857f3901a008b763939e93159fdab84/R/geometry.R#L245)

**MINOR — Aesthetic mapping is narrower than a general ggplot geom.** Explicit `aes(colour=id)` and `aes(linetype=id)` each produced the fixed default for both groups in a two-group probe. A fixed colour argument works. Global x/y mappings also take precedence over overrides on a point layer: in a probe with a 100-unit global offset and unshifted points, the outline followed the global offset. The former is consistent with the manual's fixed-style API and the latter with global ggplot inheritance. Clarify both in the README and show explicit x/y on the outline when a point layer overrides them.

**MINOR — Release-facing instructions still describe a local candidate.** The tag README says “Install the release candidate”, NEWS calls it an initial local candidate and the release procedure describes pending publication. Installation worked. Provide a pinned GitHub or release-asset installation command and distinguish strict default results from territory benchmarks. The MIT declaration, copyright-holder file, full repository license and bundled CellStyle attribution were present. Declared imports and optional packages passed package checks on the tested host.

## Executed release gates

| Gate | Independent observation |
|---|---|
| Clean install | Fresh empty package library, vanilla R, no user profile. The published tarball installed successfully with its dependency closure available from locally installed packages. This tests a clean package installation on macOS, not fetching all dependencies on a virgin OS. |
| R CMD check | Full check including the PDF manual, examples and seven test scripts finished with **Status: OK** for both a fresh tag build and the official tarball on macOS arm64, R 4.5.3. No check errors, warnings or notes. The offline dependency phase emitted network-index access messages. Windows/Linux were not independently tested. |
| Native ggplot2 | Basic one/all-group builds, correctly keyed live facets and frozen facet reuse passed. Unsupported log scales produced a warning and an empty computed layer. Explicit fixed outline styling retained underlying point colours. See the facet and frozen-order findings above. |
| Seurat | An actual Seurat object with a saved DimReduc and 700 PBMC coordinates supported the README DimPlot call. An independent split.by plot built and rendered. The integration fixture used placeholder counts; the embedding and stored IDs determine this test. |
| Shape correctness | Independently checked compact groups, separated and overlapping normals, singleton/duplicate/collinear points, two clouds of one label, a ring, and the shipped PBMC fixture. On PBMC 4, strict default returned two polygons covering all 48 members and zero other cell centers. A single-coordinate group and a line yielded the expected point/segment in tight mode. Territory preserved the hole of the synthetic annulus; convex envelopes filled it. The islands mode covered all members but fragmented one 400-point Gaussian into 21 paths at defaults. |
| Large datasets | The full Yost and NSCLC tables were used without downsampling. See the timed runs below. |
| Cache | A new process-local cache ignored marker-only edits. Coordinate, competitor and mass changes created new cache entries, and cached geometry agreed with cold recomputation. Moving competitors onto a selected group changed its result. Sixteen-entry and 16 MiB bounds held in the eviction probe. A changed key can legitimately yield the same path after binning. |
| Determinism | Repeated cold computations were identical for all three modes on the selected PBMC fixture. Shuffling rows preserved their unique vertex sets. On the two full datasets the cold territory and cached results were identical. These checks establish the tested behavior, not invariance of arbitrary edited frozen tables. |
| README | Executed the plotting, actual Seurat and frozen/readRDS R blocks against the installed package. Supplied the Seurat object assumed by the README. Used the documented source-install alternative; the optional network-dependent pak bootstrap was not tested. |
| License, dependencies, docs and notes | DESCRIPTION, NAMESPACE, LICENSE, LICENSE.md, upstream license, Rd pages, NEWS, release notes and checksum inspected; Rd, dependencies, examples and installed loading checked. Candidate wording remains stale. No legal or cross-platform certification is implied. |

### Measured performance

Territory settings followed the release's real-data profile: 256 nodes per axis, 97% mass, bandwidth 1.2% of full coordinate span. Default tight was tested separately with ordinary default arguments. Times below are seconds on this Mac, single measured runs, not multi-platform performance guarantees. Cold geometry excludes input loading; build includes computation and all points; draw includes gtable construction and rendering to an 800 × 800 PNG.

| Data | Cells | Territory drawn/requested | Cold territory | Cache hit | Cold ggplot build | Draw | Default tight drawn |
|---|---:|---:|---:|---:|---:|---:|---:|
| Yost | 33,106 | 23/23 | 0.458 | 0.004 | 0.512 | 0.100 | 0/23 |
| NSCLC | 622,791 | 14/18 | 1.018 | 0.076 | 1.204 | 1.436 | 0/18 |

## Independent follow-up on the additional findings

The follow-up rechecked the published archive's SHA-256 and installed it in a fresh temporary library. The probes used R 4.5.3 and ggplot2 4.0.3. The original NO-GO stands.

| Severity | Probe | Observed result |
|---|---|---|
| IMPORTANT | Freeze a unit square, then reorder its five rows to 1, 3, 2, 4, 5 while preserving each vertex ID. Build the plot and its grob. | Both plots built without a warning. The original path enclosed one square unit. The shuffled path crossed itself and its absolute shoelace area fell to zero. |
| IMPORTANT | Compute the territory of A in overlapping groups and independently classify every cell centre against the returned ring. | The ring contained 369 of 400 A cells and 41 of 60 B cells. The public diagnostics reported 369 assigned and 31 unresolved A cells. They omitted the 41 enclosed B cells requested by the territory specification. |
| IMPORTANT | Use the strict default on a compact Gaussian cloud of 400 cells, then on that cloud and a copy shifted by 10 units. | The single cloud had 31 unresolved members. The two separated clouds had six and five unresolved members. The package warned and returned zero paths in both runs. Default islands mode drew 21 paths for the single cloud. |
| MINOR | Map both colour and linetype to group on the outline. Separately, put a 100-unit x offset in the global mapping and override x on the point layer. | Both outline groups used the fixed colour `#C23B22` and linetype 1. In the offset test, point x ranged from −1.260 to 11.360 and outline x from 98.740 to 111.360. Document fixed styling and show explicit outline coordinates when points override the global mapping. |

For the Gaussian probes, use `set.seed(293)` and draw x and y successively with `rnorm(400, 0, 0.4)`. For the territory count, use the original cloud as A and its first 60 rows shifted by +0.3 on x as B. Request only A with `method = "territory"` and classify centres with `sp::point.in.polygon`.

## Recommended fixes for v0.1.1

1. Reject missing facet keys on independently supplied outline data unless the caller explicitly requests replication. Test keyed and unkeyed tables with both layer/facet addition orders.
2. Fix the near-vertical segment that omitted a member while reporting full coverage. Test containment of every input point against the returned segment and compare it with the diagnostics.
3. Use stored vertex order when drawing frozen paths, or reject invalid order explicitly. Test the shuffled square against the original path.
4. Report the count of enclosed other-label cells for territories. Test it against an independent point-in-polygon count on overlapping labels.
5. Explain default abstention, occupied-island fragmentation, fixed styling and coordinate inheritance in the README. Show default drawn/requested counts alongside the full-data territory examples.
6. Repeat the full release audit on the patch candidate, including clean installation, R CMD check, the regression cases and both full datasets.
