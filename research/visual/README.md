# Controlled outline comparison

`run_comparison.R` is a seeded, research-only M0 harness. It creates three
adversarial target shapes with a second, unrelated point cloud under the same
coordinates, dimensions, point size, alpha and device settings. The plate has
fixed viewport limits of -4 to 4 for every method. HDR estimation uses the
same explicit -4 to 4 KDE domain, so contour topology is not censored by the
display viewport.

| Case | Deliberate challenge |
| --- | --- |
| `ring` | A visual guide should not imply that the central empty region is occupied. |
| `islands` | One label contains spatially separated populations. Joining them communicates a region with no observed target cells. |
| `crescent` | A non-convex target exposes empty-space capture by a convex enclosure. |

The harness compares a base-R convex hull, `ggforce::geom_mark_hull`,
`ggalt::geom_encircle`, and `ggdensity::geom_hdr_lines`. The pinned ggalt 0.8.0
source was installed with its declared Imports into a temporary test library.
The package SHA is recorded in `research/sources/inventory.csv`. It is a tested
competitor installation, not a substitute implementation.

`output/matched_plate_3x4.png` and `.svg` combine all methods. `input/` stores
the exact point tables. `output/region_metrics.csv` records whether the island
midpoint and annulus centre lie inside a valid closed region and observed-point
coverage after deterministic 10% removal. Convex and ggforce metrics use their
native geometry paths with zero expansion. The ggforce row is therefore an
engine-path metric before any grid rounding. HDR metrics use emitted contour
paths and apply even-odd membership only after asserting every contour is
closed. `output/degenerate_render_results.csv` separates warning, error, and
empty-output evidence. `unknown` means visible ink was not independently
checked for that method.

Run from the repository root with:

```sh
R_LIBS=/path/to/ggalt-library:/path/to/ggforce-and-ggdensity-library \
  Rscript research/visual/run_comparison.R
```

The library paths are explicit so a replay can use any installation location.
Install the exact ggalt source matching the SHA recorded in the inventory with
its Imports before replaying.
