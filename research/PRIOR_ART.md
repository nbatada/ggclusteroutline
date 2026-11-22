# Prior art — initial official documentation evidence (not full audit)
1. ggforce::geom_mark_hull: concaveman concave hull; computed at draw time and may change on resize; default expand and rounded corners; supports labels. https://ggforce.data-imaginist.com/reference/geom_mark_hull.html
2. ggforce::geom_mark_ellipse: enclosing ellipse and labels; performance tradeoffs. https://rdrr.io/cran/ggforce/man/geom_mark_ellipse.html
3. ggalt::geom_encircle: automatic enclosing polygon; group aesthetics. https://search.r-project.org/CRAN/refmans/ggalt/html/geom_encircle.html
4. ggdensity::geom_hdr_lines: 2D highest density region outlines. https://search.r-project.org/CRAN/refmans/ggdensity/html/geom_hdr.html
5. ggplot2 official extension mechanism: ggproto Geom/Stat and layer behavior. https://ggplot2.tidyverse.org/articles/extending-ggplot2.html
M0 MUST extend audit to other relevant R packages, underlying geometry libraries, R package quality practices, source code, current versions, licenses, open issues, maintenance, actual rendering and benchmark evidence. Distinguish source-backed features from hypotheses. Do not claim none provide this.
