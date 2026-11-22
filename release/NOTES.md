# ggclusteroutline 0.1.0

Draw reusable cluster outlines in ggplot2 or on Seurat DimPlot using original labels on a fixed two-dimensional embedding.

- Tight polygons can recover disconnected islands. A locally dominant territory mode distinguishes concentrations within overlapping populations. The optional occupied-tile method covers all assigned cell centres, including isolated components.
- Keep the point layer and its expression colours. Select one group or all groups, compute geometry per facet, or draw frozen paths across successive figures.
- A bounded process-local cache reuses results across marker changes. It accounts for all competing coordinates and labels.
- On the bundled PBMC example, automatic tight bands recover both islands of Leiden 4, enclosing 48 members and zero other cells.
- Yost and NSCLC full-data comparisons are documented in the repository. Territory membership coverage depends on the embedding, label distribution and smoothing.

Use the source package with R 4.1 or newer and its declared dependencies. See the README and help pages for installation, examples, geometry selection and known limitations.
