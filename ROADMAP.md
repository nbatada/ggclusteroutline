# Roadmap and gates
M0 — M0-001 evidence delivered for scientist review. Recommended decision is NO-GO M1. [Audit and review figures](AUDIT.md). Original scope: inspect official docs and source, record packages/methods/licensing/maintenance; build adversarial synthetic benchmark datasets and comparative renders (research artifacts only); propose smallest defensible MVP and acceptance thresholds; scientist GO/NO-GO. Do not create production implementation.
M1 — Closed pending explicit scientist GO for the narrowed all-observation wrapper in [specs/PRODUCT_SPEC.md](specs/PRODUCT_SPEC.md). If approved: robust group semantics, all/selected, tiny/degenerate groups, deterministic geometry, vector export; tests and docs.
M2 — Geometry robustness (approval required): irregular shapes, disconnected islands, sparse/overlapping groups, outliers, density-vs-hull selection; CSD visual review and regression tests.
M3 — Scaling and cache (approval required): 1/10/100/1000 groups, 10k/100k/1M+ points; memory and rendering profiles; safe cache keys and invalidation; precompute/reuse.
M4 — Labels (approval required): boundary-aware positions, collision/leader lines, tiny/too-many groups; reuse established label engines if sufficient.
M5 — Release hardening (approval required): R CMD check, package docs, CRAN policies, CI, portability, examples, licensing, performance, visual snapshots; no public release without scientist authorization.
M6 — Python (separate decision): Scanpy/Matplotlib or plotnine adapter using validated geometry contract, only if justified.
At each milestone: report evidence, failures, regressions, unresolved decisions, commit hash, and next smallest ticket.
