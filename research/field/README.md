# Selected-group example on measured data

Horst, Hill and Gorman's palmerpenguins 0.1.1 distributes the Palmer Station LTER measurements under CC0. Bill length and depth supply the coordinates directly. The original species field defines membership and body mass supplies the continuous point colour. The input has 344 rows. Two lack the plotted measurements and mass. The table retains the 342 complete rows with their original row numbers. It is a general scatterplot example. Transfer to single-cell embeddings remains unmeasured. [Dataset, citation and license](https://allisonhorst.github.io/palmerpenguins/)

From the repository root, run the following with the versions in [session.txt](session.txt) available in the R library path.

```sh
Rscript --vanilla research/field/penguins.R
```

[PNG](penguins.png) · [SVG](penguins.svg) · [PDF](penguins.pdf) · [exact plotted rows](measurements.csv). Asset M0/field/penguins, revision 1. Each panel selects the same Adélie rows. The first polygon uses base R hull vertices, the second uses ggforce's default physical padding, and the third shows one ggdensity KDE contour with 90% estimated probability mass and a fixed grid domain. The figure makes the difference between enclosure and representative density visible. Its design remains subject to scientist review.

A second baseline checks reuse across plots. Run `Rscript --vanilla research/field/check-reuse.R`. The script computes Adélie hulls separately for the three original island facets and passes the same vertex table to two ggplot2 figures, colouring points by body mass or flipper length. It asserts that both built layers have identical vertex coordinates and panel assignments, and that each vertex retains its original island. [Verified vertices](reused-facet-vertices.csv)
