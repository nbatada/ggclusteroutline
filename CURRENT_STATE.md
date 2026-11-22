# Current state · 22 November 2026

**v0.1.0 local release candidate.** The scientist authorized native R implementation and local release preparation. The full-map PBMC feasibility gate passed automatically with two tight hulls, 48/48 own members, zero others, and matching reference area. The package includes a native ggplot2 layer, tested Seurat integration, per-facet paths, small-group glyphs, frozen reuse and a bounded automatic cache.

The full package check passed on macOS, including all seven installed-package test scripts, examples and the PDF manual. CellStyle remained a read-only external reference. See [validation](release/R-CMD-check.txt), [benchmarks](benchmarks/rc/README.md), and [release steps](release/README.md).

The GitHub workflow is configured. Public repository creation, remote CI, tagging the final GitHub release and publication require explicit approval. The scientist's visual preference is a full-UMAP reference plus tight island-wise bands. General visual performance remains dataset dependent, with abstentions recorded in the geometry diagnostics.
