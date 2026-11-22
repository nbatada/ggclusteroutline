# ggclusteroutline 0.1.1

This patch corrects panel isolation, frozen path ordering and nearly vertical segment coverage. Territory diagnostics now count enclosed cells from other labels. Frozen geometry records its source fingerprint, coordinate space and software versions.

The layer and precomputation now default to locally dominant territories. Supplying component IDs still requests tight component hulls. Set `method = "tight"` to reproduce the previous strict default. The README gives measured examples of strict-mode abstention and occupied-tile fragmentation, and explains how to select a method for the desired coverage.
