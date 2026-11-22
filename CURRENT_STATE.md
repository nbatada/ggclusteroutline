# Current state · 22 November 2026

The published v0.1.0 audit found silent pooling of cells across facets, truncated near-vertical segments, reordered frozen paths and incomplete territory diagnostics. The scientist authorized a local v0.1.1 patch and repeat release audit. See the [patch ticket](tickets/M1-002.md), [original audit](release/RELEASE_AUDIT_v0.1.0.md) and [decision D014](DECISIONS.md).

The original PBMC gate requires two cluster-4 polygons enclosing all 48 assigned members and zero others. The full Yost and NSCLC checks use their original labels, coordinates and reference territory settings. The scientist owns visual acceptance and release approval.

**Local v0.1.1 candidate verified.** The source archive passed full R CMD check with zero errors, warnings or notes. The repeated full-data audit matched both published territory totals and independently verified other-label inclusion for every label. See the [v0.1.1 audit and measured performance](release/RELEASE_AUDIT_v0.1.1.md). Scientist approval and cross-platform release CI remain pending.

The revised v0.1.1 candidate defaults to territory. A fresh archive passed all seven package test scripts and full R CMD check. The one-line layer drew 22/23 Yost groups and 13/18 NSCLC groups.
