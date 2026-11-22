# Roadmap and gates
M0 — Competitive audit complete. The scientist selected full-UMAP, island-wise tight bands (D010). The [territory review](research/territory/README.md) supersedes the convex-only proposal as the recommended next experiment.

**M1a · proposed, requires explicit GO.** First freeze the existing CellStyle native R behaviour as a reference. Input is the whole PBMC fixture, with its saved labels; request cluster 4. Check both reference profiles, then test territory as an island seed for tight bands of the original cell centres. Output is geometry, membership diagnostics and the labelled full-UMAP comparison against the two manual hulls. Stop if the split requires a manual threshold, drops members, or fails the [tightness and topology gates](specs/ACCEPTANCE.md). Exclude package API changes, large-data optimization and CellStyle edits from this first ticket.

M1b — After a successful feasibility review, implement a separate native R engine and ggplot2 adapter with explicit tight-band and territory meanings, group diagnostics, full-panel competition, facet keys and reusable data-space paths. Preserve the CellStyle API and backends.

M2 — Stress-test rare and interleaved populations, holes, nonfinite and degenerate inputs, grid ties, bandwidth sensitivity, and coverage. Obtain scientist review on the full embedding before designating an automatic default.

M3 — Index rows by group and compute grid-bin indices once per facet, avoiding the reference R implementation's repeated full-table scans. Stream one count surface at a time through separable smoothing; maintain only the best score and winning group per node. Retain selected surfaces within a memory budget, or recompute them in a second pass for all-group output. This bounds dense working storage near O(G²) for a G-by-G grid in the two-pass design, excluding indexed observations and emitted vertices. Each valid competing group still incurs grid smoothing, and support cutoffs require an order statistic weighted by density mass. Start with native R and grDevices contouring. Consider compiled smoothing or threshold selection only if profiling identifies a bottleneck. Measure cold/reused costs and validate cache invalidation for every competing label.

M4 — Labels (approval required): boundary-aware positions, collision/leader lines, tiny/too-many groups; reuse established label engines if sufficient.
M5 — Release hardening (approval required): R CMD check, package docs, CRAN policies, CI, portability, examples, licensing, performance, visual snapshots; no public release without scientist authorization.
M6 — Python (separate decision): Scanpy/Matplotlib or plotnine adapter using validated geometry contract, only if justified.
At each milestone: report evidence, failures, regressions, unresolved decisions, commit hash, and next smallest ticket.

## 0.1.0 release-candidate status

The subsequent scientist GO authorized M1a, M1b and the local release-preparation portions of M2/M3/M5. The automatic M1a gate passed. Current scope, measured limits, compatibility and publication decision are tracked in [current state](CURRENT_STATE.md) and the [RC evidence](benchmarks/rc/README.md). Public release, labels, persistent caches and a Python implementation remain separately gated.
