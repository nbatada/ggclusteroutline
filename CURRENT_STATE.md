# Current state — 2026-11-22
Status: concept and initial official-documentation scan. No code, benchmarks, test results, name availability check, or verified GitHub repository created.
Decisions: standalone R-first package candidate `ggclusteroutline` (name provisional); ggplot2-native interface; P0 outlines, P1 scaling/caching, P2 labels; Python later pending R evidence.
Verified prior art (documentation only): ggforce geom_mark_hull uses concaveman and computes hull at draw time; ggalt geom_encircle encloses point sets; ggdensity geom_hdr_lines draws highest-density contours. These are real competing features. No systematic runtime or visual comparison performed.
Next: CodexStrategy performs M0 and presents comparative report with actual rendered figures and evidence. Await scientist GO before implementing.
