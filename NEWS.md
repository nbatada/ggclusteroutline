# ggclusteroutline 0.2.0

- Save label positions with `compute_cluster_outlines(..., label = TRUE)` and redraw them directly from an RDS file.

- Add `label = TRUE` for automatic cluster IDs inside live territory outlines. Use `label = "only"` to draw those IDs alone.

# ggclusteroutline 0.1.1

- Computed outlines check facet keys on separate layer data. Intentional replication requires an explicit opt-in.
- Frozen paths respect stored vertex order after row reordering.
- Nearly vertical all-member segments span the full component.
- Territory diagnostics count enclosed cells carrying other labels. Frozen objects record their source fingerprint, coordinate space and software versions.
- The one-line layer and precomputation now default to locally dominant territories. Request `method = "tight"` for the former strict default. Supplying a component column continues to request all-member component hulls.

# ggclusteroutline 0.1.0

Initial release. Native R geometry and ggplot2 overlays support
tight island bands and locally dominant territories, selected or all supplied
labels, bounded in-session caching and portable frozen geometry.
