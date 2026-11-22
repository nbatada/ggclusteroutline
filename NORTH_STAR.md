# NORTH STAR — ggclusteroutline
## Mission
Deliver a tiny, robust, fast R/ggplot2 extension that automatically draws beautiful, readable outlines around labeled point clusters in UMAP, t-SNE, PCA, and general 2D scatterplots. One-line use; no geometry expertise required. Make this a useful open-source contribution with genuine demonstrated advantages over existing ggplot extensions.
## Why this exists
Scientists need to show the position of selected Leiden or annotated clusters independently of color mappings (e.g. gene expression or condition). Existing options can be awkward or misleading for irregular, disconnected, sparse, overlapping and outlier-rich populations. We must verify which gaps are real before building.
## Product promise
A native-feeling `geom_cluster_outline(aes(group=...))` layer. All or selected groups; sensible automatic geometry; stable reproducible output; honest visual interpretation; scalable point/cluster counts; optional precomputed geometry/cache. Boundary-aware labels are phase 2.
## Priorities
P0 outline correctness and publication-quality visuals. P1 performance, scalable geometry and valid caching designed from outset. P2 labels. P3 Python only after R engine/API is validated; design portable geometry contract now, avoid premature dual-language implementation.
## Non-negotiable
No claim of algorithm novelty without prior-art audit. No invented biological boundaries. No silent cell deletion, reclustering or relabeling. Disconnected regions and tiny clusters require explicit handling. Overlap is permitted when populations overlap. Deterministic results; vector export; reproducible benchmarks; graceful failure. Scientist approves comparative visual evidence.
## First authorized task
M0 competitive audit, feasibility and benchmark design; STOP for scientist review before implementation.
