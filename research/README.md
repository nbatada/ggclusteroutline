# Reproduce M0-001

Run from the repository root. The individual study directories contain raw tables, figures, parameters and their generating scripts. The comparison used R 4.5.3, ggplot2 4.0.3, ggforce 0.5.0, ggdensity 1.0.1 and ggalt development version 0.8.0 on a MacBook Air with an Apple M5, 10 cores and 32 GB of RAM, running macOS 26.7.3. These are local measurements. The [source inventory](sources/inventory.csv) separately identifies the upstream versions and Git revisions inspected on November 22.

Use an R library containing the recorded versions. The [full session](field/session.txt) lists versions for the rendering tools. For ggalt use the pinned upstream [development tarball](https://codeload.github.com/hrbrmstr/ggalt/tar.gz/7b5e9f98d0afd8c47277e6e96ce152d63b8d3776) and its declared dependencies. On the audit host the missing imports ash and extrafont installed into a temporary library together with extrafontdb and Rttf2pt1. The full ggalt namespace loaded. Current-source index availability and this development installation are distinct.

| Evidence | Replay / inputs |
|---|---|
| Four-method synthetic plate, edge cases and removal | [Visual comparison](visual/README.md) |
| Nine other shape and density fixtures | [Stress tests](stress/README.md) |
| Actual selected-group scatterplot and faceted reuse | [Palmer penguins](field/README.md) |
| Effect of changing device aspect ratio | [Resize test](device/README.md) |
| Time, memory and geometry complexity | [Scaling](scaling/README.md) |
| Upstream implementation, maintenance, license and name checks | [Source audit](sources/README.md) |

PNG and SVG versions of each plate are paired. The field comparison also has a PDF proof. Visual and numerical differences among methods describe only the supplied data, axes, parameters and devices. Exact timings vary with machine load.
