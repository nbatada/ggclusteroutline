# Scaling benchmark · M0-001

[Median timings](results/competitor_median_timing.png) · [21 native layer runs](results/competitor_measurements.csv) · [7 fresh-process peak RSS measurements](results/competitor_peak_rss.csv) · [18 convex reference runs](results/convex_reference_measurements.csv). Timings are elapsed seconds. Asset M0/scaling/competitor-median-timing, revision 1.

The matched ggforce and ggdensity comparisons use the same seeded Gaussian groups for each N and K. Each timing repeat uses identical data. Both plots include points. ggforce uses zero expansion and radius; ggdensity requests one 95% KDE level. The pipeline times three exclusive stages: ggplot build, gtable construction and drawing the resulting gtable to a 960 × 800 PNG device. Native geometry computation falls inside the appropriate stage. A subsequent SVG export counts identifiable outline elements and vertices bearing a unique stroke colour. This export is outside the reported timing total. The RSS measurement includes the R process, input, plot and additional SVG export and parsing. Each memory case runs once. R package versions appear in [the competitor session](results/competitor_sessionInfo.txt).

The convex reference uses grDevices::chull per group, then an explicitly closed path (vertex counts include the repeated closing point). It times geometry, ggplot build, and a separate full PNG export that **rebuilds** the plot. Do not sum all three columns. Its three runs use successive draws from one seeded stream, so shapes differ slightly across repeats. The convex reference uses a separate workload from the two matched native layers. The figure omits unmeasured combinations. Large native-layer cases including one million observations were outside this bounded run.

From the repository root with the stated R packages available via the usual R library path, run:

```sh
Rscript --vanilla research/scaling/benchmark_scaling.R
Rscript --vanilla research/scaling/benchmark_competitors.R
python3 research/scaling/measure_peak_rss.py
Rscript --vanilla research/scaling/make_performance_figure.R
```

The fresh-process collector uses wait4 on macOS or Linux, with platform-specific RSS units converted to bytes. Hardware and reference package versions are in [the research overview](../README.md). Timings and memory depend on the host and other activity.
