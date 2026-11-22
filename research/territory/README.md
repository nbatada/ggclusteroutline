# Territory architecture review · 22 November 2026

**Reuse the native R geometry as an opt-in estimate of a locally enriched region. Evaluate a separate tight-band rendering for the scientist-selected all-member display.** Two paths and perfect membership counts can still produce visibly loose bands.

## Replayed on the project's split-island fixture

All 700 cells competed on the saved UMAP. The same 48 cells always defined Leiden 4. The reference produced identical vertex coordinates for cluster 4 whether requested alone or as part of the all-cluster output. Areas below are in squared UMAP units. [Source and settings](check-reference.R) · [results](pbmc-reference.csv) · [accepted visual target](../leiden-reference/full-umap-bands.pdf)

| Geometry | Rings | Member centres enclosed | Other centres enclosed | Total area |
|---|---:|---:|---:|---:|
| Manually separated convex bands, existing project fixture | 2 | 48/48 | 0 | 1.579 |
| CellStyle territory, default geometry parameters | 2 | 48/48 | 0 | 15.596 |
| CellStyle territory, NSCLC geometry parameters | 2 | 48/48 | 0 | 5.325 |

The tighter territory profile still encloses 3.37 times the area of the two rubber bands. This is a favorable, deliberately chosen split example. It tests component recovery and tightness, not frequency of success across clusters.

## What the reference computes

The R and Python entry points offer independent density contours by default. Territory is a separate method. On a shared padded square grid they bin each eligible label's cells at the nearest node and smooth counts using a separable Gaussian truncated at four bandwidths. At each node the greatest absolute smoothed cell count wins; deterministic string order breaks exact ties. A label also has to meet its own cumulative density-mass cutoff. A second Gaussian pass on the resulting binary mask (one-node sigma, radius three) and contour level 0.75 inset the paths. Multiple rings and holes are possible. Mass controls estimated support before competition and inset. It does not prescribe observed coverage. Small populations compete against more abundant neighbours; local plurality can be below 50%.

CellStyle already has a base-R implementation using tabulate, matrix shifts and grDevices::contourLines. Both versions skip groups with insufficient 2D support. The R wrapper rejects automatic faceting. Python raises on an open path while R warns and skips it; path numbering also differs between backends. Use topology and membership comparisons for parity. Keep labels, points, facet keys and geometry statuses explicit.

## Transfer evidence

The upstream NSCLC record reports 395,316/622,791 cells within their own territory (63.5%), 193,288 only in another territory, and four of 18 labels without bands. Independent density at the **same** bandwidth/mass/grid enclosed 611,028 own members, with 558,152 cell centres in multiple bands. Territory had zero multiply covered centres. In the Yost BCC transfer, all 23 groups had a band, 22,515/33,106 cells (68.0%) were inside their own territory, and R/Python differed on one of 761,438 cell-by-group containment decisions. These are upstream full-data records; this review independently replayed only PBMC. Neither dataset supplies timing or peak-memory qualification for the proposed engine. A zero count at observed centres does not establish that polygon interiors never intersect.

Sources in the sibling CellStyle repository: `r/cellstyle/R/cluster-outlines.R`, `src/cellstyle/outlines.py`, their cluster-outline tests, and `design_evidence/{nsclc-tnk-bands,yost-bcc-tcell-bands}/`. The inspected files are working-tree material. HEAD ea3c201a7e00e4ce8c823abe8ff3fa9a4ffd01de alone does not identify them. SHA-256 for R: 8e481b590cbef9fe37d08dbe8d5aa943e2fbd67bc53d5bc354d6b3d3397ccd34. Python: fe91e61bc298ac8a9ee1babb8c8508d740726401ac253b6492ca092fa7c38ac9. Preserve CellStyle's MIT copyright and license notice for any adapted code. The initial transfer should bring the geometry contract, reference behaviour and small reproducible tests into ggclusteroutline. CellStyle keeps its public API, Python implementation, visual styling and existing implementation. No dependency reversal is needed.

A separate read-only reviewer checked the interpretation and the limits of the earlier scaling evidence. The CellStyle geometry files are untracked in that checkout; freeze an attributed reference snapshot before implementation. No timings for territory were collected in this review.
