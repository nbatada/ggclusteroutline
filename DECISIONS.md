# Decision ledger
D001 2026-11-22: standalone R-first ggplot2 extension, provisional name ggclusteroutline. Revisit after naming/CRAN/GitHub collision audit.
D002: existing packages are competitors; novelty not presumed.
D003: visual communication is objective; geometry is implementation detail; no false biological inference.
D004: prioritize P0 outlines and scaling/caching; labels later.
D005: M0 audit-only gate; no package implementation before scientist approval.
OPEN: exact automatic geometry/fallback strategy; boundary coverage semantics; plot-device-dependent padding; cache API; optional dependencies; R package name; Python strategy.

## M0-001 findings · 22 November 2026

- **D006 · Architect recommendation, scientist decision pending.** Stop at M0. Existing layers and precomputed paths cover the demonstrated manual workflow. The benchmark supplies no case for a new general-purpose geometry engine. [Audit](AUDIT.md)
- **D007 · Proposed if M1 receives GO.** Start with an explicitly all-observation, data-space convex envelope and point/segment fallbacks. Accept empty-space bridging as a documented property. Preserve independently supplied component keys. Defer representative density and automatic choices. [Proposed specification](specs/PRODUCT_SPEC.md)
- **D008 · Proposed reuse contract.** Carry original group/facet keys through reusable geometry. Separate physical styling from data-space vertices. Recompute when membership, geometry parameters or coordinate assumptions change. The resize experiment directly rules out treating a device-dependent hull as a device-independent cache entry. [Resize evidence](research/device/README.md)
- **D009 · Naming.** Retain ggclusteroutline as a working name. The November 22 live and archived CRAN indexes and public GitHub repository-name query returned no collision. Recheck before any release. [Search record](research/sources/README.md)

Scientist visual selections and milestone approval remain open. Earlier priorities describe the candidate product. D006–D008 record the architect's recommendation and proposed scope only.

D010 · Scientist visual choice for cluster 4. Show the entire UMAP in every panel. Use a labelled Leiden reference on the left and one tight band per spatially separate island of the selected Leiden cluster on the expression map. The demonstrated two-band construction uses a manually identified gap. Automatic island separation and M1 approval remain open. [Full UMAP evidence](research/leiden-reference/full-umap-bands.pdf)
