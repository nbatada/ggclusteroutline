# Local release procedure

The package version inside the source archive is 0.1.0. This is a local candidate for scientist review. The generated archive and its SHA-256 checksum are in this directory after the local release build. Rebuilding at a different time or with different R tools can change the archive hash.

1. Review the full-UMAP example in the repository README, the raw [benchmark comparisons](../benchmarks/rc/README.md), and the exact files in the candidate commit.
2. Review the intended public repository name and visibility. This project started without a Git remote. Approve the public source tree, local commit and asset checksum together.
3. After explicit publication approval, the following example assumes a **new public** repository named `nbatada/ggclusteroutline`, the clean candidate checkout, and no existing `origin`. Confirm the name first. The first command publishes the local repository and its history. If the target already exists, use its configured remote instead.

```sh
gh repo create nbatada/ggclusteroutline --public --source=. --remote=origin --push
```

4. After remote CI succeeds on the reviewed candidate commit, tag that exact commit and attach the checked archive and checksum:

```sh
git tag -a v0.1.0 v0.1.0-rc.1^{} -m "ggclusteroutline 0.1.0"
git push origin refs/tags/v0.1.0
gh release create v0.1.0 release/ggclusteroutline_0.1.0.tar.gz release/SHA256SUMS --verify-tag --title "ggclusteroutline 0.1.0" --notes-file release/NOTES.md
```

To verify the current local archive:

```sh
(cd release && shasum -a 256 -c SHA256SUMS)
```

## Candidate verification

The exact source archive passed full `R CMD check` on R 4.5.3 / macOS arm64 with ggplot2 4.0.3, including examples, seven test scripts and the PDF manual. A fresh tarball installation also passed all seven scripts against ggplot2 3.5.2 and 4.0.4 in isolated libraries on the same host. The Seurat test used Seurat 5.5.1 and SeuratObject 5.4.0 with the 700-cell embedding and saved cluster IDs, checking the point colours before and after adding the layer. The counts slot in the integration fixture is a placeholder; DimPlot uses the stored embedding. Windows and Linux CI are configured, awaiting a remote run.
