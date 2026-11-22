# Local release qualification

The published [v0.1.0 release](https://github.com/nbatada/ggclusteroutline/releases/tag/v0.1.0) and its checksum remain available. The v0.1.1 candidate addresses the findings in the [v0.1.0 audit](RELEASE_AUDIT_v0.1.0.md).

Review the [candidate audit](RELEASE_AUDIT_v0.1.1.md), package changes and NEWS before release approval. To check the local candidate, run the following from the release directory.

```sh
shasum -a 256 -c SHA256SUMS-v0.1.1
R CMD check ggclusteroutline_0.1.1.tar.gz
```

Publication requires scientist approval of the candidate commit and archive. Run release CI on the approved source before attaching the audited archive to a public tag.
