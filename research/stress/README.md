# Additional shape fixtures

Run `Rscript --vanilla research/stress/stress.R` from the repository root with the R libraries recorded in [the field session](../field/session.txt). Seed 11022 generates [the plotted coordinates and group labels](points.csv). Assets M0/stress/plate-1 through plate-3, revision 1, have corresponding PNG and SVG exports. Each row shares points, colour, axes and viewport across methods. Limits adapt by case. In the anisotropic row the original ellipse's x coordinates are multiplied by 100 and the axis range scales with them. Thus the visible cloud retains its relative dimensions. No area comparisons across rows are intended.

1. [Disk, ellipse and dumbbell](plate-1.png). Convex already encloses the two compact clouds. The sparse connector in the dumbbell remains visible.
2. [Adjacent groups, overlap and tail](plate-2.png). All methods allow the outlines to overlap. A hull includes the tail tip, though the different methods display different amounts of empty space.
3. [Outliers, unequal density and anisotropy](plate-3.png). On this fixture the 90% KDE drops the isolated observations from its displayed region and traces two regions for same-label islands of 135 and 15 points. Both hulls span the space between them. Point membership is unchanged in every panel.

The HDR uses the native estimator with an explicit common domain extended 23% beyond each data range and one 90% mass level. ggforce uses zero padding and rounding to expose its geometry. These settings serve different coverage goals. The figures measure behaviour on these inputs only.
